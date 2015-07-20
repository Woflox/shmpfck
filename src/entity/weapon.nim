import ../util/util
import entity
import ../geometry/shape
import ../audio/audio
import ../audio/explosion
import camera

type
  FireType{.pure.} = enum
    automatic
    charge
  WeaponEffectType{.pure.} = enum
    projectile
    blast
    shard
  WeaponDeathType{.pure.} = enum
    timed
    probability
  WeaponSpawnType{.pure.} = enum
    none
    death
    probability
  WeaponEffect = ref object
    effectType: WeaponEffectType
    directions: seq[Vector2]
    speed: float
    spawnEffect: WeaponEffect

  Projectile = ref object of Entity
    t: float
    origin: Vector2
    lifetime: float
  Blast = ref object of Entity
  Obstruction = ref object of Entity

  Weapon* = ref object
    fireType* : FireType
    effect* : WeaponEffect

const
  speed = 60.0
  lifetime = 0.35
  enemySpeed = 25.0
  enemyLifetime = 0.75

method onCollision*(self: Projectile, other: Entity) =
  other.destroyed = true
  self.destroyed = true
  playSound(newExplosionNode(), -2, 0)

proc newProjectile*(position: Vector2, sourceVelocity: Vector2): Projectile =
  result = Projectile(movement: Movement.normal,
                      drawable: true,
                      position: position,
                      origin: position,
                      collisionTag: CollisionTag.playerWeapon,
                      lifetime: lifetime)
  let fireDir = position.normalize()
  result.velocity = sourceVelocity + fireDir * speed
  let renderShape = createShape(vertices = @[vec2(0,0),vec2(0,0)],
                             drawStyle = DrawStyle.line,
                             lineColor = color(1, 1, 0.5),
                             closed = false)
  let collisionShape = createShape(vertices = @[vec2(0,0)],
                                collisionType = CollisionType.continuous,
                                closed = false)
  result.shapes = @[renderShape, collisionShape]
  result.init(matrixFromDirection(result.velocity.normalize))

proc newEnemyProjectile*(position: Vector2, sourceVelocity: Vector2): Projectile =
  result = Projectile(movement: Movement.normal,
                      drawable: true,
                      position: position,
                      origin: position,
                      collisionTag: CollisionTag.enemyWeapon,
                      lifetime: enemyLifetime)
  let fireDir = position.normalize() * (-1)
  result.velocity = sourceVelocity + fireDir * enemySpeed
  let renderShape = createShape(vertices = @[vec2(0,0),vec2(0,0)],
                             drawStyle = DrawStyle.line,
                             lineColor = color(1, 1, 0.5))
  let collisionShape = createShape(vertices = @[vec2(0,0)],
                                collisionType = CollisionType.continuous,
                                closed = false)
  result.shapes = @[renderShape, collisionShape]
  result.init(matrixFromDirection(result.velocity.normalize))


method update(self: Projectile, dt: float) =
  self.t += dt
  if (self.t > self.lifetime):
    self.destroyed = true

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
