import ../util/util
import ../util/random
import entity
import ../geometry/shape
import ../audio/audio
import ../audio/explosion
import camera
import math

type
  FireType{.pure.} = enum
    automatic
    charge
  MovementType{.pure.} = enum
    straight
    slowed
    sine
  WeaponEffect = ref object of RootObj
  ProjectileSpawner = ref object of WeaponEffect
    directions: seq[Vector2]
    speed: float
    lifetime: float
    spawnEffect: WeaponEffect
    movementType: MovementType

  ShardSpawner = ref object of WeaponEffect
  BlastSpawner = ref object of WeaponEffect
    radius: float
    time: float


  Projectile = ref object of Entity
    t: float
    origin: Vector2
    lifetime: float
    intensity: float
    spawner: ProjectileSpawner
    fireVelocity: Vector2
    sourceVelocity: Vector2
    movementType: MovementType

  Blast = ref object of Entity
  Shard = ref object of Entity

  WeaponType* = ref object
    case fireType : FireType
    of FireType.automatic:
      fireRate : float
    of FireType.charge:
      chargeTime: float
    effect : WeaponEffect

  Weapon* = ref object
    weaponType : WeaponType
    timeSinceFire : float
    timeCharged : float
    firing : bool
    owner: Entity

method onCollision*(self: Projectile, other: Entity) =
  other.destroyed = true
  self.destroyed = true
  playSound(newExplosionNode(), -2, 0)

proc generateBlastSpawner(): BlastSpawner =
  result = BlastSpawner()

proc generateShardSpawner(): ShardSpawner =
  result = ShardSpawner()

proc generateProjectileSpawner(): ProjectileSpawner =
  result = ProjectileSpawner(directions: @[])
  result.speed = relativeRandom(50, 4)
  result.lifetime = relativeRandom((50 / result.speed) * 0.35, 3)
  result.movementType = randomEnumValue(MovementType)
  case result.movementType:
    of MovementType.straight: discard
    of MovementType.slowed:
      result.speed *= 2
    of MovementType.sine: discard
  let numExtraDirections = int(relativeRandom(0.5, 8))
  let angleChange = expRandom(Pi)
  var currentAngle = 0.0
  if numExtraDirections == 0 or randomChance(0.5):
    result.directions.add(vec2(0, 1))
  else:
    currentAngle -= angleChange / 2
  for i in 1..numExtraDirections:
    currentAngle += angleChange
    let direction = directionFromAngle(currentAngle)
    result.directions.add(direction)
    result.directions.add(vec2(-direction.x, direction.y))
  if randomChance(0.5):
    case random(1, 4):
      of 1:
        result.spawnEffect = generateProjectileSpawner()
      of 2:
        result.spawnEffect = generateProjectileSpawner()
      of 3:
        result.spawnEffect = generateProjectileSpawner()
      else: discard

proc generateWeaponType* (): WeaponType =
  result = WeaponType()
  result.fireType = randomEnumValue(FireType)
  case result.fireType:
    of FireType.automatic:
      result.fireRate = relativeRandom(4, 3)
    of FireType.charge:
      result.chargeTime = relativeRandom(0.6, 2)
  result.effect = generateProjectileSpawner()

proc generateWeapon* (weaponType: WeaponType, owner: Entity): Weapon =
  result = Weapon(weaponType: weaponType, owner: owner)
  result.timeSinceFire = 1.0 / weaponType.fireRate

method spawn(self: WeaponEffect, position: Vector2, rotation: Matrix2x2,
             velocity: Vector2, isPlayer: bool, intensity: float) = discard

method spawn(self: ProjectileSpawner, position: Vector2, rotation: Matrix2x2,
             velocity: Vector2, isPlayer: bool, intensity: float) =
  let renderShape = createShape(vertices = @[vec2(0,0),vec2(0,0)],
                                drawStyle = DrawStyle.line,
                                lineColor = color(1, 1, 0.5))
  let collisionShape = createShape(vertices = @[vec2(0,0)],
                                   collisionType = CollisionType.continuous,
                                   closed = false)
  for relativeDirection in self.directions:
    let projectile = Projectile(movement: Movement.normal,
                      drawable: true,
                      position: position,
                      origin: position,
                      collisionTag: CollisionTag.playerWeapon,
                      lifetime: self.lifetime * intensity,
                      spawner: self,
                      intensity: intensity,
                      movementType: self.movementType)
    if isPlayer:
      projectile.collisionTag = CollisionTag.playerWeapon
    else:
      projectile.collisionTag = CollisionTag.enemyWeapon
    projectile.fireVelocity = rotation * relativeDirection * self.speed * intensity
    projectile.velocity = projectile.fireVelocity + velocity
    projectile.sourceVelocity = velocity

    projectile.shapes = @[renderShape, collisionShape]
    projectile.init(matrixFromDirection(projectile.velocity.normalize))

    addEntity(projectile)

proc fire(self: Weapon, intensity: float = 1.0) =
  var rotation = self.owner.rotation
  if self.owner.collisionTag != CollisionTag.player:
    rotation = rotation * matrixFromAngle(Pi) #TODO: this shouldn't be necessary (fix enemy rotation)
  self.weaponType.effect.spawn(self.owner.position,
                               rotation,
                               self.owner.getVelocity(),
                               self.owner.collisionTag == CollisionTag.player,
                               intensity)

proc startFiring *(self: Weapon) =
  self.firing = true

proc stopFiring *(self: Weapon) =
  self.firing = false

proc isFiring *(self: Weapon): bool =
  return self.firing

proc update *(self: Weapon, dt: float) =
  case self.weaponType.fireType:
    of FireType.automatic:
      self.timeSinceFire += dt
      if self.firing and self.timeSinceFire > 1.0 / self.weaponType.fireRate:
        self.timeSinceFire = 0
        self.fire()

    of FireType.charge:
      if self.firing:
        self.timeCharged += dt
      elif self.timeCharged > 0.0:
        let intensity = min (1.0, self.timeCharged / self.weaponType.chargeTime)
        self.fire(intensity)
        self.timeCharged = 0.0

method update(self: Projectile, dt: float) =
  self.t += dt
  if self.t > self.lifetime:
    self.destroyed = true
    if self.spawner.spawnEffect != nil:
      let velocity = if self.movementType == MovementType.slowed:
        vec2(0, 0) else: self.sourceVelocity

      self.spawner.spawnEffect.spawn(self.position,
                             matrixFromDirection(self.fireVelocity.normalize),
                             velocity,
                             self.collisionTag == CollisionTag.playerWeapon,
                             self.intensity)
  else:
    case self.movementType:
      of MovementType.straight:
        discard
      of MovementType.slowed:
        self.velocity = (self.fireVelocity + self.sourceVelocity) *
                          (1 - (self.t / self.lifetime))
      of MovementType.sine:
        discard


  #update render shape
  let originDistance = ((self.position + self.velocity * dt) - self.origin).length
  var stretch = self.velocity.length / 60
  let stretchFraction = min(1, originDistance / stretch)
  stretch *= stretchFraction
  let cameraStretch = (self.rotation.transpose * mainCamera.velocity) *
                        stretchFraction/ 120
  self.shapes[0].relativeVertices[0] = (vec2(0, -stretch)) + cameraStretch
  self.shapes[0].relativeVertices[1] = -cameraStretch

  procCall Entity(self).update(dt)
