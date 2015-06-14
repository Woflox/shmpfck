import mersenne
import times
import util
import math

var mt = newMersenneTwister(int(epochTime()))

proc rand(self: var MersenneTwister): uint32 {.inline.}=
  cast[uint32](self.getNum())

proc newRandom* (seed: int): MersenneTwister =
  newMersenneTwister(seed)

proc random* (self: var MersenneTwister, minValue, maxValue: int): int =
  result = ((self.getNum() and high(int)) mod (maxValue + 1 - minValue)) + minValue

proc random* (self: var MersenneTwister, minValue, maxValue: float): float =
  float(self.rand()) * ((maxValue - minValue) / float(high(uint32))) + minValue

proc uniformRandom* (self: var MersenneTwister): float =
  float(self.rand()) / float(high(uint32))

proc randomChoice* (self: var MersenneTwister, sequence): auto =
  sequence[self.random(low(sequence), high(sequence))]

proc randomDirection* (self: var MersenneTwister): Vector2 =
  directionFromAngle(self.random(0, 2*Pi))

proc seed* (seed: int) =
  mt = newMersenneTwister(seed)

proc random* (minValue, maxValue: int): int =
  mt.random(minValue, maxValue)

proc random* (minValue, maxValue: float): float =
  mt.random(minValue, maxValue)

proc uniformRandom* : float =
  mt.uniformRandom()

proc randomChoice* (sequence): auto =
  mt.randomChoice(sequence)

proc randomDirection* : Vector2 =
  mt.randomDirection()

proc expRandom* (frequency: float) : float =
  -ln(uniformRandom()) / frequency

