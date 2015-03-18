import ../render/shape
import ../util/util
import ../util/noise
import ../util/random
import ../ai/neuralnet
import entity
import ship
import playership
import weapon

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
  noiseFrequency = 2
  noiseOctaves = 3

proc generateEnemy* (species: Species, position: Vector2): Enemy =
  result = Enemy(collidable: true,
                movement: Movement.polar,
                drawable: true,
                position: position,
                minPolarY: 1,
                species: species)
  result.shapes = species.shapes
  result.moveSpeed = species.moveSpeed
  result.weapons = @[species.weapon]
  result.t = random(0.0, 1000.0)
  result.init()

proc generateTestEnemy* (position: Vector2): Enemy =
  var species = Species(moveSpeed: 10)

  let shape = createIsoTriangle(width = 0.61803398875, height = -1.0, drawStyle = DrawStyle.filledOutline,
                                lineColor = col(1, 0, 1), fillColor = col(0.375, 0, 0.375))
  species.shapes = @[shape]
  species.brain = newNeuralNet(inputs = 7, outputs = 2,
                            hiddenLayers = 10, hiddenLayerSize = 8)
  species.brain.randomize()
  result = generateEnemy(species, position)

method updateBehaviour*(self: Enemy, dt: float) =
  self.t += dt

  let ship = entityOfType[PlayerShip]()
  let dirToShip = self.rotation.transpose * (ship.position - self.position).normalize()
  let shipMoveDir = ship.velocity.normalize()
  let noiseVal = fractalNoise(self.t / noiseFrequency, noiseOctaves)
  let noiseVal2 = fractalNoise((self.t + 100) / noiseFrequency, noiseOctaves)

  self.brain.simulate(1.0, noiseVal, noiseVal2, dirToShip.x,
                      dirToShip.y, shipMoveDir.x, shipMoveDir.y)

  self.moveDir = vec2(self.brain.getOutput(0), self.brain.getOutput(1)).normalize

  procCall Ship(self).updateBehaviour(dt)
