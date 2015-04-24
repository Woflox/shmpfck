import opengl

type
  FrameBuffer* = object
    texture*: GluInt
    fbo* : GluInt


proc createFrameBuffer* (width, height: int): FrameBuffer =
  var fb: FrameBuffer

  glGenTextures(1, addr(fb.texture))
  glBindTexture(GL_TEXTURE_2D, fb.texture)
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, GLsizei(width), GLsizei(height), 0,
               GL_RGBA, GL_UNSIGNED_BYTE, nil)
  glBindTexture(GL_TEXTURE_2D, 0)

  glGenFrameBuffers(1, addr(fb.fbo))
  glBindFrameBuffer(GL_FRAME_BUFFER, fb.fbo)
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         fb.texture, 0)
  let status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
  if int(status) != GL_FRAMEBUFFER_COMPLETE:
    echo "Error: Couldn't create Frame Buffer"
  glBindFrameBuffer(GL_FRAMEBUFFER, 0)
  result = fb

proc resize* (self: FrameBuffer, width, height: int) =
  glBindTexture(GL_TEXTURE_2D, self.texture)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, GLsizei(width), GLsizei(height), 0,
               GL_RGBA, GL_UNSIGNED_BYTE, nil)
  glBindTexture(GL_TEXTURE_2D, 0)
