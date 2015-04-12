import ../util/util
import ../geometry/shape

type
  HAlign* {.pure.} = enum
    left, right, center, fill, contain
  VAlign* {.pure.} = enum
    top, bottom, center, fill, contain
  UIObject* = ref object of RootObj
    position*: Vector2
    size*: Vector2
    hAlign*: HAlign
    vAlign*: VAlign
    innerElements*: seq[UIObject]
    shapes*: seq[Shape]
    bounds*: BoundingBox


method update*(self: UIObject, dt: float) =
  for i in 0..high(self.shapes):
    self.shapes[i].update(Transform(position: self.bounds.minPos, matrix: identity()))
  for element in self.innerElements:
    element.update(dt)

proc add(self: UIObject, child: UIObject) {.inline.} =
  self.innerElements.add(child)

proc newUIObject* (position: Vector2, size: Vector2, hAlign: HAlign, vAlign: VAlign): UIObject =
  UIObject(position: position, size: size, hAlign: hAlign, vAlign: vAlign, innerElements: @[], shapes: @[])

proc updateLayout* (self: UIObject, parentBounds: BoundingBox) =
  case self.hAlign:
    of HAlign.left:
      self.bounds.minPos.x = parentBounds.minPos.x + self.position.x
      self.bounds.maxPos.x = self.bounds.minPos.x + self.size.x
    of HAlign.right:
      self.bounds.maxPos.x = parentBounds.maxPos.x + self.position.x
      self.bounds.minPos.x = self.bounds.maxPos.x - self.size.x
    of HAlign.center:
      self.bounds.minPos.x = parentBounds.center.x - self.size.x / 2
      self.bounds.maxPos.x = parentBounds.center.x + self.size.x / 2
    of HAlign.fill:
      self.bounds.minPos.x = parentBounds.minPos.x + self.position.x
      self.bounds.maxPos.x = parentBounds.maxPos.x + self.size.x
    of HAlign.contain:
      self.bounds.minPos.x = self.innerElements[0].bounds.minPos.x + self.position.x
      self.bounds.maxPos.x = self.innerElements[0].bounds.maxPos.x + self.size.x
  case self.vAlign:
    of VAlign.bottom:
      self.bounds.minPos.y = parentBounds.minPos.y + self.position.y
      self.bounds.maxPos.y = self.bounds.minPos.y + self.size.y
    of VAlign.top:
      self.bounds.maxPos.y = parentBounds.maxPos.y + self.position.y
      self.bounds.minPos.y = self.bounds.maxPos.y - self.size.y
    of VAlign.center:
      self.bounds.minPos.y = parentBounds.center.y - self.size.y / 2
      self.bounds.maxPos.y = parentBounds.center.y + self.size.y / 2
    of VAlign.fill:
      self.bounds.minPos.y = parentBounds.minPos.y + self.position.y
      self.bounds.maxPos.y = parentBounds.maxPos.y + self.size.y
    of VAlign.contain:
      self.bounds.minPos.y = self.innerElements[0].bounds.minPos.y + self.position.y
      self.bounds.maxPos.y = self.innerElements[0].bounds.maxPos.y + self.size.y

  for element in self.innerElements:
    element.updateLayout(self.bounds)

method renderLine* (self: UIObject) =
  for shape in self.shapes:
    shape.renderLine()
  for element in self.innerElements:
    element.renderLine()

method renderSolid* (self: UIObject) =
  for shape in self.shapes:
    shape.renderSolid()
  for element in self.innerElements:
    element.renderSolid()

method renderPoint* (self: UIObject) =
  for element in self.innerElements:
    element.renderPoint()
