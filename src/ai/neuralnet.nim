import math
import ../util/random
import ../util/util

const
  numNeurons = 64
  numSynapsesPerNeuron = 8
  updateRate = 1 / 120.0
  maxUpdates = 8
  responseSmoothing = 0.75

type
  Neuron* = object
    value: float
    intermediateValue: float
    synapses: array[numSynapsesPerNeuron, Synapse]
  Synapse = object
    neuronIndex: int
    weight: float
  NeuralNet* = object
    neurons: array[numNeurons, Neuron]
    inputs: int
    outputs: int
    timeSinceUpdate: float

proc newNeuralNet* (inputs: int, outputs: int): NeuralNet =
  result = NeuralNet(inputs: inputs, outputs: outputs)

proc randomize* (self: var NeuralNet) =
  for i in self.inputs..high(self.neurons):
    for j in 0..high(self.neurons[i].synapses):
      self.neurons[i].synapses[j].neuronIndex = random(0, high(self.neurons))
      self.neurons[i].synapses[j].weight = random(-1.0, 1.0)

proc activate(self: var Neuron) =
  self.intermediateValue *= abs(self.intermediateValue) * 2
  self.intermediateValue = self.intermediateValue / (1 + abs(self.intermediateValue))
  self.value = lerp(self.intermediateValue, self.value, responseSmoothing)

proc simulate* (self: var NeuralNet, dt: float, inputs: varargs[float]) =
  self.timeSinceUpdate += dt
  var numUpdates = 0

  for i in 0..self.inputs-1:
    self.neurons[i].value = inputs[i]

  while self.timeSinceUpdate > updateRate and numUpdates < maxUpdates:
    self.timeSinceUpdate -= updateRate
    inc numUpdates

    for i in self.inputs..high(self.neurons):
      self.neurons[i].intermediateValue = 0
      for j in 0..high(self.neurons[i].synapses):
        self.neurons[i].intermediateValue += self.neurons[self.neurons[i].synapses[j].neuronIndex].value *
                                 self.neurons[i].synapses[j].weight
      self.neurons[i].activate()

proc getOutput* (self: NeuralNet, index): float =
  self.neurons[index + self.neurons.len - self.outputs].value

iterator outputs* (self: NeuralNet): float =
  for i in self.neurons.len - self.outputs .. high(self.neurons):
    yield self.neurons[i].value
