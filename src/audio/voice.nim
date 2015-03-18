import audio
import flite

type
  VoiceNodeObj = object of AudioNodeObj
    t: float
    wave: Wave
  VoiceNode* = ptr VoiceNodeObj

let fliteSuccess = fliteInit()
let voice = fliteVoiceSelect("cmu_us_kal_diphone")

proc newVoiceNode*(text: string): VoiceNode =
  result = createShared(VoiceNodeObj)
  result[] = VoiceNodeObj()
  result.wave = fliteTextToWave(text, voice)
  echo "NEWVOICENODE"
  if result.wave != nil:
    echo "Sample rate: ", result.wave.sampleRate
    echo "Num channels: ", result.wave.numChannels

method updateOutputs*(self: VoiceNode, dt: float) =
  self.output = [0.0, 0.0]
  if self.wave == nil:
    return

  let index = int(self.t * float(self.wave.sampleRate))
  if index >= self.wave.numSamples:
    return

  var output = float(self.wave[index]) / float(high(int16))

  self.output[0] = output
  self.output[1] = output

  self.t += dt
