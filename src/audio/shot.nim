import audio
import math
import ../util/util
import ../util/random

type
  ShotNodeObj = object of AudioNodeObj
    t: float
    pitchBend: float
    fade: float
  ShotNode* = ptr ShotNodeObj

proc newShotNode*(): ShotNode =
  result = createShared(ShotNodeObj)
  result[] = ShotNodeObj()
  result.fade = random(0.05, 0.2)
  result.pitchBend = random(0.1, 20)

method updateOutputs*(self: ShotNode, dt: float) =
  if self.t >= 0.2:
    self.stop()
    self.output = [0.0, 0.0]
    return

  self.t += dt

  var output = ((self.pitchBend / self.t) mod 1) * 2 - 1
  if output > 0:
    output = 1
  else:
    output = 0
  output *= max(0, 1 - self.t / self.fade)

  self.output[0] = output
  self.output[1] = output
