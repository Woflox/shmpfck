import ../util/util
import ../util/noise
import opengl
import entity
import math

var
  target*: Entity
  lastTargetPos: Vector2
  offsetTargetPos: Vector2
  smoothedTargetPos: Vector2
  smoothPos: Vector2
  position: Vector2
  smoothTargetRotation: float
  smoothRotation: float
  rotation: float
  shakeBoost: float
  zoom*: float
  t: float

const
  smoothing = 0.25
  targetMoveSpeed = 20 + 20
  velocityOffsetCoefficient = 0.75
  polarOffset = 10
  rotationSpeed = 1.5
  rotationSmoothing = 0.25
  positionShake = 0.2
  rotationShake = 0.005
  noiseFrequency = 2
  noiseOctaves = 3
  speedShakeBoost = 0.375
  rotationSpeedShakeBoost = 8

proc init* (pos: Vector2) =
  position = pos
  offsetTargetPos = pos
  smoothedTargetPos = pos
  lastTargetPos = pos

proc shake* (shakeAmount: float) =
  shakeBoost = max(shakeBoost, shakeAmount)

proc update* (dt: float) =
  if dt == 0:
    return

  t += dt

  #update position
  if target != nil:
    let targetMovement = target.position -  lastTargetPos
    let velocityOffset = target.getVelocity() * velocityOffsetCoefficient
    offsetTargetPos = target.position + velocityOffset
    offsetTargetPos += offsetTargetPos.normalize() * polarOffset
    smoothedTargetPos += targetMovement
    let delta = (offsetTargetPos - smoothedTargetPos)
    let distance = delta.length
    let direction = delta.normalize
    if targetMoveSpeed * dt > distance:
      smoothedTargetPos = offsetTargetPos
    else:
      smoothedTargetPos += targetMoveSpeed * dt * direction
  let lastSmoothPos = smoothPos
  smoothPos = lerp(smoothPos, smoothedTargetPos, smoothing, dt)

  position = smoothPos

  let speed = ((smoothPos - lastSmoothPos) / dt).length
  let posShake = positionShake * (1 + speedShakeBoost * speed)

  position.x += fractalNoise(t / noiseFrequency, noiseOctaves) * positionShake
  position.y += fractalNoise(1000 + t / noiseFrequency, noiseOctaves) * posShake

  #update rotation
  let targetRotation = angleFromMatrix(target.rotation)
  makeAnglesNear(targetRotation, smoothTargetRotation)

  if abs(targetRotation - smoothTargetRotation) < rotationSpeed * dt:
    smoothTargetRotation = targetRotation
  elif targetRotation > rotation:
    smoothTargetRotation += rotationSpeed * dt
  else:
    smoothTargetRotation -= rotationSpeed * dt

  makeAnglesNear(smoothTargetRotation, smoothRotation)
  let lastSmoothRotation = smoothRotation
  smoothRotation = lerp(smoothRotation, smoothTargetRotation, rotationSmoothing, dt)

  rotation = smoothRotation

  let rotationSpeed = abs((smoothRotation - lastSmoothRotation) / dt)
  let rotShake = rotationShake * (1 + rotationSpeedShakeBoost * rotationSpeed)

  rotation += fractalNoise(t / noiseFrequency, noiseOctaves) * rotShake

  if target != nil:
    lastTargetPos = target.position

proc applyTransform* () =
  glLoadIdentity()
  glRotated(radToDeg(-rotation), 0, 0, -1)
  glTranslated(-position.x, -position.y, 0)
