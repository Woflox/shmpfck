import ../util/util
import opengl
import entity

type
  Camera = ref object of Entity
    target*: Entity

var
  camera* : Camera

proc newCamera(pos: Vector2): Camera =
  camera = Camera(position: pos, collidable: false, physics:Physics.none, drawable: false)
  result = camera



method update(dt: float) =

