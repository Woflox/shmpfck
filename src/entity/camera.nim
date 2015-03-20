import ../util/util
import ../util/noise
import opengl
import entity
import math

type
  Camera = ref object
    target*: Entity
    lastTargetPos: Vector2
    offsetTargetPos: Vector2
    smoothedTargetPos: Vector2
    smoothPos: Vector2
    smoothTargetRotation: float
    smoothRotation: float
    shakeBoost: float
    zoom*: float
    t: float
    rotation: float
    position: Vector2

const
  smoothing = 0.25
  targetMoveSpeed = 20 + 20
  velocityOffsetCoefficient = 0.75
  polarOffset = 10
  rotationSpeed = 1.5
  rotationSmoothing = 0.25
  positionShake = 0.2
  rotationShake = 0.005
  noiseFrequency = 0.5
  noiseOctaves = 3
  speedShakeBoost = 0.375
  rotationSpeedShakeBoost = 8

var mainCamera*: Camera

proc newCamera* (pos: Vector2): Camera =
  result = Camera(position: pos, offsetTargetPos: pos, smoothedTargetPos: pos, lastTargetPos: pos)
  mainCamera = result

proc shake* (self: Camera, shakeAmount: float) =
  self.shakeBoost = max(self.shakeBoost, shakeAmount)

proc update* (self: Camera, dt: float) =
  if dt == 0:
    return

  self.t += dt

  #update position
  if self.target != nil:
    let targetMovement = self.target.position - self.lastTargetPos
    let velocityOffset = self.target.getVelocity() * velocityOffsetCoefficient
    self.offsetTargetPos = self.target.position + velocityOffset
    self.offsetTargetPos += self.offsetTargetPos.normalize() * polarOffset
    self.smoothedTargetPos += targetMovement
    let delta = (self.offsetTargetPos - self.smoothedTargetPos)
    let distance = delta.length
    let direction = delta.normalize
    if targetMoveSpeed * dt > distance:
      self.smoothedTargetPos = self.offsetTargetPos
    else:
      self.smoothedTargetPos += targetMoveSpeed * dt * direction
  let lastSmoothPos = self.smoothPos
  self.smoothPos = lerp(self.smoothPos, self.smoothedTargetPos, smoothing, dt)

  self.position = self.smoothPos

  let speed = ((self.smoothPos - lastSmoothPos) / dt).length
  let posShake = positionShake * (1 + speedShakeBoost * speed)

  self.position.x += fractalNoise(self.t * noiseFrequency, noiseOctaves) * posShake
  self.position.y += fractalNoise(1000 + self.t * noiseFrequency, noiseOctaves) * posShake

  #update rotation
  let targetRotation = angleFromMatrix(self.target.rotation)
  makeAnglesNear(targetRotation, self.smoothTargetRotation)

  if abs(targetRotation - self.smoothTargetRotation) < rotationSpeed * dt:
    self.smoothTargetRotation = targetRotation
  elif targetRotation > self.rotation:
    self.smoothTargetRotation += rotationSpeed * dt
  else:
    self.smoothTargetRotation -= rotationSpeed * dt

  makeAnglesNear(self.smoothTargetRotation, self.smoothRotation)
  let lastSmoothRotation = self.smoothRotation
  self.smoothRotation = lerp(self.smoothRotation, self.smoothTargetRotation, rotationSmoothing, dt)

  self.rotation = self.smoothRotation

  let rotationSpeed = abs((self.smoothRotation - lastSmoothRotation) / dt)
  let rotShake = rotationShake * (1 + rotationSpeedShakeBoost * rotationSpeed)

  self.rotation += fractalNoise(self.t * noiseFrequency, noiseOctaves) * rotShake

  if self.target != nil:
    self.lastTargetPos = self.target.position

proc applyTransform* (self: Camera) =
  glLoadIdentity()
  glRotated(radToDeg(-self.rotation), 0, 0, -1)
  glTranslated(-self.position.x, -self.position.y, 0)
