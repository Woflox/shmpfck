import opengl
import ../util/util

type
  DrawStyle* {.pure.} = enum
    none, line, filledOutline, solid
  CollisionType* {.pure.} = enum
    none, discrete, continuous
  Shape* = object
    relativeVertices* : seq[Vector2]
    vertices* : seq[Vector2]
    lastVertices* : seq[Vector2]
    drawStyle: DrawStyle
    collisionType* : CollisionType
    lineColor* : Color
    fillColor* : Color
    absolutePosition* : bool
    closed* : bool
    boundingBox*: BoundingBox

iterator collisionLines(self: Shape): array[2, Vector2] =
  for i in 0..high(self.vertices)-1:
    yield [self.vertices[i], self.vertices[i+1]]
  if self.closed:
    yield [self.vertices[high(self.vertices)], self.vertices[0]]
  if self.collisionType == CollisionType.continuous:
    for i in 0..high(self.lastVertices)-1:
      yield [self.lastVertices[i], self.lastVertices[i+1]]
    if self.closed:
      yield [self.lastVertices[high(self.lastVertices)], self.lastVertices[0]]
    for i in 0..high(self.vertices):
      yield [self.vertices[i], self.lastVertices[i]]


proc linesIntersect(point1, point2, point3, point4: Vector2): bool =
  var ua = (point4.x - point3.x) * (point1.y - point3.y) -
           (point4.y - point3.y) * (point1.x - point3.x)
  var ub = (point2.x - point1.x) * (point1.y - point3.y) -
           (point2.y - point1.y) * (point1.x - point3.x)
  let denominator = (point4.y - point3.y) * (point2.x - point1.x) -
                    (point4.x - point3.x) * (point2.y - point1.y)
  if denominator == 0.0:
      return ua == 0.0 and ub == 0.0
  else:
    ua /= denominator
    ub /= denominator;
    return ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1

proc intersects* (self: Shape, other: Shape): bool =
  if other.collisionType == CollisionType.none or
      not self.boundingBox.overlaps(other.boundingBox):
    return false

  for line in self.collisionLines:
    for otherLine in other.collisionLines:
      if linesIntersect(line[0], line[1], otherLine[0], otherLine[1]):
        return true

proc update* (self: var Shape, transform: Transform) =
  if not self.absolutePosition:
    self.boundingBox = minimalBoundingBox()
    if self.collisionType == CollisionType.continuous:
      self.lastVertices = self.vertices
      for i in 0..high(self.lastVertices):
        self.boundingBox.expandTo(self.lastVertices[i])
    for i in 0..high(self.vertices):
      self.vertices[i] = transform.apply(self.relativeVertices[i])
      self.boundingBox.expandTo(self.vertices[i])

proc glVertex2d(v:Vector2) =
  glVertex2d(v.x, v.y)

proc glColor4d(c:Color) =
  glColor4d(c.r, c.g, c.b, c.a)

proc renderLine* (self: Shape) =
  if self.drawStyle == DrawStyle.none or self.drawStyle == DrawStyle.solid:
    return

  glColor4d(self.lineColor)
  for i in 0..high(self.vertices)-1:
    glVertex2d(self.vertices[i])
    glVertex2d(self.vertices[i+1])
  if self.closed:
    glVertex2d(self.vertices[high(self.vertices)])
    glVertex2d(self.vertices[0])

proc renderSolid* (self: Shape) =
  if self.drawStyle == DrawStyle.none or self.drawStyle == DrawStyle.line:
    return

  glColor4d(self.fillColor)
  for i in 0..high(self.vertices)-1:
    glVertex2d(self.vertices[0])
    glVertex2d(self.vertices[i])
    glVertex2d(self.vertices[i+1])

proc setVertices (self: var Shape, vertices: seq[Vector2]) =
  self.vertices = vertices
  if self.absolutePosition:
    for i in 0..high(self.vertices):
      self.boundingBox.expandTo(self.vertices[i])
  else:
    self.relativeVertices = vertices

proc newShape* (vertices: seq[Vector2], drawStyle = DrawStyle.none,
                lineColor = Color(), fillColor = Color(), closed = true,
                collisionType = CollisionType.none, absolutePosition = false): Shape =
  result = Shape(drawStyle: drawStyle, lineColor: lineColor, fillColor: fillColor,
                 absolutePosition: absolutePosition, collisionType: collisionType)
  result.setVertices(vertices)

proc createIsoTriangle* (width: float, height: float, drawStyle = DrawStyle.none,
                         lineColor = Color(), fillColor = Color(),
                         position = vec2(0,0), collisionType = CollisionType.none,
                         absolutePosition = false): Shape =
  result = Shape(drawStyle: drawStyle, lineColor: lineColor, fillColor: fillColor, closed: true,
                 absolutePosition: absolutePosition, collisionType: collisionType)
  result.setVertices(@[vec2(-width/2, 0) + position,
                       vec2(0, height) + position,
                       vec2(width/2,0) + position])
