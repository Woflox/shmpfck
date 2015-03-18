import audio
import math
import ../util/util
import ../util/random

type
  ExplosionNodeObj = object of AudioNodeObj
    t: float
  ExplosionNode* = ptr ExplosionNodeObj

proc newExplosionNode*(): ExplosionNode =
  result = createShared(ExplosionNodeObj)
  result[] = ExplosionNodeObj()

method updateOutputs*(self: ExplosionNode, dt: float) =
  if self.t >= 0.5:
    self.stop()
    self.output = [0.0, 0.0]
    return

  self.t += dt

  var output = uniformRandom() / exp(self.t*10)

  self.output[0] = output
  self.output[1] = output
