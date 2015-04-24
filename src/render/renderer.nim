import shader
import fbo
import opengl
import ../globals/globals
import ../util/util
import ../world/world
import ../ui/screen

include shaders/basic.frag
include shaders/basic.vert
include shaders/post.frag
include shaders/post.vert

var basicShader: ShaderProgram
var postShader: ShaderProgram
var frameBuffer: FrameBuffer

proc init* =
  loadExtensions()
  glClearColor(0.0, 0.0, 0.0, 1.0)                  # Set background color to black and opaque
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST)
  echo "OpenGL version ", cast[cstring](glGetString(GL_VERSION))

  basicShader = newShaderProgram(basicVert, basicFrag)
  postShader = newShaderProgram(postVert, postFrag)
  frameBuffer = createFrameBuffer(1366, 768)

proc resize* =
  glViewport(0, 0, GLint(screenWidth), GLint(screenHeight))
  glMatrixMode(GL_PROJECTION)
  glLoadIdentity()
  glOrtho(-screenAspectRatio, screenAspectRatio, -1, 1, -1, 1)
  frameBuffer.resize(screenWidth, screenHeight)


proc fullscreenQuad =
  glBegin(GL_TRIANGLE_FAN)
  glVertex2d(-1.0, -1.0)
  glVertex2d(1.0, -1.0)
  glVertex2d(1.0, 1.0)
  glVertex2d(-1.0, 1.0)
  glEnd()

proc render* =
  glBindFrameBuffer(GL_FRAMEBUFFER, frameBuffer.fbo)
  glClear(GL_COLOR_BUFFER_BIT)
  glMatrixMode(GL_MODELVIEW)
  glLineWidth(1)
  glPointSize(1)
  glLoadIdentity()

  basicShader.apply()

  world.render()
  currentScreen.render()

  glBindFrameBuffer(GL_FRAMEBUFFER, 0)
  postShader.setTexture("sceneTex", frameBuffer.texture)
  postShader.apply()
  fullscreenQuad()
