import sdl2
import opengl
import util/util
import entity/entity
import entity/ship
from input/input import nil

# Initialize SDL
discard SDL_Init(INIT_EVERYTHING)
var window = CreateWindow("SHMPFCK", 100, 100, 800, 600, SDL_WINDOW_OPENGL or SDL_WINDOW_RESIZABLE)
var context = window.GL_CreateContext()

# Initialize OpenGL
loadExtensions()
glClearColor(0.0, 0.0, 0.0, 1.0)                  # Set background color to black and opaque
glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) # Nice perspective corrections

var entities*: seq[Entity] = @[]

# Main loop

var
  evt: TEvent
  runGame = true
  t = GetTicks()

proc resize() =
  let
    width: int32 = 800
    height: int32 = 600
    aspect = float(width)/float(height)
  glViewport(0, 0, width, height)                        # Set the viewport to cover the new window
  glMatrixMode(GL_PROJECTION)                       # To operate on the Projection matrix
  glLoadIdentity()                                  # Reset
  glOrtho(-10*aspect, 10*aspect, -10, 10, -1, 1)

proc update() =
  let now = GetTicks()
  let dt = float(now - t) * 0.001
  t = now

  for entity in entities:
    entity.update(dt)

proc render() =
  glClear(GL_COLOR_BUFFER_BIT)
  glMatrixMode(GL_MODELVIEW)
  glLoadIdentity()

  for entity in entities:
    entity.render()

  window.GL_SwapWindow()

proc newGame() =
  var ship = generateShip(vec2(0,-7))
  entities.add(ship)

while runGame:
  while PollEvent(evt):
    case evt.kind:
      of QuitEvent:
        runGame = false
        break
      of WindowEvent:
        resize()
      else:
        input.handleEvent(evt)
  update()
  render()

destroy window
