import audio
import math
import ../util/noise
import ../util/random
import ../util/util

type
  AmbientNodeObj = object of AudioNodeObj
    t: float
  AmbientNode* = ptr AmbientNodeObj

const
  noiseFrequency = 0.5
  noiseOctaves = 3

proc newAmbientNode*(): AmbientNode =
  result = createShared(AmbientNodeObj)
  result[] = AmbientNodeObj()

method updateOutputs*(self: AmbientNode, dt: float) =
  var output = 0.0
  let noiseVal = (fractalNoise(self.t * noiseFrequency, noiseOctaves) + 1) / 2
  let noiseVal2 = (fractalNoise((self.t + 100) / noiseFrequency, noiseOctaves) + 1) / 2
  output = ((self.t * 40) mod 1.0) * 2 - 1
  output *= lerp(1.0, uniformRandom(), noiseVal)
  output = lerp(output, fractalNoise(self.t * 50, 10), noiseVal2)

  self.output[0] = output
  self.output[1] = output

  if (self.t * 79.9) mod 1.0 > 0.5:
    self.output[0] = 0
    self.output[1] *= 0.5
  if (self.t * 40.25) mod 1.0 > 0.5:
    self.output[1] = 0
    self.output[0] *= 0.5

  self.t += dt
