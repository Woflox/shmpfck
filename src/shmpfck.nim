import sdl2
import opengl
import util/util
from input/input import nil
from world/world import nil

# Initialize SDL
discard init(INIT_EVERYTHING)
var window = createWindow("SHMPFCK", 100, 100, 800, 600, SDL_WINDOW_OPENGL or SDL_WINDOW_RESIZABLE)
var context = window.glCreateContext()

# Initialize OpenGL
loadExtensions()
glClearColor(0.0, 0.0, 0.0, 1.0)                  # Set background color to black and opaque
glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) # Nice perspective corrections

proc resize() =
  var width, height: cint
  window.getSize(width, height)
  let aspect = float(width)/float(height)

  glViewport(0, 0, width, height)                        # Set the viewport to cover the new window
  glMatrixMode(GL_PROJECTION)                       # To operate on the Projection matrix
  glLoadIdentity()                                  # Reset
  glOrtho(-20*aspect, 20*aspect, -20, 20, -1, 1)

# Main loop

var
  event: Event = Event(kind:UserEvent)
  runGame = true
  t = getTicks()

proc update() =
  let now = getTicks()
  let dt = float(now - t) * 0.001
  t = now

  input.update(dt)
  world.update(dt)

proc render() =
  glClear(GL_COLOR_BUFFER_BIT)
  glMatrixMode(GL_MODELVIEW)
  glLoadIdentity()

  world.render()

  window.glSwapWindow()

input.init()
world.generate()

while runGame:
  while pollEvent(event):
    case event.kind:
      of QuitEvent:
        runGame = false
        break
      of WindowEvent:
        resize()
      else:
        input.addEvent(event)
  update()
  render()

destroy window
