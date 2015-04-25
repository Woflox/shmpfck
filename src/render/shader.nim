import opengl
import ../util/util

type
  ShaderProgram* = Gluint

proc compileShader(source: var cstring, shaderType: GLenum): GLuint =
  result = glCreateShader(shaderType)
  glShaderSource(result, GLsizei(1), cast[cstringArray](addr source), nil)
  glCompileShader(result)
  var compiled: GLint
  glGetShaderiv(result, GLenum(GL_COMPILE_STATUS), addr compiled)
  if compiled == GL_FALSE:
    var messageLength: GLint
    glGetShaderiv(result, GLenum(GL_INFO_LOG_LENGTH), addr messageLength)
    var message = newString(messageLength).cstring
    glGetShaderInfoLog(result, messageLength, nil, message)
    echo message , " (", source, ")"

proc newShaderProgram* (vs, ps: string): ShaderProgram =
  var vsCstring = vs.cstring
  var psCstring = ps.cstring
  let vertexShaderObject = compileShader(vsCstring, GLenum(GL_VERTEX_SHADER))
  let fragmentShaderObject = compileShader(psCstring, GLenum(GL_FRAGMENT_SHADER))
  result = glCreateProgram()
  glAttachShader(result, vertexShaderObject)
  glAttachShader(result, fragmentShaderObject)
  glLinkProgram(result)
  var linked: GLint
  glGetProgramiv(result, GLenum(GL_LINK_STATUS), addr linked)
  if linked == GL_FALSE:
    var messageLength: GLint
    glGetProgramiv(result, GLenum(GL_INFO_LOG_LENGTH), addr messageLength)
    var message = newString(messageLength).cstring
    glGetProgramInfoLog(result, messageLength, nil, message)
    echo message

proc apply* (self: ShaderProgram) =
  glUseProgram(self)

proc getParameterLocation(self: ShaderProgram, name: string): GLint =
  glGetUniformLocation(self, name.cstring)

proc setParameter* (self: ShaderProgram, name: string, value: float) =
  self.apply()
  glUniform1f(self.getParameterLocation(name), value)

proc setParameter* (self: ShaderProgram, name: string, value: Vector2) =
  self.apply()
  glUniform2f(self.getParameterLocation(name), value.x, value.y)

proc setTexture* (self: ShaderProgram, name: string, texture: GluInt) =
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, texture)
  glUniform1i(self.getParameterLocation(name), 0)
