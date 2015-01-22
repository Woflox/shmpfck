import math

type
  Vector2* = tuple[x, y: float]
  Color* = tuple[r, g, b, a: float]
  Matrix2x2* = array[2, array[2, float]]
  Transform* = tuple[position: Vector2, rotation: Matrix2x2]

proc `+`*(a, b:Vector2) :Vector2 =
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `+=`*(a: var Vector2, b: Vector2) =
  a = a+b

proc `-`*(a, b:Vector2) :Vector2 =
  result.x = a.x - b.x
  result.y = a.y - b.y

proc `*`*(a, b:Vector2) :Vector2 =
  result.x = a.x * b.x
  result.y = a.y * b.y

proc `*`*(a:Vector2, b:float) :Vector2 =
  result.x = a.x * b
  result.y = a.y * b

proc dot*(a, b:Vector2) :float =
  (a.x * b.x) + (a.y * b.y)

proc length*(a:Vector2) :float =
  sqrt(a.x + a.y)

proc normalize*(a:Vector2) :Vector2 =
  let length = a.length
  result.x = a.x / length
  result.y = a.y / length



