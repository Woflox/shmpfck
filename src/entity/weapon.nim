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

  projectile = ref object of Entity
  blast = ref object of Entity
  obstruction = ref object of Entity

  Weapon* = ref object
    fireType* : FireType
    effect* : WeaponEffect
