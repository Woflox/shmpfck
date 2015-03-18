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
import ../audio/voice
from ../input/input import nil
from ../entity/camera import nil


proc testShape (pos: Vector2): Entity =
  result = Entity(drawable: true, position: pos)
  let shape = createIsoTriangle(width =0.2, height = 0.2, drawStyle = DrawStyle.solid,
                                 fillColor = col(0.25, 0.25, 0.25))
  result.shapes = @[shape]
  result.init()

var intros = ["Try harder",
              "Welcome back. I missed you.",
              "Did you have a good run?",
              "How are you today?",
              "Maybe you should just give up.",
              "Just go for a short walk",
              "A challenger approaches",
              "How many days have we been trapped here?",
              "Game over.",
              "Hello"]

proc generate* () =
  entities = @[]
  for x in -25..25:
    for y in -25..25:
      entities.add(testShape(vec2(float(x*4),float(y*4))))
  let ship = generatePlayerShip(vec2(0,10))
  camera.init(ship.position)
  camera.target = ship

  for i in 0..20:
    let speciesPos = randomDirection() * 100
    var species = generateTestSpecies()
    for j in 0..10:
      let pos = speciesPos + randomDirection() * random(0.0, 10.0)
      entities.add(generateEnemy(species, pos))

  entities.add(ship)


playSound(newAmbientNode(), -3.0, 0.0)

proc update* (dt: float) =
  if (input.buttonPressed(input.restart)):
    generate()
  var i = 0
  while i <= high(entities):
    entities[i].update(dt)
    inc i
  i = 0
  while i <= high(entities):
    entities[i].checkForCollisions(i, dt)
    inc i
  i = 0
  while i <= high(entities):
    if entities[i].destroyed:
      entities.del(i)
    else:
      inc i

  if entityOfType[PlayerShip]() == nil:
    generate()
    playSound(newVoiceNode(intros.randomChoice()), 0.0, 0.0)

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
