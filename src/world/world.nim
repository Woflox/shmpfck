import opengl
import ../entity/entity
import ../entity/ship
import ../entity/enemy
import ../entity/playership
import ../entity/camera
import ../util/util
import ../util/random
import ../geometry/shape
import ../audio/audio
import ../audio/ambient
import ../audio/prose
import ../ui/text
import ../ui/uiobject
from ../input/input import nil
from ../entity/camera import nil
import math

proc testShape (pos: Vector2): Entity =
  result = Entity(drawable: true, position: pos)
  let maxSize = min(25.0, pos.length / 3)
  let shape = createIsoTriangle(width = random(0.0, maxSize),
                                height = random(0.0, maxSize),
                                drawStyle = DrawStyle.filledOutline,
                                fillColor = color(0.04, 0.04, 0.06),
                                lineColor = color(0.08, 0.08, 0.12))
  result.shapes = @[shape]
  result.init(rotation = matrixFromAngle(random(0.0, 2*Pi)))

proc generate* () =
  clearEntities()
  for i in 0..2000:
    addEntity(testShape(vec2(random(-300.0, 300.0), random(-300.0, 300.0))))
  let ship = generatePlayerShip(vec2(0,10))
  var camera = newCamera(ship.position)
  camera.target = ship

  for i in 0..20:
    let speciesPos = randomDirection() * random(100.0, 300.0)
    var species = generateTestSpecies()
    for j in 0..10:
      let pos = speciesPos + randomDirection() * random(0.0, 25.0)
      addEntity(generateEnemy(species, pos))

  addEntity(ship)
  sayProse()


playSound(newAmbientNode(), -4.0, 0.0)

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

  mainCamera.update(dt)

proc render* () =
  glPushMatrix()
  mainCamera.applyTransform()
  glEnable (GL_BLEND);
  glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_COLOR);
  glBegin(GL_TRIANGLES)
  for entity in entities:
    entity.onScreen = mainCamera.isOnScreen(entity.boundingBox)
    entity.renderSolid()
  glEnd()
  glBegin(GL_LINES)
  for entity in entities:
    entity.renderLine()
  glEnd()
  glPopMatrix()
