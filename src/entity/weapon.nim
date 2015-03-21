import ../util/util
import entity
import ../render/shape
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
  Blast = ref object of Entity
  Obstruction = ref object of Entity

  Weapon* = ref object
    fireType* : FireType
    effect* : WeaponEffect

const
  speed = 60.0
  lifetime = 0.5

method onCollision*(self: Projectile, other: Entity) =
  other.destroyed = true
  self.destroyed = true
  playSound(newExplosionNode(), -2, 0)

proc newProjectile*(position: Vector2, sourceVelocity: Vector2): Projectile =
  result = Projectile(movement: Movement.normal,
                      drawable: true,
                      position: position,
                      collisionTag: CollisionTag.playerWeapon)
  let fireDir = position.normalize()
  result.velocity = sourceVelocity + fireDir * speed
  let shape = createIsoTriangle(width = 0, height = result.velocity.length / 60, drawStyle = DrawStyle.line,
                                lineColor = color(1, 1, 0.5))
  result.shapes = @[shape]
  result.init(matrixFromDirection(result.velocity.normalize))

method updateBehaviour(self: Projectile, dt: float) =
  self.t += dt
  if (self.t > lifetime):
    self.destroyed = true
