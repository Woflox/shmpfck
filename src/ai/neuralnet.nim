import math
import ../util/random

type
  Neuron = ref object
    value: float
    synapses: seq[Synapse]
  Synapse = ref object
    weight: float
    child: Neuron
  NeuralNet* = ref object
    layers: seq[seq[Neuron]]

proc newNeuralNet* (inputs: int, outputs: int,
                  hiddenLayers: int, hiddenLayerSize: int): NeuralNet =
  #initialize sequence
  result = NeuralNet(layers: @[])
  result.layers.add(newSeq[Neuron](inputs))
  for i in 1..hiddenLayers:
    result.layers.add(newSeq[Neuron](hiddenLayerSize))
  result.layers.add(newSeq[Neuron](outputs))

  for i in 0..high(result.layers):
    for j in 0..high(result.layers[i]):
      result.layers[i][j] = Neuron(synapses: @[])

  #create synapse structure
  for i in 0..hiddenLayers:
    for neuron in result.layers[i]:
      for childNeuron in result.layers[i+1]:
        neuron.synapses.add(Synapse(child: childNeuron))

proc randomize* (self: NeuralNet) =
  for layer in self.layers:
    for neuron in layer:
      for synapse in neuron.synapses:
        synapse.weight = random(-1.0, 1.0)

proc sigmoid(t: float): float =
  2 / (1 + exp(-t)) - 1

proc simulate* (self: NeuralNet, inputs: varargs[float]) =
  for i in 0..inputs.len-1:
    self.layers[0][i].value = inputs[i]

  for i in 1..high(self.layers):
    for neuron in self.layers[i]:
      neuron.value = 0

  for i in 0..high(self.layers)-1:
    for neuron in self.layers[i]:
      for synapse in neuron.synapses:
        synapse.child.value += neuron.value * synapse.weight
    for neuron in self.layers[i+1]:
      neuron.value = sigmoid(neuron.value)

proc output* (self: NeuralNet, index): float =
  self.layers[self.layers.len-1][index].value
