import ../geometry/shape
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
    brain: NeuralNet
    timeSinceShoot: float
    wantsToShoot: bool
    t: float

const
  noiseFrequency = 0.5
  noiseOctaves = 3
  waveFrequency = 0.25
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
  result.brain = species.brain
  result.moveSpeed = species.moveSpeed
  result.weapons = @[species.weapon]
  result.t = random(0.0, 1000.0)
  result.init()

proc generateTestSpecies* (): Species =
  var species = Species(moveSpeed: random(5.0,20.0), shapes: @[])
  var color = color(uniformRandom(),uniformRandom(),uniformRandom())
  let index = random(0, 2)
  case index:
    of 0: color.r = 1
    of 1: color.g = 1
    of 2: color.b = 1
    else: discard
  for i in 0..random(1, 6):
    let size = random(0.25, 1)
    let point1 = vec2(random(-size, size),random(-size, size))
    let point2 = vec2(random(-size, size),random(-size, size))
    let lineColor = if random(0, 2) == 0: color(1, 1, 1) else: color
    let shape = newShape(vertices = @[point1, point2],
                             drawStyle = DrawStyle.line,
                             lineColor = lineColor,
                             collisionType = CollisionType.continuous)
    let shape2 = newShape(vertices = @[vec2(point1.x * -1, point1.y), vec2(point2.x * -1, point2.y)],
                             drawStyle = DrawStyle.line,
                             lineColor = lineColor,
                             collisionType = CollisionType.continuous)
    species.shapes.add(shape)
    species.shapes.add(shape2)

  species.brain = newNeuralNet(inputs = 15, outputs = 3)
  species.brain.randomize()
  result = species

method update*(self: Enemy, dt: float) =
  self.t += dt

  let inverseRotation = self.rotation.transpose

  let ship = entityOfType[PlayerShip]()
  let dirToShip = inverseRotation * (ship.position - self.position).normalize()
  let shipMoveDir = inverseRotation * ship.getVelocity().normalize()
  let waveVal = sin(self.t * waveFrequency * Pi * 2 )
  let noiseVal = fractalNoise(self.t * noiseFrequency, noiseOctaves)
  let noiseVal2 = fractalNoise((self.t + 100) * noiseFrequency, noiseOctaves)
  let closeShipDir = if self.position.distanceSquared(ship.position) < closeRange:
                        dirToShip else: vec2(0,0)
  var obstacle: Entity
  var obstacleDistance = 1000000.0
  var weightedObstaclePos = vec2(0,0)
  var weightedCloseObstaclePos = vec2(0,0)
  var totalWeight = 0.0
  for entity in entitiesByTag[int(CollisionTag.playerWeapon)]:
    let distance = self.position.distanceSquared(entity.position)
    let weight = 1.0 / distance
    if distance < obstacleDistance:
        obstacle = entity
        obstacleDistance = distance
    weightedObstaclePos += entity.position * weight
    totalWeight += weight
  if totalWeight > 0.0:
    weightedObstaclePos = weightedObstaclePos / totalWeight
  let weightedObstacleDir = if obstacle != nil:
    inverseRotation * (weightedObstaclePos - self.position).normalize() else: vec2(0,0)
  let closeObstacleDir = if obstacleDistance < closeRange:
    inverseRotation * (obstacle.position - self.position).normalize() else: vec2(0,0)
  let obstacleMoveDir = if obstacle != nil:
    inverseRotation * obstacle.getVelocity().normalize() else: vec2(0,0)

  self.brain.simulate(dt, waveVal, noiseVal, noiseVal2,
                      dirToShip.x, dirToShip.y, shipMoveDir.x, shipMoveDir.y,
                      closeShipDir.x, closeShipDir.y,
                      weightedObstacleDir.x, weightedObstacleDir.y,
                      closeObstacleDir.x, closeObstacleDir.y,
                      obstacleMoveDir.x, obstacleMoveDir.y)

  self.moveDir = vec2(self.brain.getOutput(0), self.brain.getOutput(1)).normalize

  if length(self.position) <= self.minPolarY + 0.1:
    self.reposition(self.position.normalize * 200)

  if length(self.position) >= 400:
    self.reposition(self.position.normalize * (self.minPolarY + 0.2))

  procCall Ship(self).update(dt)


method updatePostPhysics* (self: Enemy, dt: float) =
  self.wantsToShoot = self.brain.getOutput(2) > 0.1
  if self.wantsToShoot and self.timeSinceShoot > 2.0:
    addEntity(newEnemyProjectile(self.position + self.rotation*vec2(0,1), self.getVelocity()))
    self.timeSinceshoot = 0

  self.timeSinceShoot += dt

