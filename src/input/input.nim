import sdl2
import ../util/util

var
  stickMoveDir: Vector2
  dPadMoveDir: Vector2
  keyboardMoveDir: Vector2



proc handleEvent(event: TEvent) =
  case event.kind:
    of ControllerAxisMotion:
    of ControllerButtonDown:
    of ControllerButtonUp:
    else:
      discard

proc update(dt: float) =
  discard
