import ../render/shape
import ../util/util
import math

type
  Movement* {.pure.} = enum
    none, normal, polar
  CollisionTag* {.pure.} = enum
    none, playerWeapon, enemyWeapon, player, enemy
  Entity* = ref object of RootObj
    movement*: Movement
    drawable*: bool
    shapes*: seq[Shape]
    position*: Vector2
    rotation*: Matrix2x2
    velocity*: Vector2
    minPolarY*: float
    boundingBox*: BoundingBox
    destroyed*: bool
    collisionTag*: CollisionTag

const
  numTags = 4

proc transform*(self: Entity): Transform {.inline.} =
  Transform(position: self.position, rotation: self.rotation)

method updateBehaviour*(self: Entity, dt: float) =
  discard

var
  entities* : seq[Entity]
  entitiesByTag* : array[1..numTags, seq[Entity]]

proc clearEntities* =
  entities = @[]
  for i in low(entitiesByTag)..high(entitiesByTag):
    entitiesByTag[i] = @[]

proc addEntity*(entity: Entity) =
  entities.add(entity)
  if entity.collisionTag != CollisionTag.none:
    entitiesByTag[int(entity.collisionTag)].add(entity)

proc removeEntity*(index: int) =
  var entity = entities[index]
  entities.del(index)
  if entity.collisionTag != CollisionTag.none:
    entitiesByTag[int(entity.collisionTag)].del(
      find(entitiesByTag[int(entity.collisionTag)], entity))

proc collidable(self: Entity): bool =
  self.collisionTag != CollisionTag.none

proc entitiesOfType* [T](): seq[T] =
  result = @[]
  for entity in entities:
    if entity of T:
      result.add(T(entity))

proc entityOfType* [T](): T =
  for entity in entities:
    if entity of T:
      return T(entity)

proc updateShapeTransforms(self: Entity) =
  if self.collidable:
    self.boundingBox = minimalBoundingBox()
  for i in 0..self.shapes.len-1:
    self.shapes[i].setTransform(self.transform)
    if self.collidable:
      self.boundingBox.expandTo(self.shapes[i].boundingBox)



proc updatePhysics(self: Entity, dt: float) =
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

proc collides(tag1: CollisionTag, tag2: CollisionTag): bool =
  case tag1:
    of CollisionTag.playerWeapon:
      return tag2 == CollisionTag.enemy
    of CollisionTag.enemyWeapon:
      return tag2 == CollisionTag.player
    of CollisionTag.player:
      return tag2 == CollisionTag.enemy
    else:
      return false

method onCollision* (self: Entity, other: Entity) =
  discard

proc checkForCollisions* (self: Entity, index: int, dt: float) =
  for tag in low(entitiesByTag)..high(entitiesByTag):
    if collides(self.collisionTag, CollisionTag(tag)):
      for i in 0..high(entitiesByTag[tag]):
        var entity = entitiesByTag[tag][i]
        if self.boundingBox.overlaps(entity.boundingBox):
           #TODO: detailed shape collision
          self.onCollision(entity)
          entity.onCollision(self)

proc init* (self: Entity) =
  self.rotation = identity()
  self.updateShapeTransforms()

proc update* (self: Entity, dt: float) =
  self.updateBehaviour(dt)
  self.updatePhysics(dt)
  if (not self.collidable) and not (self.movement == Movement.none):
    self.updateShapeTransforms()

proc getVelocity* (self:Entity): Vector2 =
  if self.movement == Movement.polar:
    let dirFromCenter = normalize(self.position)
    result = dirFromCenter * self.velocity.y +
             vec2(dirFromCenter.y, -dirFromCenter.x) * self.velocity.x
  else:
    result = self.velocity

proc renderLine* (self: Entity) =
  for shape in self.shapes:
      shape.renderLine()

proc renderSolid* (self: Entity) =
  for shape in self.shapes:
      shape.renderSolid()
