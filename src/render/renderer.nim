import shader
import fbo
import opengl
import math
import ../globals/globals
import ../util/util
import ../world/world
import ../ui/screen
import ../entity/camera

const basicFrag = staticRead("../content/shaders/basic.frag")
const basicVert = staticRead("../content/shaders/basic.vert")
const postFrag = staticRead("../content/shaders/post.frag")
const postVert = staticRead("../content/shaders/post.vert")

var basicShader: ShaderProgram
var postShader: ShaderProgram
var frameBuffer: FrameBuffer
var t: float

const maxFrameBufferHeight = 720
const targetScanLineFrequency = 0.5

proc init* =
  loadExtensions()
  glClearColor(0, 0, 0, 1.0)                  # Set background color to black and opaque
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST)
  echo "OpenGL version ", cast[cstring](glGetString(GL_VERSION))

  basicShader = newShaderProgram(basicVert, basicFrag)
  postShader = newShaderProgram(postVert, postFrag)
  frameBuffer = createFrameBuffer(int(maxFrameBufferHeight * (16.0 / 9)),
                                  maxFrameBufferHeight)

proc resize* =
  glViewport(0, 0, GLint(screenWidth), GLint(screenHeight))
  glMatrixMode(GL_PROJECTION)
  glLoadIdentity()
  glOrtho(-screenAspectRatio, screenAspectRatio, -1, 1, -1, 1)
  frameBuffer.resize(min(int(screenAspectRatio * maxFrameBufferHeight), screenWidth),
                     min(maxFrameBufferHeight, screenHeight))

proc fullscreenQuad =
  glBegin(GL_TRIANGLE_FAN)
  glVertex2d(-1.0, -1.0)
  glVertex2d(1.0, -1.0)
  glVertex2d(1.0, 1.0)
  glVertex2d(-1.0, 1.0)
  glEnd()

proc update* (dt: float) =
  t += dt

proc render* =

  #render scene
  glBindFrameBuffer(GL_FRAMEBUFFER, frameBuffer.fbo)
  glViewport(0, 0, GLint(frameBuffer.width), GLint(frameBuffer.height))
  glClear(GL_COLOR_BUFFER_BIT)
  glMatrixMode(GL_MODELVIEW)
  glLineWidth(1)
  glPointSize(1)
  glLoadIdentity()

  basicShader.apply()
  mainCamera.setPostZoomThreshold(float(frameBuffer.height) / float(maxFrameBufferHeight))
  world.render()

  #render UI
  let zoom = mainCamera.getPostZoom()
  currentScreen.render(zoom)

  #post processing
  let targetScanLines = float(frameBuffer.height) * targetScanLineFrequency
  let scanLinePeriod = max(2, floor(screenSize.y / (targetScanLines * zoom)))
  let scanLineFrequency = 1 / scanLinePeriod
  let scanLines = screenSize.y * scanLineFrequency;

  glBindFrameBuffer(GL_FRAMEBUFFER, 0)
  glViewport(0, 0, GLint(screenWidth), GLint(screenHeight))
  postShader.setParameter("zoom", zoom)
  postShader.setParameter("t", t)
  postShader.setParameter("scanLines", scanLines)
  postShader.setParameter("screenHeight", screenSize.y)
  postShader.setParameter("aspectRatio", screenAspectRatio)
  postShader.setTexture("sceneTex", frameBuffer.texture)
  postShader.apply()
  fullscreenQuad()
