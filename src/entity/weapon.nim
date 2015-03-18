import ../util/util
import entity

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

proc newProjectile(pos: Vector2): Projectile =
  Projectile(position: pos)
