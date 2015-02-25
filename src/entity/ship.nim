import ../render/shape
import ../util/util
import opengl
import entity
from ../input/input import nil

type
  Ship* = ref object of Entity

const moveSpeed = 20.0

proc generateShip* (position: Vector2): Ship =
  result = Ship(collidable: true,
                movement: Movement.polar,
                drawable: true,
                position: position,
                minPolarY: 10)

  let shape = createIsoTriangle(width = 0.61803398875, height = 1.0, drawStyle = DrawStyle.filledOutline,
                                lineColor = col(0, 1, 0), fillColor = col(0, 0.375, 0))
  result.shapes = @[shape]
  result.init()

method updateBehaviour*(self: Ship, dt: float) =
  self.velocity = input.moveDir() * moveSpeed
