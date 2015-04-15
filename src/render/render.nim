import ../util/util
import shader

include shaders/basic.frag
include shaders/basic.vert

var basicShader* : ShaderProgram

proc initShaders* =
  basicShader = newShaderProgram(basicFrag, basicVert)
