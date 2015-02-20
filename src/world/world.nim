import ../entity/entity
import ../entity/camera
import ../entity/ship
import ../util/util

proc update* (dt: float) =
  for entity in entities:
    entity.update(dt)

proc render* () =
  for entity in entities:
    entity.render()

proc generate* () =
  entities = @[]
  entities.add(newCamera(vec2(0,0)))
  let ship = generateShip(vec2(0,5))
  entities.add(generateShip(vec2(0,5)))
  camera.setTarget(ship)
