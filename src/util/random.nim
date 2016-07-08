import mersenne
import times
import util
import math

var mt = newMersenneTwister(uint32(epochTime()))

proc rand(self: var MersenneTwister): uint32 {.inline.}=
  self.getNum()

proc newRandom* (seed: uint32): MersenneTwister =
  newMersenneTwister(seed)

proc random* (self: var MersenneTwister, minValue, maxValue: int): int =
  result = int(self.getNum() mod uint32(maxValue + 1 - minValue)) + minValue

proc random* (self: var MersenneTwister, minValue, maxValue: float): float =
  float(self.rand()) * ((maxValue - minValue) / float(uint32.high)) + minValue

proc uniformRandom* (self: var MersenneTwister): float =
  float(self.rand()) / float(uint32.high)

proc randomChoice* (self: var MersenneTwister, choices: auto): distinct auto =
  choices[self.random(int(choices.low), int(choices.high))]

proc randomChoice* [T](self: var MersenneTwister, choices: varargs[T]): T =
  randomChoice(choices)

template randomEnumValue* (merseneTwister, kind: expr): expr =
  kind(merseneTwister.random(ord(kind.low), ord(kind.high)))
  
proc randomChance* (self: var MersenneTwister, probability: float): bool =
  return self.uniformRandom() < probability

proc randomDirection* (self: var MersenneTwister): Vector2 =
  directionFromAngle(self.random(0, 2*Pi))

proc randomPointInDisc* (self: var MersenneTwister, radius: float): Vector2 =
  self.randomDirection() * sqrt(self.uniformRandom()) * radius

proc expRandom* (self: var MersenneTwister, frequency: float) : float =
  -ln(self.uniformRandom()) / frequency

proc relativeRandom* (self: var MersenneTwister, median: float, maxMultiplier: float) : float =
  median * (pow(maxMultiplier, self.random(-1.0, 1.0)))

proc seed* (seed: uint32) =
  mt = newMersenneTwister(seed)

proc random* (minValue, maxValue: int): int =
  mt.random(minValue, maxValue)

proc random* (minValue, maxValue: float): float =
  mt.random(minValue, maxValue)

proc uniformRandom* : float =
  mt.uniformRandom()

proc randomChoice* (choices: auto): distinct auto =
  mt.randomChoice(choices)

proc randomChoice* [T](choices: varargs[T]): T =
  mt.randomChoice(choices)

template randomEnumValue* (kind: expr): expr =
  kind(random(ord(kind.low), ord(kind.high)))

proc randomChance* (probability: float): bool =
  mt.randomChance(probability)

proc randomDirection* : Vector2 =
  mt.randomDirection()

proc randomPointInDisc* (radius: float) : Vector2 =
  mt.randomPointInDisc(radius)

proc expRandom* (frequency: float) : float =
  mt.expRandom(frequency)

proc relativeRandom* (median: float, maxMultiplier: float) : float =
  mt.relativeRandom(median, maxMultiplier)
