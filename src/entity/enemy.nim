import ../render/shape
import ../util/util
import ../util/noise
import ../util/random
import ../ai/neuralnet
import ../audio/audio
import ../audio/explosion
import entity
import ship
import playership
import weapon
import math

type
  Species* = ref object
    moveSpeed*: float
    shapes*: seq[Shape]
    brain*: NeuralNet
    weapon*: Weapon
  Enemy = ref object of Ship
    species *: Species
    t: float

proc brain(self: Enemy): NeuralNet {.inline.} =
  self.species.brain

const
  noiseFrequency = 0.5
  noiseOctaves = 3
  waveFrequency = 1.0
  closeRange = pow(5, 2)

method onCollision(self: Enemy, other: PlayerShip) =
  playSound(newExplosionNode(), 0.0, 0.0)
  other.destroyed = true

proc generateEnemy* (species: Species, position: Vector2): Enemy =
  result = Enemy(movement: Movement.polar,
                drawable: true,
                position: position,
                minPolarY: 1,
                species: species,
                collisionTag: CollisionTag.enemy)
  result.shapes = species.shapes
  result.moveSpeed = species.moveSpeed
  result.weapons = @[species.weapon]
  result.t = random(0.0, 1000.0)
  result.init()

proc generateTestSpecies* (): Species =
  var species = Species(moveSpeed: random(5.0,15.0))
  var color = col(uniformRandom(),uniformRandom(),uniformRandom())
  let index = random(0, 2)
  case index:
    of 0: color.r = 1
    of 1: color.g = 1
    of 2: color.b = 1
    else: discard
  var fillColor = col(color.r * 0.375, color.g * 0.375, color.b * 0.375)

  let shape = createIsoTriangle(width = 0.61803398875, height = -1.0, drawStyle = DrawStyle.filledOutline,
                                lineColor = color, fillColor = fillColor)
  species.shapes = @[shape]
  species.brain = newNeuralNet(inputs = 16, outputs = 2,
                            hiddenLayers = 5, hiddenLayerSize = 16)
  species.brain.randomize()
  result = species

method updateBehaviour*(self: Enemy, dt: float) =
  self.t += dt

  let inverseRotation = self.rotation.transpose

  let ship = entityOfType[PlayerShip]()
  let dirToShip = inverseRotation * (ship.position - self.position).normalize()
  let shipMoveDir = inverseRotation * ship.getVelocity().normalize()
  let waveVal = sin((self.t / (2 * Pi)) * waveFrequency)
  let noiseVal = fractalNoise(self.t * noiseFrequency, noiseOctaves)
  let noiseVal2 = fractalNoise((self.t + 100) * noiseFrequency, noiseOctaves)
  let closeShipDir = if self.position.distanceSquared(ship.position) < closeRange:
                        dirToShip else: vec2(0,0)
  var obstacle: Entity
  var obstacleDistance = 1000000.0
  for entity in entitiesByTag[int(CollisionTag.playerWeapon)]:
    let distance = self.position.distanceSquared(entity.position)
    if distance < obstacleDistance:
      obstacle = entity
      obstacleDistance = distance
  let obstacleDir = if obstacle == nil: vec2(0,0) else:
         inverseRotation * (obstacle.position - self.position).normalize()
  let closeObstacleDir = if obstacleDistance < closeRange: obstacleDir else: vec2(0,0)
  let obstacleMoveDir = if obstacle == nil: vec2(0,0) else:
    inverseRotation * obstacle.getVelocity().normalize()

  self.brain.simulate(1.0, waveVal, noiseVal, noiseVal2, dirToShip.x,
                      dirToShip.y, shipMoveDir.x, shipMoveDir.y,
                      closeShipDir.x, closeShipDir.y, obstacleDir.x,
                      obstacleDir.y, closeObstacleDir.x, closeObstacleDir.y,
                      obstacleMoveDir.x, obstacleMoveDir.y)

  self.moveDir = vec2(self.brain.getOutput(0), self.brain.getOutput(1)).normalize

  procCall Ship(self).updateBehaviour(dt)
