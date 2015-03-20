import audio
import flite
import flite/rms
import math

type
  VoiceNodeObj = object of AudioNodeObj
    t: float
    wave: Wave
  VoiceNode* = ptr VoiceNodeObj

let fliteSuccess = fliteInit()
let voice = registerCmuUsRms(nil)

const speed = 0.95
const saturation = 0

proc newVoiceNode*(text: string): VoiceNode =
  result = createShared(VoiceNodeObj)
  result[] = VoiceNodeObj()
  result.wave = fliteTextToWave(text, voice)
  if result.wave != nil:
    echo "Voice: ", voice.name
    echo "Sample rate: ", result.wave.sampleRate
    echo "Num channels: ", result.wave.numChannels

method destruct*(self: VoiceNode) =
  self.wave.delete()

method updateOutputs*(self: VoiceNode, dt: float) =
  self.output = [0.0, 0.0]
  if self.wave == nil:
    self.stop()
    return

  let index = int(self.t * speed * float(self.wave.sampleRate))
  if index >= self.wave.numSamples:
    self.stop()
    return

  var output = float(self.wave[index]) / float(high(int16))

  if output > 0:
    output = pow(output, 1 - saturation)
  else:
    output = -pow(-output, 1 - saturation)

  self.output[0] = output
  self.output[1] = output

  self.t += dt
