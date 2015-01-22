import ../render/shape
import ../util/util
import opengl

type
  Entity* = ref object
    collidable*: bool
    dynamic*: bool
    drawable*: bool
    shapes*: seq[Shape]
    position*: Vector2
    rotation: Matrix2x2
    velocity: Vector2
    acceleration: Vector2

method updateBehaviour*(self: Entity, dt: float) =
  discard

proc updatePhysics (self: Entity, dt: float) =
  if self.dynamic:
    self.velocity = self.velocity + self.acceleration * dt
    self.position += self.velocity * dt

proc update*(self: Entity, dt: float) =
    self.updateBehaviour(dt)
    if self.collidable or self.dynamic:
      self.updatePhysics(dt)


proc render*(self: Entity) =
  if self.drawable:
    glLoadIdentity()
    glTranslated(self.position.x, self.position.y, 0)
    for shape in self.shapes:
      shape.render()
