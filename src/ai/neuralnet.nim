import math
import ../util/random

type
  Neuron = ref object
    value: float
    weights: seq[float]
  NeuralNet* = ref object
    layers: seq[seq[Neuron]]

const activationThreshold = 0.1

proc newNeuralNet* (inputs: int, outputs: int,
                  hiddenLayers: int, hiddenLayerSize: int): NeuralNet =
  #initialize sequence
  result = NeuralNet()
  result.layers = newSeq[seq[Neuron]](hiddenLayers + 2)
  result.layers[0] = (newSeq[Neuron](inputs))
  for i in 1..hiddenLayers:
    result.layers[i] = (newSeq[Neuron](hiddenLayerSize))
  result.layers[hiddenLayers + 1] = (newSeq[Neuron](outputs))

  for j in 0..high(result.layers[0]):
    result.layers[0][j] = Neuron()
  for i in 1..high(result.layers):
    for j in 0..high(result.layers[i]):
      result.layers[i][j] = Neuron(weights: newSeq[float](result.layers[i-1].len))

proc randomize* (self: NeuralNet) =
  for i in 1..high(self.layers):
    for neuron in self.layers[i]:
      for j in 0..high(neuron.weights):
        neuron.weights[j] = random(-1.0, 1.0)

proc activate(t: float): float =
  result = t / (1 + abs(t))
  if abs(result) < activationThreshold:
    result = 0

proc simulate* (self: NeuralNet, inputs: varargs[float]) =
  for i in 0..inputs.len-1:
    self.layers[0][i].value = inputs[i]

  for i in 1..high(self.layers):
    let previousLayer = self.layers[i-1]
    for neuron in self.layers[i]:
      neuron.value = 0
      var index = 0
      for j in 0..high(previousLayer):
        neuron.value += previousLayer[j].value * neuron.weights[index]
      neuron.value = activate(neuron.value)

proc getOutput* (self: NeuralNet, index): float =
  self.layers[self.layers.len-1][index].value

iterator outputs* (self: NeuralNet): float =
  for neuron in self.layers[high(self.layers)]:
    yield neuron.value
