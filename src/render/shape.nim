import opengl
import ../util/util

type
  DrawStyle* {.pure.} = enum
    line, outline, filledOutline, solid
  Shape* = object
    drawStyle : DrawStyle
    vertices : seq[Vector2]
    lineColor* : Color
    fillColor* : Color
    visible* :bool
    position* :Vector2
    rotation* :Matrix2x2

proc drawLine* (self: Shape) =
  glColor4d(self.lineColor.r, self.lineColor.g, self.lineColor.b, self.lineColor.a)
  for vertex in self.vertices:
    glVertex2d(vertex.x, vertex.y)
    if self.drawStyle != DrawStyle.line:
      glVertex2d(self.vertices[0].x, self.vertices[0].y)

proc drawSolid* (self: Shape) =
  glColor4d(self.fillColor.r, self.fillColor.g, self.fillColor.b, self.fillColor.a)
  for vertex in self.vertices:
    glVertex2d(vertex.x, vertex.y)
    glVertex2d(self.vertices[0].x, self.vertices[0].y)

proc render* (self: Shape) =
  if self.visible:
    if self.drawStyle == DrawStyle.filledOutline or self.drawStyle == DrawStyle.solid:
        glBegin(GL_TRIANGLE_FAN)
        self.drawSolid()
        glEnd()
    if self.drawStyle != DrawStyle.solid:
        glBegin(GL_LINES)
        self.drawLine()
        glEnd()

proc test*: Shape =
  discard

proc createIsoTriangle* (width: float, height: float, drawStyle: DrawStyle,
                              lineColor: Color = Color(), fillColor: Color = Color()): Shape =
  result = Shape(drawStyle: drawStyle, lineColor: lineColor, fillColor: fillColor, visible: true)
  result.vertices = @[vec2(-width/2, 0), vec2(0, height), vec2(width/2,0)]
