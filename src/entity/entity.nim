import ../render/shape
import ../util/util
import opengl
import math

type
  Physics* {.pure.} = enum
    none, full, velocity, polar
  Entity* = ref object of RootObj
    collidable*: bool
    physics*: Physics
    drawable*: bool
    shapes*: seq[Shape]
    position*: Vector2
    rotation*: Matrix2x2
    velocity*: Vector2
    acceleration*: Vector2

method updateBehaviour*(self: Entity, dt: float) =
  discard

proc updatePhysics (self: Entity, dt: float) =
  case self.physics
    of Physics.full:
      self.velocity = self.velocity + self.acceleration * dt
      self.position += self.velocity * dt

    of Physics.velocity:
      self.position += self.velocity * dt

    of Physics.polar:
      let dirFromCenter = normalize(self.position)
      self.position += self.velocity.y * dt * dirFromCenter
      let length =  self.position.length
      # circumference is 2 * Pi * length, but the 2pi cancels out because
      # deltaAngle is 2 * Pi * (velocity.y / circumference)
      if length != 0:
        let deltaAngle = self.velocity.x * dt / length
        let newAngle = angleFromDirection(dirFromCenter) + deltaAngle
        let newDir = directionFromAngle(newAngle)
        self.rotation = matrixFromDirection(newDir)
        self.position = newDir * length

    of Physics.none:
      discard

proc update*(self: Entity, dt: float) =
    self.updateBehaviour(dt)
    if self.collidable or self.physics != Physics.none:
      self.updatePhysics(dt)


proc render*(self: Entity) =
  if self.drawable:
    glLoadIdentity()
    glTranslated(self.position.x, self.position.y, 0)
    for shape in self.shapes:
      shape.render()
