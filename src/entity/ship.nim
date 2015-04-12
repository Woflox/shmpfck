import ../util/util
import weapon
import opengl
import entity
from ../input/input import nil

type
  Ship* = ref object of Entity
    moveDir* : Vector2
    moveSpeed* : float
    weapons* : seq[Weapon]
    currentWeapon* : Weapon
    firePoint* : Vector2

proc startWeaponAction* (self: Ship, index: int) =
  self.currentWeapon = self.weapons[index]

proc stopWeaponAction* (self: Ship, index: int) =
  discard

method update* (self: Ship, dt: float) =
  self.velocity = self.moveDir * self.moveSpeed
  procCall Entity(self).update(dt)
