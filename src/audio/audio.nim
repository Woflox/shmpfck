import sdl2
import sdl2/audio
import math

# Audio settings requested:
const bufferSizeInSamples = 1024
const bytesPerSample = 2  # 16 bit PCM
const bufferSizeInBytes = bufferSizeInSamples * bytesPerSample

var sampleRate = 44100    # Hz
var obtained: AudioSpec # Actual audio parameters SDL returns

type
  AudioSample* = array[0..1, float]
  MixerTrack* = tuple
    volume, pan: float
  AudioNode* = ref object of RootObj
    inputs*: seq[AudioNode]
    output*: AudioSample
    visited: bool
    stopped: bool
  MixerNode* = ref object of AudioNode
    tracks*: seq[MixerTrack]
  LimiterNode* = ref object of AudioNode
    threshold, release: float
  CompressorNode* = ref object of AudioNode
    threshold, release, attack, ratio: float

proc newMixerNode(): MixerNode =
  result = MixerNode(tracks: @[], inputs: @[])

var masterNode = newMixerNode()

proc amplitudeToDb*(amplitude: float): float =
  log10(amplitude) * 10

proc dbToAmplitude*(db: float): float =
  pow(10, db / 10)

method updateOutputs*(self: AudioNode, dt: float) =
  discard

method updateOutputs*(self: MixerNode, dt: float) =
  self.output = [0.0, 0.0]
  for i in 0..high(self.tracks):
    let volume = self.tracks[i].volume
    let pan = self.tracks[i].pan
    self.output[0] += self.inputs[i].output[0] * volume * sqrt((-pan + 1) / 2)
    self.output[1] += self.inputs[i].output[1] * volume * sqrt((pan + 1) / 2)

proc stop(self: AudioNode) =
  self.stopped = true

proc reset(self: AudioNode) {.gcsafe.} =
  discard
 # for input in self.inputs:
  #  input.reset()

proc update(self: AudioNode, dt: float) =
  self.visited = false
  for input in self.inputs:
    if not input.visited:
      input.update(dt)
  self.updateOutputs(dt)

proc playSound(node: AudioNode, volume, pan: float) =
  #TODO: add ducking priority param to choose parent node; side chain compression
  masterNode.inputs.add(node)
  masterNode.tracks.add((dbToAmplitude(volume), pan))

var t = 0.0
# Write amplitude direct to hardware buffer
proc audioCallback(userdata: pointer; stream: ptr uint8; len: cint) {.cdecl.} =
  let dt = 1.0 / float(sampleRate)
  var i = 0
  #var testNode = newMixerNode()
  while i < int16(obtained.samples)*2-1:
    t += dt
    var leftSamplePtr = cast[ptr int16](cast[int](stream) + i * bytesPerSample)
    var rightSamplePtr = cast[ptr int16](cast[int](leftSamplePtr) + bytesPersample)
    #masterNode.reset()
    #masterNode.update(dt)
    leftSamplePtr[] = int16(((t * 40) mod 1) * float(high(int16)))
    rightSamplePtr[] = int16(((t * 40) mod 1) * float(high(int16)))
    #leftSamplePtr[] = int16(masterNode.output[0] * float(high(int16)))
    #rightSamplePtr[] = int16(masterNode.output[1] * float(high(int16)))
    i += 2

proc init* =
  var audioSpec: AudioSpec
  audioSpec.freq = cint(sampleRate)
  audioSpec.format = AUDIO_S16 # 16 bit PCM
  audioSpec.channels = 2       # stereo
  audioSpec.samples = bufferSizeInSamples
  audioSpec.padding = 0
  audioSpec.callback = audioCallback
  audioSpec.userdata = nil
  if OpenAudio(addr(audioSpec), addr(obtained)) != 0:
    echo("Couldn't open audio device. " & $GetError() & "\n")
    return

  echo("frequency: ", obtained.freq)
  echo("format: ", obtained.format)
  echo("channels: ", obtained.channels)
  echo("samples: ", obtained.samples)
  echo("padding: ", obtained.padding)
  sampleRate = obtained.freq
  if obtained.format != AUDIO_S16:
    echo("Couldn't open 16-bit audio channel.")
    return
  if obtained.channels != 2:
    echo("Couldn't open stereo audio channels.")
    return

  let b = int16(masterNode.output[0] * float(high(int16)))
  let d = int16(masterNode.output[1] * float(high(int16)))
  PauseAudio(0)
