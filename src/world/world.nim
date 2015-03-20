import opengl
import ../entity/entity
import ../entity/ship
import ../entity/enemy
import ../entity/playership
import ../util/util
import ../util/random
import ../render/shape
import ../audio/audio
import ../audio/ambient
import ../audio/poetry
import math
from ../input/input import nil
from ../entity/camera import nil


proc testShape (pos: Vector2): Entity =
  result = Entity(drawable: true, position: pos)
  let shape = createIsoTriangle(width =0.2, height = 0.2, drawStyle = DrawStyle.solid,
                                 fillColor = col(0.25, 0.25, 0.25))
  result.shapes = @[shape]
  result.init()

proc generate* () =
  clearEntities()
  for x in -25..25:
    for y in -25..25:
      addEntity(testShape(vec2(float(x*4),float(y*4))))
  let ship = generatePlayerShip(vec2(0,10))
  camera.init(ship.position)
  camera.target = ship

  for i in 0..20:
    let speciesPos = randomDirection() * 100
    var species = generateTestSpecies()
    for j in 0..10:
      let pos = speciesPos + randomDirection() * random(0.0, 25.0)
      addEntity(generateEnemy(species, pos))

  addEntity(ship)


playSound(newAmbientNode(), -4.0, 0.0)
sayProse()

proc update* (dt: float) =
  if (input.buttonPressed(input.restart)):
    generate()
  var i = 0
  while i <= high(entities):
    entities[i].update(dt)
    inc i
  for entityList in entitiesByTag:
    i = 0
    while i <= high(entityList):
      entityList[i].checkForCollisions(i, dt)
      inc i
  i = 0
  while i <= high(entities):
    if entities[i].destroyed:
      removeEntity(i)
    else:
      inc i

  if entityOfType[PlayerShip]() == nil:
    generate()
    sayProse()

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
