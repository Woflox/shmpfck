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
    rotation*: Matrix2x2
    velocity*: Vector2
    minPolarY*: float
    test:bool

proc transform(self: Entity): Transform =
  Transform(position: self.position, rotation: self.rotation)

method updateBehaviour*(self: Entity, dt: float) =
  discard

var
  entities* : seq[Entity] = @[]

proc entitiesOfType* [T](): seq[T] =
  result = @[]
  for entity in entities:
    if entity is T:
      result.add(entity)

proc entityOfType* [T](): T =
  for entity in entities:
    if entity is T:
      return entity

proc updateShapeTransforms(self: Entity) =
  for i in 0..self.shapes.len-1:
    self.shapes[i].setTransform(self.transform)

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
      self.rotation = matrixFromDirection(dirFromCenter) * matrixFromAngle(deltaAngle)
      self.position = directionFromMatrix(self.rotation) * length

    of Movement.none:
      discard

  if self.collidable and not (self.movement == Movement.none):
    self.updateShapeTransforms()

proc init*(self: Entity) =
  self.rotation = identity()
  self.updateShapeTransforms()

proc update*(self: Entity, dt: float) =
  self.updateBehaviour(dt)
  self.updatePhysics(dt)
  if (not self.collidable) and not (self.movement == Movement.none):
    self.updateShapeTransforms()

proc getVelocity*(self:Entity): Vector2 =
  if self.movement == Movement.polar:
    let dirFromCenter = normalize(self.position)
    result = dirFromCenter * self.velocity.y +
             vec2(dirFromCenter.y, -dirFromCenter.x) * self.velocity.x
  else:
    result = self.velocity

proc renderLine*(self: Entity) =
  for shape in self.shapes:
      shape.renderLine()

proc renderSolid*(self: Entity) =
  for shape in self.shapes:
      shape.renderSolid()
