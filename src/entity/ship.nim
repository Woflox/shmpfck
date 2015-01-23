import ../render/shape
import ../util/util
import opengl
import entity

type
  Ship* = ref object of Entity


proc generateShip* (position: Vector2): Ship =
  result = Ship(collidable: true, dynamic: true, drawable: true, position: position)
  let shape = createIsoTriangle(width = 0.5, height = 1.0, drawStyle = DrawStyle.filledOutline)
  result.shapes = @[shape]
