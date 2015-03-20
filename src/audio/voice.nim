import audio
import flite
import flite/rms
import math
import audioutil

type
  VoiceNodeObj = object of AudioNodeObj
    t: float
    wave: Wave
  VoiceNode* = ptr VoiceNodeObj

let fliteSuccess = fliteInit()
let voice = registerCmuUsRms(nil)

const speed = 1.0
const volumeBoost = 4.0
const saturation = -1.0

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

  output = saturate(output, saturation)

  output = clamp(output*volumeBoost, -1, 1)

  self.output[0] = output
  self.output[1] = output

  self.t += dt
