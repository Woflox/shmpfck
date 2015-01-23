import ../render/shape
import ../util/util
import opengl
import entity

type
  Ship* = ref object of Entity


proc generateShip* (position: Vector2): Ship =
  result = Ship(collidable: true, dynamic: true, drawable: true, position: position)
  let shape = createIsoTriangle(width = 0.61803398875, height = 1.0, drawStyle = DrawStyle.filledOutline,
                                lineColor = col(0, 1, 0), fillColor = col(0, 0.5, 0))
  result.shapes = @[shape]
