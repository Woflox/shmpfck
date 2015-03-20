import math
import ../util/util

proc saturate* (x, amount: float): float =
  result = lerp(x, sin(x*Pi/2), amount)
