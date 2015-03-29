import ../util/util
import entity
import ../geometry/shape
import ../audio/audio
import ../audio/explosion

type
  FireType{.pure.} = enum
    automatic
    charge
  WeaponEffectType{.pure.} = enum
    projectile
    blast
    obstruction
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
  Blast = ref object of Entity
  Obstruction = ref object of Entity

  Weapon* = ref object
    fireType* : FireType
    effect* : WeaponEffect

const
  speed = 360.0
  lifetime = 0.5

method onCollision*(self: Projectile, other: Entity) =
  other.destroyed = true
  self.destroyed = true
  playSound(newExplosionNode(), -2, 0)

proc newProjectile*(position: Vector2, sourceVelocity: Vector2): Projectile =
  result = Projectile(movement: Movement.normal,
                      drawable: true,
                      position: position,
                      origin: position,
                      collisionTag: CollisionTag.playerWeapon)
  let fireDir = position.normalize()
  result.velocity = sourceVelocity + fireDir * speed
  let renderShape = newShape(vertices = @[vec2(0,0),vec2(0,0)],
                             drawStyle = DrawStyle.line,
                             lineColor = color(1, 1, 0.5))
  let collisionShape = newShape(vertices = @[vec2(0,0)],
                                collisionType = CollisionType.continuous)
  result.shapes = @[renderShape, collisionShape]
  result.init(matrixFromDirection(result.velocity.normalize))

method updateBehaviour(self: Projectile, dt: float) =
  self.t += dt
  if (self.t > lifetime):
    self.destroyed = true

  #update render shape
  let originDistance = ((self.position + self.velocity * dt) - self.origin).length
  let stretch = min(speed / 60, originDistance)
  self.shapes[0].relativeVertices[0] = vec2(0, -stretch)
