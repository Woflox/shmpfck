import ../util/util
import ../render/shape
import ship
import entity
from ../input/input import nil

type
  PlayerShip* = ref object of Ship

proc generatePlayerShip* (position: Vector2): PlayerShip =
  result = PlayerShip(collidable: true,
                movement: Movement.polar,
                drawable: true,
                position: position,
                minPolarY: 10,
                moveSpeed: 20)

  let shape = createIsoTriangle(width = 0.61803398875, height = 1.0, drawStyle = DrawStyle.filledOutline,
                                lineColor = col(0, 1, 0), fillColor = col(0, 0.375, 0))
  result.shapes = @[shape]
  result.init()

method updateBehaviour* (self: PlayerShip, dt: float) =
  self.moveDir = input.moveDir()
  procCall Ship(self).updateBehaviour(dt)
