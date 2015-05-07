import audio
import flite
import flite/rms
import math
import common
import threadpool
import ../util/util

type
  VoiceNodeObj = object of AudioNodeObj
    t: float
    wave: Wave
  VoiceNode* = ptr VoiceNodeObj

let fliteSuccess = fliteInit()
let voice = registerCmuUsRms(nil)

const speed = 1.0
const volumeBoost = 2.5
const saturation = -0.5
const numBits = 4
const downSample = 8
const bitcrushedSaturation = 1.0
const bitcrushMix = 0.075
const stereoDelay = 0.005

proc newVoiceNode(text: string): VoiceNode =
  result = createShared(VoiceNodeObj)
  result[] = VoiceNodeObj()
  result.wave = fliteTextToWave(text, voice)
  if result.wave != nil:
    echo "Voice node:"
    echo "  voice: ", voice.name
    echo "  sample rate: ", result.wave.sampleRate
    echo "  channels: ", result.wave.numChannels

method destruct*(self: VoiceNode) =
  self.wave.delete()

method updateOutputs*(self: VoiceNode, dt: float) =
  self.output = [0.0, 0.0]
  if self.wave == nil:
    self.stop()
    return

  for channel in 0..1:
    let index = int((self.t + stereoDelay * float(channel)) * speed * float(self.wave.sampleRate))
    let downSampledIndex = int(index / downSample) * downSample
    if index >= self.wave.numSamples:
      self.stop()
      return

    var sample = float(self.wave[index]) / float(high(int16))
    var bitcrushedSample = float(self.wave[downSampledIndex]) / float(high(int16))
    bitcrushedSample = bitcrush(bitcrushedSample, numBits)
    bitcrushedSample = saturate(bitcrushedSample, bitcrushedSaturation)
    sample = saturate(sample, saturation)
    var output = lerp(sample, bitcrushedSample, bitcrushMix)

    output *= volumeBoost

    self.output[channel] = output

  self.t += dt

proc createAndPlayVoiceNode(text: string) =
  let node = newVoiceNode(text)
  playSound(node, -1.0, 0.0)

proc say*(text: string) =
  spawn createAndPlayVoiceNode(text)
