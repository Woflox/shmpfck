import opengl
import ../util/util

type
  DrawStyle* {.pure.} = enum
    line, outline, filledOutline, solid
  Vertex* = object
  Shape* = object
    vertices : seq[Vector2]
    transformedVertices : seq[Vector2]
    drawStyle: DrawStyle
    lineColor* : Color
    fillColor* : Color
    visible* :bool
    position* :Vector2
    rotation* :Matrix2x2

proc setTransform* (self: var Shape, transform: Transform) =
  for i in 0..self.vertices.len - 1:
    self.transformedVertices[i] = transform.apply(self.vertices[i])

proc glVertex2d(v:Vector2) =
  glVertex2d(v.x, v.y)

proc glColor4d(c:Color) =
  glColor4d(c.r, c.g, c.b, c.a)

proc renderLine* (self: Shape) =
  if (not self.visible) or self.drawStyle == DrawStyle.solid:
    return

  glColor4d(self.lineColor)
  for i in 0..self.vertices.len-2:
    glVertex2d(self.transformedVertices[i])
    glVertex2d(self.transformedVertices[i+1])
  if self.drawStyle != DrawStyle.line:
    glVertex2d(self.transformedVertices[self.transformedVertices.len-1])
    glVertex2d(self.transformedVertices[0])

proc renderSolid* (self: Shape) =
  if (not self.visible) or
     self.drawStyle == DrawStyle.line or
     self.drawStyle == DrawStyle.outline:
    return

  glColor4d(self.fillColor)
  for i in 1..self.vertices.len-2:
    glVertex2d(self.transformedVertices[0])
    glVertex2d(self.transformedVertices[i])
    glVertex2d(self.transformedVertices[i+1])

proc setVertices (self: var Shape, vertices: seq[Vector2]) =
  self.vertices = vertices
  self.transformedVertices = vertices

proc createIsoTriangle* (width: float, height: float, drawStyle: DrawStyle,
                              lineColor: Color = Color(), fillColor: Color = Color()): Shape =
  result = Shape(drawStyle: drawStyle, lineColor: lineColor, fillColor: fillColor, visible: true)
  result.setVertices(@[vec2(-width/2, 0), vec2(0, height), vec2(width/2,0)])
