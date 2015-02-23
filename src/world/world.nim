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
  for entity in entities:
    entity.render()

proc testShape (pos: Vector2): Entity =
  result = Entity(drawable: true, position: pos)
  let shape = createIsoTriangle(width =0.2, height = 0.2, drawStyle = DrawStyle.solid,
                                 fillColor = col(0.25, 0.25, 0.25))
  result.shapes = @[shape]


proc generate* () =
  entities = @[]
  for x in -20..20:
    for y in -20..20:
      entities.add(testShape(vec2(float(x*2),float(y*2))))
  let ship = generateShip(vec2(0,5))
  camera.init(ship.position)
  camera.target = ship
  entities.add(ship)
