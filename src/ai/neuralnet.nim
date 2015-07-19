import math
import ../util/random
import ../util/util

const
  numNeurons = 64
  numSynapsesPerNeuron = 4
  maxWeight = sqrt(8.0)
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
    timeSinceUpdate: float

proc newNeuralNet* (inputs: int): NeuralNet =
  result = NeuralNet(inputs: inputs)

proc randomize* (self: var NeuralNet) =
  for i in self.inputs..self.neurons.high:
    for synapse in self.neurons[i].synapses.mitems:
      synapse.neuronIndex = random(0, self.neurons.high)
      synapse.weight = random(-maxWeight, maxWeight)

proc activate(self: var Neuron) =
  self.intermediateValue *= abs(self.intermediateValue)
  self.intermediateValue = self.intermediateValue / (1 + abs(self.intermediateValue))
  self.value = lerp(self.intermediateValue, self.value, responseSmoothing)

proc simulate* (self: var NeuralNet, dt: float, inputs: varargs[float]) =
  self.timeSinceUpdate += dt
  var numUpdates = 0

  for i in 0..<self.inputs:
    self.neurons[i].value = inputs[i]

  while self.timeSinceUpdate > updateRate and numUpdates < maxUpdates:
    self.timeSinceUpdate -= updateRate
    inc numUpdates

    for i in self.inputs..self.neurons.high:
      self.neurons[i].intermediateValue = 0
      for synapse in self.neurons[i].synapses:
        self.neurons[i].intermediateValue += self.neurons[synapse.neuronIndex].value * synapse.weight
      self.neurons[i].activate()

proc getOutput* (self: NeuralNet, index): float =
  self.neurons[index + self.inputs].value
