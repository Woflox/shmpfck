import ../util/util
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
  result.shapes = @[shape]
  result.init()

method updateBehaviour* (self: PlayerShip, dt: float) =
  self.moveDir = input.moveDir()

  procCall Ship(self).updateBehaviour(dt)

method updatePostPhysics* (self: PlayerShip, dt: float) =
  self.wantsToShoot = input.buttonDown(input.fire1)
  if self.wantsToShoot and self.timeSinceShoot > 0.2:
    addEntity(newProjectile(self.position + self.rotation*vec2(0,1), self.getVelocity()))
    playSound(newShotNode(), -7, 0.0)
    self.timeSinceshoot = 0

  self.timeSinceShoot += dt
