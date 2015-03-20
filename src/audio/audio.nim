import sdl2
import sdl2/audio
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
    input: AudioInput
    lastInput: AudioInput
    output*: AudioSample
    visited: bool
    stopped: bool
    refCount: int
  AudioNode* = ptr AudioNodeObj
  MixerNodeObj* = object of AudioNodeObj
  MixerNode* = ptr MixerNodeObj
  LimiterNode* = object of AudioNode
    threshold, release: float
  CompressorNode* = object of AudioNode
    threshold, release, attack, ratio, gain: float

iterator inputs*(self: AudioNode): AudioInput =
  discard
  var input = self.input
  while input != nil:
    yield input
    input = input.next

proc getInputNode*(self: AudioNode, index): AudioNode =
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

proc addInput(self: AudioNode, node: AudioNode, volume = 1.0, pan = 0.0) =
  var toAdd = createShared(AudioInputObj)
  toAdd[] = AudioInputObj(node: node, volume: volume, pan: pan)

  if self.input == nil:
    self.input = toAdd
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

method updateOutputs*(self: MixerNode, dt: float) =
  self.output = [0.0, 0.0]
  for input in self.inputs:
    self.output[0] += input.node.output[0] * input.volume * sqrt((-input.pan + 1) / 2)
    self.output[1] += input.node.output[1] * input.volume * sqrt((input.pan + 1) / 2)

proc stop*(self: AudioNode) =
  self.stopped = true

proc setUnvisited(self: AudioNode) =
  self.visited = false
  for input in self.inputs:
    input.node.setUnvisited()

proc update(self: AudioNode, dt: float) =
  self.visited = true
  var input = self.input
  while input != nil:
    if not input.node.visited:
      input.node.update(dt)
    if input.node.stopped:
      if input.previous == nil:
        self.input = input.next
      else:
        input.previous.next = input.next
      if input.next == nil:
        self.lastInput = input.previous
      else:
        input.next.previous = input.previous
      if input.previous == nil:
        self.input = input.next
      input.node.releaseRef()
      var toFree = input
      input = input.next
      freeShared(toFree)
    else:
      input = input.next
  self.updateOutputs(dt)



proc newMixerNode*(): MixerNode =
  result = createShared(MixerNodeObj)
  result[] = MixerNodeObj()

var masterNode = newMixerNode()

proc playSound*(node: AudioNode, volume, pan: float) =
  #TODO: add ducking priority param to choose parent node; side chain compression
  lockAudio()
  masterNode.addInput(node, dbToAmplitude(volume), pan)
  unlockAudio()

var t = 0.0
# Write amplitude direct to hardware buffer
proc audioCallback(userdata: pointer; stream: ptr uint8; len: cint) {.cdecl, thread, gcsafe.} =
  let dt = 1.0 / float(obtained.freq)
  var i = 0
  #var testNode = newMixerNode()
  while i < int16(obtained.samples)*2-1:
    t += dt
    var leftSamplePtr = cast[ptr int16](cast[int](stream) + i * bytesPerSample)
    var rightSamplePtr = cast[ptr int16](cast[int](leftSamplePtr) + bytesPersample)
    masterNode.setUnvisited()
    masterNode.update(dt)
    leftSamplePtr[] = int16(masterNode.output[0] * float(high(int16)))
    rightSamplePtr[] = int16(masterNode.output[1] * float(high(int16)))
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

  echo("frequency: ", obtained.freq)
  echo("format: ", obtained.format)
  echo("channels: ", obtained.channels)
  echo("samples: ", obtained.samples)
  echo("padding: ", obtained.padding)
  if obtained.format != AUDIO_S16:
    echo("Couldn't open 16-bit audio channel.")
    return
  if obtained.channels != 2:
    echo("Couldn't open stereo audio channels.")
    return

  let b = int16(masterNode.output[0] * float(high(int16)))
  let d = int16(masterNode.output[1] * float(high(int16)))
  pauseAudio(0)
