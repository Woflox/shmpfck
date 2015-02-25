import opengl
import ../entity/entity
import ../entity/ship
import ../util/util
import ../render/shape
from ../entity/camera import nil

proc update* (dt: float) =
  for entity in entities:
    entity.update(dt)
  camera.update(dt)

proc render* () =
  camera.applyTransform()
  glEnable (GL_BLEND);
  glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_COLOR);
  glBegin(GL_TRIANGLES)
  for entity in entities:
    entity.renderSolid()
  glEnd()
  glBegin(GL_LINES)
  for entity in entities:
    entity.renderLine()
  glEnd()

proc testShape (pos: Vector2): Entity =
  result = Entity(drawable: true, position: pos)
  let shape = createIsoTriangle(width =0.2, height = 0.2, drawStyle = DrawStyle.solid,
                                 fillColor = col(0.25, 0.25, 0.25))
  result.shapes = @[shape]
  result.init()


proc generate* () =
  entities = @[]
  for x in -50..50:
    for y in -50..50:
      entities.add(testShape(vec2(float(x*2),float(y*2))))
  let ship = generateShip(vec2(0,10))
  camera.init(ship.position)
  camera.target = ship
  entities.add(ship)
