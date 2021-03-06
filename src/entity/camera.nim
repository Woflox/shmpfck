import ../util/util
import ../util/noise
import ../globals/globals
import opengl
import entity
import math

type
  Camera = ref object
    target*: Entity
    lastTargetPos: Vector2
    smoothedTargetPos: Vector2
    smoothPos: Vector2
    smoothTargetRotation: float
    smoothRotation: float
    shakeBoost: float
    zoom*: float
    zoomInThreshold*: float
    zoomOutThreshold*: float
    t: float
    rotation: float
    rotationMatrix: Matrix2x2
    position: Vector2
    velocity*: Vector2
    bounds: BoundingBox
    postZoomThreshold: float
    blur: float

const
  smoothing = 0.25
  targetMoveSpeed = playerMoveSpeed * 2.5
  velocityOffsetCoefficient = 0.75
  rotationSpeed = 1.5
  rotationSmoothing = 0.25
  positionShake = 0.2
  rotationShake = 0.005
  noiseFrequency = 0.5
  noiseOctaves = 3
  speedShakeBoost = 0.25
  rotationSpeedShakeBoost = 6
  zoomSpeed = 0.55
  zoomHysteresis = 1.25
  zoomPadding = 3
  minBoundsMinY = -10.5
  minBoundsMaxY = 22.5
  maxBoundsMinY = -19.5
  maxBoundsMaxY = 24.5
  blurRate = 0.012
  unblurRate = 0.024
  maxBlur = 0.01

var mainCamera*: Camera

proc newCamera* (pos: Vector2): Camera =
  result = Camera(position: pos, smoothedTargetPos: pos, lastTargetPos: pos, zoom: minBoundsMaxY - minBoundsMinY)
  mainCamera = result

proc shake* (self: Camera, shakeAmount: float) =
  self.shakeBoost = max(self.shakeBoost, shakeAmount)

proc update* (self: Camera, dt: float) =
  if dt == 0 or self.target == nil:
    return

  self.t += dt
  let lastPos = self.position

  #update position
  let targetMovement = self.target.position - self.lastTargetPos
  let velocityOffset = self.target.getVelocity() * velocityOffsetCoefficient

  #expand bounds to include enemies
  let inverseTargetRotation = self.target.rotation.transpose

  let minWidth = (minBoundsMaxY - minBoundsMinY) * screenAspectRatio
  let maxWidth = (maxBoundsMaxY - maxBoundsMinY) * screenAspectRatio
  var targetBox = boundingBox(vec2(-minWidth / 2 + zoomPadding, minBoundsMinY + zoomPadding),
                              vec2(minWidth / 2 - zoomPadding, minBoundsMaxY - zoomPadding))
  let maxBounds = boundingBox(vec2(-maxWidth / 2 + zoomPadding, maxBoundsMinY + zoomPadding),
                              vec2(maxWidth / 2 - zoomPadding, maxBoundsMaxY - zoomPadding))

  for enemy in entitiesByTag[int(CollisionTag.enemy)]:
    let transformedPos = inverseTargetRotation * (enemy.position - self.target.position)
    if maxBounds.contains(transformedPos):
      targetBox.expandTo(transformedPos)

  targetBox.minPos -= vec2(zoomPadding, zoomPadding)
  targetBox.maxPos += vec2(zoomPadding, zoomPadding)

  let offsetTargetPos = self.target.position + self.target.rotation * targetBox.center + velocityOffset
  self.smoothedTargetPos += targetMovement
  let delta = (offsetTargetPos - self.smoothedTargetPos)
  let distance = delta.length
  let direction = delta.normalize
  if targetMoveSpeed * dt > distance:
    self.smoothedTargetPos = offsetTargetPos
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

  let desiredZoom = max(targetBox.size.y, targetBox.size.x / screenAspectRatio)
  let zoomAmount = self.zoom * zoomSpeed * dt
  var zooming = false
  if desiredZoom > self.zoom:
    if desiredZoom > self.zoomOutThreshold:
      if desiredZoom - self.zoom < zoomAmount:
        self.zoom = desiredZoom
      else:
        zooming = true
        self.zoom += zoomAmount
        self.blur = min(maxBlur, self.blur + blurRate * dt)
      self.zoomInThreshold = self.zoom / zoomHysteresis
  else:
    if desiredZoom < self.zoomInThreshold:
      if self.zoom - desiredZoom < zoomAmount:
        self.zoom = desiredZoom
      else:
        zooming = true
        self.zoom -= zoomAmount
        self.blur = max(-maxBlur, self.blur - blurRate * dt)
      self.zoomOutThreshold = self.zoom * zoomHysteresis

  if not zooming:
    if self.blur > 0:
      self.blur = max(0, self.blur - unblurRate * dt)
    else:
      self.blur = min(0, self.blur + unblurRate * dt)

  if self.target != nil:
    self.lastTargetPos = self.target.position

  self.velocity = (self.position - lastPos) / dt
  self.bounds = boundingBox(vec2(-screenAspectRatio / 2, -0.5) * self.zoom,
                            vec2(screenAspectRatio / 2, 0.5) * self.zoom)
  self.rotationMatrix = matrixFromAngle(-self.rotation)

proc getBounds* (self: Camera): BoundingBox {.inline.} = self.bounds

proc applyTransform* (self: Camera) =
  var scale = 2 / self.zoom
  if self.zoom < self.postZoomThreshold:
    scale = 2 / self.postZoomThreshold
  glScaled(scale, scale, 1)
  glRotated(radToDeg(-self.rotation), 0, 0, -1)
  glTranslated(-self.position.x, -self.position.y, 0)

proc worldToViewSpace* (self: Camera, point: Vector2): Vector2 =
  self.rotationMatrix * (point - self.position)

proc isOnScreen* (self: Camera, point: Vector2): bool =
  self.bounds.contains(self.worldToViewSpace(point))

proc isOnScreen* (self: Camera, box: BoundingBox): bool =
  var screenSpaceBox = minimalBoundingBox()
  screenSpaceBox.expandTo(self.worldToViewSpace(box.minPos))
  screenSpaceBox.expandTo(self.worldToViewSpace(box.maxPos))
  screenSpaceBox.expandTo(self.worldToViewSpace(vec2(box.minPos.x, box.maxPos.y)))
  screenSpaceBox.expandTo(self.worldToViewSpace(vec2(box.maxPos.x, box.minPos.y)))
  result = self.bounds.overlaps(screenSpaceBox)

proc getPostZoom* (self: Camera): float =
  if self.zoom > self.postZoomThreshold:
    return 1
  else:
    return self.zoom / self.postZoomThreshold

proc setPostZoomThreshold* (self: Camera, value: float) =
  if value > 1:
    self.postZoomThreshold = maxBoundsMaxY - maxBoundsMinY
  else:
    self.postZoomThreshold = (maxBoundsMaxY - maxBoundsMinY) * value

proc getBlur* (self: Camera): float =
  abs(self.blur) / (self.zoom / (maxBoundsMaxY - maxBoundsMinY))
