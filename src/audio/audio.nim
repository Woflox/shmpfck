import sdl2
import sdl2/audio
import ../util/util
import common
import math
import flite

# Audio settings requested:
const bufferSizeInSamples = 1024
const bytesPerSample = 2  # 16 bit PCM
const sampleRate = 44100    # Hz
var obtained: AudioSpec # Actual audio parameters SDL returns

type
  AudioSample* = array[0..1, float]
  AudioInputObj* = object
    node*: AudioNode
    volume*, pan*: float
    next: AudioInput
    previous: AudioInput
  AudioInput* = ptr AudioInputObj
  AudioNodeObj* = object of RootObj
    firstInput: AudioInput
    lastInput: AudioInput
    output*: AudioSample
    visited: bool
    stopped: bool
    stopOnNoInput: bool
    refCount: int
  AudioNode* = ptr AudioNodeObj

iterator inputs*(self: AudioNode): AudioInput =
  var input = self.firstInput
  while input != nil:
    yield input
    input = input.next

proc getInputNode*(self: AudioNode, index: int): AudioNode =
  var i = 0
  for input in self.inputs:
    if i == index:
      return input.node
    inc i
  return nil

method destruct*(self:AudioNode) =
  discard

proc addRef(self: AudioNode) =
  inc self.refCount

proc releaseRef(self: AudioNode) =
  dec self.refCount
  if self.refCount == 0:
    self.destruct()
    freeShared(self)

proc addInput*(self: AudioNode, node: AudioNode, volume = 1.0, pan = 0.0) =
  var toAdd = createShared(AudioInputObj)
  toAdd[] = AudioInputObj(node: node, volume: volume, pan: pan)

  if self.firstInput == nil:
    self.firstInput = toAdd
    self.lastInput = toAdd
  else:
    self.lastInput.next = toAdd
    toAdd.previous = self.lastInput
    self.lastInput = toAdd

  toAdd.node.addRef()

proc amplitudeToDb*(amplitude: float): float =
  log10(amplitude) * 10

proc dbToAmplitude*(db: float): float =
  pow(10, db / 10)

method updateOutputs*(self: AudioNode, dt: float) =
  discard

proc stop*(self: AudioNode) =
  self.stopped = true

proc setUnvisited(self: AudioNode) =
  self.visited = false
  for input in self.inputs:
    input.node.setUnvisited()

proc update(self: AudioNode, dt: float) =
  self.visited = true
  var input = self.firstInput
  while input != nil:
    if not input.node.visited:
      input.node.update(dt)
    if input.node.stopped:
      if input.previous == nil:
        self.firstInput = input.next
      else:
        input.previous.next = input.next
      if input.next == nil:
        self.lastInput = input.previous
      else:
        input.next.previous = input.previous
      input.node.releaseRef()
      var toFree = input
      input = input.next
      freeShared(toFree)
    else:
      input = input.next
  if self.stopOnNoInput and self.firstInput == nil:
    self.stop()
  else:
    self.updateOutputs(dt)


####################
#
#  MixerNode

type
  MixerNodeObj = object of AudioNodeObj
  MixerNode = ptr MixerNodeObj

proc newMixerNode(): MixerNode =
  result = createShared(MixerNodeObj)
  result[] = MixerNodeObj()

method updateOutputs(self: MixerNode, dt: float) =
  self.output = [0.0, 0.0]
  for input in self.inputs:
    self.output[0] += input.node.output[0] * input.volume * sqrt((-input.pan + 1) / 2)
    self.output[1] += input.node.output[1] * input.volume * sqrt((input.pan + 1) / 2)

####################
#
#  LimiterNode

type
  LimiterNodeObj = object of AudioNodeObj
    threshold, release, limit, timeSinceLimit: float

  LimiterNode = ptr LimiterNodeObj

proc newLimiterNode(threshold: float, release: float): LimiterNode =
  result = createShared(LimiterNodeObj)
  result[] = LimiterNodeObj(threshold: dbToAmplitude(threshold),
                            release: release,
                            timeSinceLimit: release,
                            stopOnNoInput: true)

method updateOutputs(self: LimiterNode, dt: float) =
  let input = self.getInputNode(0).output
  self.timeSinceLimit += dt
  var multiplier = 1.0

  if self.timeSinceLimit < self.release:
    let releaseCurve = sCurve(self.timeSinceLimit / self.release)
    multiplier = lerp(self.limit, 1.0, releaseCurve)

  let peak = max(abs(input[0]), abs(input[1]))
  if peak > self.threshold:
    let newLimit = self.threshold / peak
    if newLimit < multiplier:
      self.limit = newLimit
      multiplier = newLimit
      self.timeSinceLimit = 0

  self.output[0] = input[0] * multiplier
  self.output[1] = input[1] * multiplier

###################
#
#  CompressorNode

type
  CompressorNodeObj = object of AudioNodeObj
    threshold, ratio, attack, release, gain: float


###################
#
#  BitcrusherNode

type
  BitcrusherNodeObj* = object of AudioNodeObj
    numBits: int
  BitcrusherNode = ptr BitcrusherNodeObj

proc newBitCrusherNode*(numBits: int): BitcrusherNode =
  result = createShared(BitcrusherNodeObj)
  result[] = BitcrusherNodeObj(numBits: numBits, stopOnNoInput: true)

method updateOutputs(self: BitcrusherNode, dt: float) =
  for channel in 0..1:
    let input = self.getInputNode(0).output[channel]
    self.output[channel] = bitcrush(input, self.numBits)



###################

#signal chain setup
var masterLimiter = newLimiterNode(threshold = 0, release = 2)
var masterMixer = newMixerNode()
masterLimiter.addInput(masterMixer)

proc playSound*(node: AudioNode, volume, pan: float) =
  #TODO: add ducking priority param to choose parent node; side chain compression
  lockAudio()
  masterMixer.addInput(node, dbToAmplitude(volume), pan)
  unlockAudio()

# Write amplitude direct to hardware buffer
proc audioCallback(userdata: pointer; stream: ptr uint8; len: cint) {.cdecl, thread, gcsafe.} =
  let dt = 1.0 / float(obtained.freq)
  var i = 0
  while i < int16(obtained.samples)*2-1:
    var leftSamplePtr = cast[ptr int16](cast[int](stream) + i * bytesPerSample)
    var rightSamplePtr = cast[ptr int16](cast[int](leftSamplePtr) + bytesPersample)
    masterLimiter.setUnvisited()
    masterLimiter.update(dt)
    leftSamplePtr[] = int16(masterLimiter.output[0] * float(int16.high))
    rightSamplePtr[] = int16(masterLimiter.output[1] * float(int16.high))
    i += 2

proc initAudio* =
  var audioSpec: AudioSpec
  audioSpec.freq = cint(sampleRate)
  audioSpec.format = AUDIO_S16 # 16 bit PCM
  audioSpec.channels = 2       # stereo
  audioSpec.samples = bufferSizeInSamples
  audioSpec.padding = 0
  audioSpec.callback = audioCallback
  audioSpec.userdata = nil
  if openAudio(addr(audioSpec), addr(obtained)) != 0:
    echo("Couldn't open audio device. " & $getError() & "\n")
    return
  echo "Audio:"
  echo("  sample rate: ", obtained.freq)
  echo("  format: ", obtained.format)
  echo("  channels: ", obtained.channels)
  echo("  buffer size: ", obtained.samples)
  echo("  padding: ", obtained.padding)
  if obtained.format != AUDIO_S16:
    echo("Couldn't open 16-bit audio channel.")
    return
  if obtained.channels != 2:
    echo("Couldn't open stereo audio channels.")
    return

  pauseAudio(0)
