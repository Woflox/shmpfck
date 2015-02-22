import math

type
  Vector2* = object
    x*, y*: float
  Color* = object
    r*, g*, b*, a*: float
  Matrix2x2* = array[2, array[2, float]]

proc `+`*(a, b:Vector2): Vector2 =
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `+=`*(a: var Vector2, b: Vector2) =
  a = a+b

proc `-`*(a, b:Vector2): Vector2 =
  result.x = a.x - b.x
  result.y = a.y - b.y

proc `*`*(a, b:Vector2): Vector2 =
  result.x = a.x * b.x
  result.y = a.y * b.y

proc `*`*(a:Vector2, b:float): Vector2 =
  result.x = a.x * b
  result.y = a.y * b

proc `*`*(a:float, b:Vector2): Vector2 =
  b*a

proc `/`*(a:Vector2, b:float): Vector2 =
  result.x = a.x / b
  result.y = a.y / b

proc dot*(a, b:Vector2): float =
  (a.x * b.x) + (a.y * b.y)

proc length*(a:Vector2): float =
  sqrt(a.x*a.x + a.y*a.y)

proc normalize*(a:Vector2): Vector2 =
  let length = a.length
  if (length != 0):
    result.x = a.x / length
    result.y = a.y / length

proc vec2*(x, y:float): Vector2 =
  Vector2(x:x, y:y)

proc `*`*(a:Matrix2x2, b:Matrix2x2): Matrix2x2 =
  for i in 0..1:
    for j in 0..1:
      for n in 0..1:
        result[i][j] += a[i][n] * b[n][j]

proc `*`*(a:Matrix2x2, b:Vector2): Vector2 =
  vec2(a[0][0] * b.x + a[0][1] * b.y,
       a[1][0] * b.x + a[1][1] * b.y)

proc lerp* (a, b: auto, ratio: float): auto =
  a*(1-ratio) + b*ratio

proc lerp* (a, b: auto, ratio, dt: float): auto =
  a*(pow(ratio, dt)) + b*(1-pow(ratio, dt))

proc matrixFromAngle*(a: float): Matrix2x2 =
  let
    sinA = sin(a)
    cosA = cos(a)
  result = [[ cosA, sinA],
            [-sinA, cosA]]

proc angleFromDirection*(dir: Vector2): float =
  arctan2(dir.x, dir.y)

proc directionFromAngle*(a: float): Vector2 =
  vec2(sin(a), cos(a))

proc matrixFromDirection*(dir: Vector2): Matrix2x2 =
  [[ dir.y, dir.x],
   [-dir.x, dir.y]]

proc col*(r, g, b: float, a = 1.0): Color =
  Color(r:r, g:g, b:b, a:a)

proc glMatrix*(self: Matrix2x2): array[16, float] =
  [self[0][0], self[1][0], 0, 0,
   self[0][1], self[1][1], 0, 0,
   0         , 0         , 1, 0,
   0         , 0         , 0, 1]

proc radToDeg*(angle: float): float =
  angle * 360 / (2 * Pi)
