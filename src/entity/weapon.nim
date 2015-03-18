import ../util/util
import entity
import ../render/shape

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
  Blast = ref object of Entity
  Obstruction = ref object of Entity

  Weapon* = ref object
    fireType* : FireType
    effect* : WeaponEffect

const
  speed = 60.0

proc newProjectile*(position: Vector2): Projectile =
  result = Projectile(collidable: true,
                      movement: Movement.polar,
                      drawable: true,
                      position: position,
                      minPolarY: 10)
  let shape = createIsoTriangle(width = 0, height = speed / 60, drawStyle = DrawStyle.line,
                                lineColor = col(1, 1, 0.5))
  result.shapes = @[shape]
  result.init()

method updateBehaviour(self: Projectile, dt: float) =
  self.velocity = vec2(0, speed)
