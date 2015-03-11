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
  WeaponEffect = ref object
    effectType: WeaponEffectType
    directions: seq[Vector2]
    speed: float
  projectile = ref object of Entity
  blast = ref object of Entity
  obstruction = ref object of Entity

  Weapon* = ref object
    fireType* : FireType
    fireDirections* : seq[Vector2]
