import ../util/util
import ../util/random
import ../geometry/shape
import ship
import entity
import weapon
import ../audio/audio
import ../audio/shot
from ../input/input import nil

type
  PlayerShip* = ref object of Ship
    timeSinceShoot: float
    wantsToShoot: bool

proc generatePlayerShip* (position: Vector2): PlayerShip =
  result = PlayerShip(movement: Movement.polar,
                drawable: true,
                position: position,
                minPolarY: 10,
                moveSpeed: 20,
                collisionTag: CollisionTag.player)

  let shape = createIsoTriangle(width = goldenRatio, height = 1.0, drawStyle = DrawStyle.filledOutline,
                                lineColor = color(0, 1, 0), fillColor = color(0, 0.375, 0),
                                collisionType = CollisionType.continuous)
  let flameShape = createIsoTriangle(width = goldenRatio / 2, height = -0.5, drawStyle = DrawStyle.filledOutline)
  result.shapes = @[shape, flameShape]
  result.init()

method updateBehaviour* (self: PlayerShip, dt: float) =
  self.moveDir = input.moveDir()
  let flameLength = random(0.5, 1.0) * max(0.25, (self.moveDir.y + 1) / 2)
  self.shapes[1].relativeVertices[1] = vec2(0, -flameLength)
  self.shapes[1].lineColor = color(1, flameLength, 0)
  self.shapes[1].fillColor = color(0.375, flameLength * 0.375, 0)

  procCall Ship(self).updateBehaviour(dt)


method updatePostPhysics* (self: PlayerShip, dt: float) =
  self.wantsToShoot = input.buttonDown(input.fire1)
  if self.wantsToShoot and self.timeSinceShoot > 0.2:
    addEntity(newProjectile(self.position + self.rotation*vec2(0,1), self.getVelocity()))
    playSound(newShotNode(), -7, 0.0)
    self.timeSinceshoot = 0

  self.timeSinceShoot += dt
