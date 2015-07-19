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
const post2Frag = staticRead("../content/shaders/post2.frag")
const post2Vert = staticRead("../content/shaders/post2.vert")
const pixelAlignedVert = staticRead("../content/shaders/pixelAligned.vert")

var basicShader: ShaderProgram
var postShader: ShaderProgram
var post2Shader: ShaderProgram
var uiShader: ShaderProgram
var frameBuffer: FrameBuffer
var postFrameBuffer: FrameBuffer
var t: float

const maxFrameBufferHeight = 580
const targetScanLineFrequency = 0.5

proc init* =
  loadExtensions()
  glClearColor(0, 0, 0, 1.0)                  # Set background color to black and opaque
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST)
  echo "OpenGL version ", cast[cstring](glGetString(GL_VERSION))

  basicShader = newShaderProgram(basicVert, basicFrag)
  postShader = newShaderProgram(postVert, postFrag)
  post2Shader = newShaderProgram(post2Vert, post2Frag)
  uiShader = newShaderProgram(pixelAlignedVert, basicFrag)
  frameBuffer = createFrameBuffer(int(maxFrameBufferHeight * (16.0 / 9)),
                                  maxFrameBufferHeight)
  postFrameBuffer = createFrameBuffer(int(maxFrameBufferHeight * (16.0 / 9)),
                                  maxFrameBufferHeight)

proc resize* =
  glViewport(0, 0, GLint(screenWidth), GLint(screenHeight))
  glMatrixMode(GL_PROJECTION)
  glLoadIdentity()
  glOrtho(-screenAspectRatio, screenAspectRatio, -1, 1, -1, 1)
  frameBuffer.resize(min(int(screenAspectRatio * maxFrameBufferHeight), screenWidth),
                     min(maxFrameBufferHeight, screenHeight))
  postFrameBuffer.resize(screenWidth, screenHeight)

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
  uiShader.apply()
  uiShader.setParameter("screenSize", vec2(float(frameBuffer.width), float(frameBuffer.height)));
  let zoom = mainCamera.getPostZoom()
  currentScreen.render(zoom)

  #post processing
  let targetScanLines = float(frameBuffer.height) * targetScanLineFrequency
  let scanLinePeriod = max(2, floor(screenSize.y / (targetScanLines * zoom)))
  let scanLines = screenSize.y / scanLinePeriod;
  let brightnessCompensation = min(scanLinePeriod / 2, 2);

  glBindFrameBuffer(GL_FRAMEBUFFER, postFrameBuffer.fbo)
  glViewport(0, 0, GLint(screenWidth), GLint(screenHeight))
  postShader.apply()
  postShader.setParameter("zoom", zoom)
  postShader.setParameter("t", t)
  postShader.setParameter("scanLines", scanLines)
  postShader.setParameter("scanLineOffset", 0.5 / screenSize.y)
  postShader.setParameter("screenHeight", screenSize.y)
  postShader.setParameter("aspectRatio", screenAspectRatio)
  postShader.setParameter("brightnessCompensation", brightnessCompensation)
  postShader.setTexture("sceneTex", frameBuffer.texture)
  fullscreenQuad()

  glBindFrameBuffer(GL_FRAMEBUFFER, 0)
  post2Shader.apply()
  post2Shader.setParameter("t", t)
  post2Shader.setParameter("blur", mainCamera.getBlur())
  post2Shader.setParameter("aspectRatio", screenAspectRatio)
  post2Shader.setTexture("sceneTex", postFrameBuffer.texture)
  fullscreenQuad()
