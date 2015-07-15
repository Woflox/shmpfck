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
  Line* = array[2, Vector2]
  Triangle* = array[3, Vector2]

iterator collisionLines(self: Shape): Line =
  for i in 0..<self.vertices.high:
    yield [self.vertices[i], self.vertices[i+1]]
  if self.closed:
    yield [self.vertices[self.vertices.high], self.vertices[0]]
  if self.collisionType == CollisionType.continuous:
    yield [self.vertices[0], self.lastVertices[0]]

iterator collisionTriangles(self: Shape): Triangle =
  if self.closed:
    for i in 1..<self.vertices.high:
      yield [self.vertices[0], self.vertices[i], self.vertices[i+1]]
  if self.collisionType == CollisionType.continuous:
    for i in 0..<self.vertices.high:
      yield [self.vertices[i], self.lastVertices[i], self.lastVertices[i+1]]
      yield [self.vertices[i], self.vertices[i+1], self.lastVertices[i+1]]
    if self.closed:
      yield [self.vertices[self.vertices.high],
             self.lastVertices[self.vertices.high],
             self.lastVertices[0]]
      yield [self.vertices[self.vertices.high],
             self.vertices[0],
             self.lastVertices[0]]

proc hasCollisionTriangles(self: Shape): bool =
  self.closed or (self.collisionType == CollisionType.continuous and self.vertices.len > 1)

proc linesIntersect(line1, line2: Line): bool =
  var ua = (line2[1].x - line2[0].x) * (line1[0].y - line2[0].y) -
           (line2[1].y - line2[0].y) * (line1[0].x - line2[0].x)
  var ub = (line1[1].x - line1[0].x) * (line1[0].y - line2[0].y) -
           (line1[1].y - line1[0].y) * (line1[0].x - line2[0].x)
  let denominator = (line2[1].y - line2[0].y) * (line1[1].x - line1[0].x) -
                    (line2[1].x - line2[0].x) * (line1[1].y - line1[0].y)
  if denominator == 0.0:
      return ua == 0.0 and ub == 0.0
  else:
    ua /= denominator
    ub /= denominator;
    return ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1

proc sameSide(p1, p2, a, b: Vector2): bool =
  let cp1 = (b-a).cross(p1-a)
  let cp2 = (b-a).cross(p2-a)
  result = cp1 * cp2 >= 0

proc pointInTriangle(p: Vector2, a: Triangle): bool =
  sameSide(p,a[0], a[1],a[2]) and sameSide(p,a[1], a[0], a[2]) and sameSide(p, a[2], a[0], a[1])

proc trianglesIntersect(a, b: Triangle): bool =
  linesIntersect([a[0], a[1]], [b[0], b[1]]) or
    linesIntersect([a[1], a[2]], [b[0], b[1]]) or
    pointInTriangle(a[0], b) or pointInTriangle(a[1], b) or pointInTriangle(a[2], b) or
    pointInTriangle(b[0], a) or pointInTriangle(b[1], a) or pointInTriangle(b[2], a)

proc lineIntersectsTriangle(a: Line, b: Triangle): bool =
  linesIntersect(a, [b[0], b[1]]) or linesIntersect(a, [b[1], b[2]]) or
    pointInTriangle(a[0], b) or pointInTriangle(a[1], b)


proc intersects* (self: Shape, other: Shape): bool =
  if other.collisionType == CollisionType.none or
      not self.boundingBox.overlaps(other.boundingBox):
    return false

  if self.hasCollisionTriangles and other.hasCollisionTriangles:
    for triangle in self.collisionTriangles:
      for otherTriangle in other.collisionTriangles:
        if trianglesIntersect(triangle, otherTriangle):
          return true
  elif self.hasCollisionTriangles and not other.hasCollisionTriangles:
    for triangle in self.collisionTriangles:
      for line in other.collisionLines:
        if lineIntersectsTriangle(line, triangle):
          return true
  elif not other.hasCollisionTriangles:
    for line in self.collisionLines:
      for triangle in self.collisionTriangles:
        if lineIntersectsTriangle(line, triangle):
          return true
  else:
    for line in self.collisionLines:
      for otherLine in other.collisionLines:
        if linesIntersect(line, otherLine):
          return true

proc update* (self: var Shape, transform: Transform) =
  if not self.absolutePosition:
    self.boundingBox = minimalBoundingBox()
    if self.collisionType == CollisionType.continuous:
      self.lastVertices = self.vertices
      for i in 0..self.lastVertices.high:
        self.boundingBox.expandTo(self.lastVertices[i])
    for i in 0..self.vertices.high:
      self.vertices[i] = transform.apply(self.relativeVertices[i])
      self.boundingBox.expandTo(self.vertices[i])

proc init* (self: var Shape, transform: Transform) =
  if not self.absolutePosition:
    for i in 0..self.vertices.high:
      self.vertices[i] = transform.apply(self.relativeVertices[i])
    if self.collisionType == CollisionType.continuous:
      self.lastVertices = self.vertices

  self.boundingBox = minimalBoundingBox()
  for i in 0..self.vertices.high:
    self.boundingBox.expandTo(self.vertices[i])

proc glVertex2d* (v:Vector2) =
  glVertex2d(v.x, v.y)

proc glColor4d* (c:Color) =
  glColor4d(c.r, c.g, c.b, c.a)

proc renderLine* (self: Shape) =
  if self.drawStyle == DrawStyle.none or self.drawStyle == DrawStyle.solid:
    return

  glColor4d(self.lineColor)
  for i in 0..<self.vertices.high:
    glVertex2d(self.vertices[i])
    glVertex2d(self.vertices[i+1])
  if self.closed:
    glVertex2d(self.vertices[self.vertices.high])
    glVertex2d(self.vertices[0])

proc renderSolid* (self: Shape) =
  if self.drawStyle == DrawStyle.none or self.drawStyle == DrawStyle.line:
    return

  glColor4d(self.fillColor)
  for i in 0..<self.vertices.high:
    glVertex2d(self.vertices[0])
    glVertex2d(self.vertices[i])
    glVertex2d(self.vertices[i+1])

proc setVertices (self: var Shape, vertices: seq[Vector2]) =
  self.vertices = vertices
  if self.absolutePosition:
    for i in 0..self.vertices.high:
      self.boundingBox.expandTo(self.vertices[i])
  else:
    self.relativeVertices = vertices

proc newShape* (vertices: seq[Vector2], drawStyle = DrawStyle.none,
                lineColor = Color(), fillColor = Color(), closed = true,
                collisionType = CollisionType.none, absolutePosition = false): Shape =
  result = Shape(drawStyle: drawStyle, lineColor: lineColor, fillColor: fillColor,
                 absolutePosition: absolutePosition, collisionType: collisionType,
                 closed: closed)
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
