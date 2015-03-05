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

proc startFiring* (self: Ship, index: int) =
  self.currentWeapon = self.weapons[index]

proc stopFiring* (self: Ship, index: int) =
  discard

method updateBehaviour* (self: Ship, dt: float) =
  self.velocity = self.moveDir * self.moveSpeed
