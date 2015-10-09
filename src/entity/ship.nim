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

proc setWeaponFiring* (self: Ship, index: int, fire: bool) =
  if fire:
    if (self.currentWeapon == nil) or (not self.currentWeapon.isFiring):
      self.currentWeapon = self.weapons[index]
      self.currentWeapon.startFiring()
  else:
    self.weapons[index].stopFiring()


method updatePostPhysics* (self: Ship, dt: float) =
  self.velocity = self.moveDir * self.moveSpeed
  for weapon in self.weapons:
    weapon.update(dt)
  procCall Entity(self).updatePostPhysics(dt)
