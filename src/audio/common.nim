import math
import ../util/util

proc saturate* (x, amount: float): float =
  lerp(x, sin(x*Pi/2), amount)

proc slowAttackCurve* (x: float): float =
  1 - cos(x*Pi/2)

proc slowReleaseCurve* (x: float): float =
  sin(x*Pi/2)

proc sCurve* (x: float): float =
  (1 - cos(x*Pi))/2

proc bitCrush* (x: float, numBits: int): float =
  let intSize = pow(2.0, float(numBits - 1))
  result = float(round(x * intSize)) / intSize
