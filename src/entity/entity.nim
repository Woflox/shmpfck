import ../render/shape
import ../util/util
import opengl
import math

type
  Movement* {.pure.} = enum
    none, normal, polar
  Entity* = ref object of RootObj
    collidable*: bool
    movement*: Movement
    drawable*: bool
    shapes*: seq[Shape]
    position*: Vector2
    rotation*: float
    velocity*: Vector2
    minPolarY*: float

method updateBehaviour*(self: Entity, dt: float) =
  discard

var
  entities* : seq[Entity] = @[]

proc entitiesOfType[T](): seq[T] =
  result = @[]
  for entity in entities:
    if entity is T:
      result.add(entity)

proc entityOfType[T](): T =
  for entity in entities:
    if entity is T:
      return entity

proc updatePhysics (self: Entity, dt: float) =
  case self.movement:
    of Movement.normal:
      self.position += self.velocity * dt

    of Movement.polar:
      let dirFromCenter = normalize(self.position)
      self.position += self.velocity.y * dt * dirFromCenter
      var length =  self.position.length
      # circumference is 2 * Pi * length, but the 2pi cancels out because
      # deltaAngle is 2 * Pi * (velocity.y / circumference)
      if length < self.minPolarY:
        length = self.minPolary
        self.velocity.y = 0
      let deltaAngle = self.velocity.x * dt / length
      let newAngle = angleFromDirection(dirFromCenter) + deltaAngle
      let newDir = directionFromAngle(newAngle)
      self.rotation = newAngle
      self.position = newDir * length

    of Movement.none:
      discard

proc update*(self: Entity, dt: float) =
    self.updateBehaviour(dt)
    self.updatePhysics(dt)

proc getVelocity*(self:Entity): Vector2 =
  if self.movement == Movement.polar:
    let dirFromCenter = normalize(self.position)
    result = dirFromCenter * self.velocity.y +
             vec2(dirFromCenter.y, -dirFromCenter.x) * self.velocity.x
  else:
    result = self.velocity

proc render*(self: Entity) =
  if self.drawable:
    glPushMatrix()
    glTranslated(self.position.x, self.position.y, 0)
    if self.rotation != 0:
      glRotated(radToDeg(self.rotation), 0, 0, -1)
    for shape in self.shapes:
      shape.render()
    glPopMatrix()
