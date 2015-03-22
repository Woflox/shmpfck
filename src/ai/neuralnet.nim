import math
import ../util/random

type
  Neuron = ref object
    value: float
    synapses: seq[Synapse]
  Synapse = object
    neuron: Neuron
    weight: float
  NeuralNet* = ref object
    neurons: seq[Neuron]
    inputs: int
    outputs: int
    timeSinceUpdate: float
    activationThreshold: float

const
  updateRate = 1.0 / 60.0

proc newNeuralNet* (inputs: int, outputs: int, hiddenNeurons: int, activationThreshold: float): NeuralNet =
  #initialize sequence
  result = NeuralNet(inputs: inputs, outputs: outputs, activationThreshold: activationThreshold)
  result.neurons = newSeq[Neuron](inputs+outputs+hiddenNeurons)

  for i in 0..high(result.neurons):
    result.neurons[i] = Neuron()

proc randomize* (self: NeuralNet, connectionsPerNeuron: int) =
  for i in self.inputs..high(self.neurons):
    let neuron = self.neurons[i]
    self.neurons[i].synapses = newSeq[Synapse](connectionsPerNeuron)
    for j in 0..high(neuron.synapses):
      neuron.synapses[j].neuron = self.neurons.randomChoice
      neuron.synapses[j].weight = random(-1.0, 1.0)
  self.timeSinceUpdate = random(0, updateRate)

proc activate(t: float, threshold: float): float =
  result = t / (1 + abs(t))
  if abs(result) < threshold:
    result = 0

proc simulate* (self: NeuralNet, dt: float, inputs: varargs[float]) =
  self.timeSinceUpdate += dt
  while self.timeSinceUpdate >= updateRate:
    self.timeSinceUpdate -= updateRate

    for i in 0..self.inputs-1:
      self.neurons[i].value = inputs[i]

    for i in self.inputs..high(self.neurons):
      let neuron = self.neurons[i]
      neuron.value = 0
      for synapse in neuron.synapses:
        neuron.value += synapse.neuron.value * synapse.weight
      neuron.value = activate(neuron.value, self.activationThreshold)

proc getOutput* (self: NeuralNet, index): float =
  self.neurons[index + self.neurons.len - self.outputs].value

iterator outputs* (self: NeuralNet): float =
  for i in self.neurons.len - self.outputs .. high(self.neurons):
    yield self.neurons[i].value
