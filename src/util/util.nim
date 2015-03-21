import math

const
  goldenRatio* = 0.61803398875

type
  Vector2* = object
    x*, y*: float
  Color* = object
    r*, g*, b*, a*: float
  Matrix2x2* = array[2, array[2, float]]
  Transform* = object
    position*: Vector2
    rotation*: Matrix2x2
  BoundingBox* = object
    minPos*, maxPos*: Vector2

proc `+`*(a, b: Vector2): Vector2 =
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `+=`*(a: var Vector2, b: Vector2) =
  a = a+b

proc `-`*(a, b: Vector2): Vector2 =
  result.x = a.x - b.x
  result.y = a.y - b.y

proc `-=`*(a: var Vector2, b: Vector2) =
  a = a-b

proc `*`*(a, b: Vector2): Vector2 =
  result.x = a.x * b.x
  result.y = a.y * b.y

proc `*`*(a: Vector2, b: float): Vector2 =
  result.x = a.x * b
  result.y = a.y * b

proc `*=`*(a: var Vector2, b: float): Vector2 =
  a = a * b

proc `*`*(a: float, b: Vector2): Vector2 =
  b*a

proc `/`*(a: Vector2, b: float): Vector2 =
  result.x = a.x / b
  result.y = a.y / b

proc `/=`*(a: var Vector2, b: float): Vector2 =
  a = a / b

proc `-`*(a: Vector2): Vector2 =
  a * (-1)

proc dot*(a, b: Vector2): float =
  (a.x * b.x) + (a.y * b.y)

proc length*(a: Vector2): float =
  sqrt(a.x*a.x + a.y*a.y)

proc lengthSquared*(a: Vector2): float =
  a.x*a.x + a.y*a.y

proc distance*(a:Vector2, b:Vector2): float =
  length(a-b)

proc distanceSquared*(a: Vector2, b:Vector2): float =
  lengthSquared(a-b)

proc normalize*(a: Vector2): Vector2 =
  let length = a.length
  if (length != 0):
    result.x = a.x / length
    result.y = a.y / length

proc vec2*(x, y: float): Vector2 =
  Vector2(x: x, y: y)

proc `*`*(a: Matrix2x2, b: Matrix2x2): Matrix2x2 =
  result = [[0.0, 0.0],
            [0.0, 0.0]]
  for i in 0..1:
    for j in 0..1:
      for n in 0..1:
        result[i][j] += a[i][n] * b[n][j]

proc `*`*(a: Matrix2x2, b: Vector2): Vector2 =
  vec2(a[0][0] * b.x + a[0][1] * b.y,
       a[1][0] * b.x + a[1][1] * b.y)

proc `$`*(a: Matrix2x2): string =
  "[[" & $a[0][0] & ", " & $a[0][1] & "]\n [" & $a[1][0] & ", " & $a[1][1] & "]]"

proc apply* (transform: Transform, v: Vector2): Vector2 =
  result = transform.position + transform.rotation*v

proc lerp* (a, b: auto, ratio: float): auto =
  a*(1-ratio) + b*ratio

proc lerp* (a, b: auto, ratio, dt: float): auto =
  a*(pow(ratio, dt)) + b*(1-pow(ratio, dt))

proc angleFromDirection* (dir: Vector2): float =
  arctan2(dir.x, dir.y)

proc directionFromAngle* (a: float): Vector2 =
  vec2(sin(a), cos(a))

proc matrixFromDirection* (dir: Vector2): Matrix2x2 =
  [[ dir.y, dir.x],
   [-dir.x, dir.y]]

#proc matrixFromAngle*(a: float): Matrix2x2 =
#  let
#    sinA = sin(a)
#    cosA = cos(a)
#  result = [[ cosA, sinA],
#            [-sinA, cosA]]

proc matrixFromAngle* (a: float): Matrix2x2 =
  matrixFromDirection(directionFromAngle(a))

proc transpose* (a: Matrix2x2): Matrix2x2 =
  for x in 0..1:
    for y in 0..1:
      result[x][y] = a[y][x]

proc identity* : Matrix2x2 =
  [[1.0, 0.0],
   [0.0, 1.0]]

proc directionFromMatrix*(m: Matrix2x2): Vector2 =
  vec2(m[0][1], m[0][0])

proc angleFromMatrix*(m: Matrix2x2): float =
  angleFromDirection(directionFromMatrix(m))

proc color*(r, g, b: float, a = 1.0): Color =
  Color(r:r, g:g, b:b, a:a)

proc glMatrix*(self: Matrix2x2): array[16, float] =
  [self[0][0], self[1][0], 0, 0,
   self[0][1], self[1][1], 0, 0,
   0         , 0         , 1, 0,
   0         , 0         , 0, 1]

proc radToDeg*(angle: float): float =
  angle * 360 / (2 * Pi)

proc makeAnglesNear* (a: float, b: var float) =
  while b > a + Pi:
    b -= Pi * 2
  while b < a - Pi:
    b += Pi * 2

proc boundingBox* (minPos, maxPos: Vector2): BoundingBox =
  BoundingBox(minPos: minPos, maxPos: maxPos)

proc minimalBoundingBox*(): BoundingBox =
  boundingBox(vec2(100000, 100000), vec2(-100000, -100000))

proc center*(self: BoundingBox): Vector2 =
  (self.minPos + self.maxPos) / 2

proc size*(self: BoundingBox): Vector2 =
  self.maxPos - self.minPos

proc expandTo* (self: var BoundingBox, point: Vector2) =
  self.minPos.x = min(self.minPos.x, point.x)
  self.minPos.y = min(self.minPos.y, point.y)
  self.maxPos.x = max(self.maxPos.x, point.x)
  self.maxPos.y = max(self.maxPos.y, point.y)

proc expandTo* (self: var BoundingBox, box: BoundingBox) =
  self.minPos.x = min(self.minPos.x, box.minPos.x)
  self.minPos.y = min(self.minPos.y, box.minPos.y)
  self.maxPos.x = max(self.maxPos.x, box.maxPos.x)
  self.maxPos.y = max(self.maxPos.y, box.maxPos.y)

proc overlaps* (a: BoundingBox, b: BoundingBox): bool =
  a.minPos.x < b.maxPos.x and a.maxPos.x > b.minPos.x and
    a.minPos.y < b.maxPos.y and a.maxPos.y > b.minPos.y

proc contains* (a: BoundingBox, b: Vector2): bool =
  b.x > a.minPos.x and b.x < a.maxPos.x and
    b.y > a.minPos.y and b.y < a.maxPos.y

proc clamp* (val, minVal, maxVal: float): float =
  max(minVal, min(maxVal, val))
