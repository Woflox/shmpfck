import audio
import math
import ../util/util

type
  ShotNodeObj = object of AudioNodeObj
    t: float
  ShotNode* = ptr ShotNodeObj

proc newShotNode*(): ShotNode =
  result = createShared(ShotNodeObj)
  result[] = ShotNodeObj()

method updateOutputs*(self: ShotNode, dt: float) =
  if self.t >= 0.2:
    self.stop()
    self.output = [0.0, 0.0]
    return

  self.t += dt

  var output = ((1 / self.t) mod 1) * 2 - 1
  if output > 0:
    output = 1
  else:
    output = 0
  output *= 1 - self.t / 0.2

  self.output[0] = output
  self.output[1] = output
