import sdl2
import sdl2/joystick
import sdl2/gamecontroller
import ../util/util
import queues

var
  stickMoveDir: Vector2
  buttonMoveDir: Vector2
  controller: GameControllerPtr

type
  Action* = enum
    left, right, up, down, fire1, fire2, fire3, fire4

  Control = ref object
    key: cint
    button: uint8
    down: bool
    pressed: bool
    released: bool
    action: Action

const maxAxisValue = 32768.0
const deadZone = 0.2

var
  controls* = [Control(action: left,  key: K_LEFT,  button: SDL_CONTROLLER_BUTTON_DPAD_LEFT),
               Control(action: right, key: K_RIGHT, button: SDL_CONTROLLER_BUTTON_DPAD_RIGHT),
               Control(action: up,    key: K_UP,    button: SDL_CONTROLLER_BUTTON_DPAD_UP),
               Control(action: down,  key: K_DOWN,  button: SDL_CONTROLLER_BUTTON_DPAD_DOWN),
               Control(action: fire1, key: K_Z,     button: SDL_CONTROLLER_BUTTON_X),
               Control(action: fire2, key: K_C,     button: SDL_CONTROLLER_BUTTON_B),
               Control(action: fire3, key: K_S,     button: SDL_CONTROLLER_BUTTON_Y),
               Control(action: fire4, key: K_X,     button: SDL_CONTROLLER_BUTTON_A)]

  events = initQueue[Event]()

proc addEvent*(event: var Event) =
  events.enqueue(event)

proc handleEvent(event: var Event) =
  case event.kind:
    of ControllerAxisMotion:
      case event.caxis.axis:
        of uint8(SDL_CONTROLLER_AXIS_LEFTX):
          let axisValue = float(event.caxis.value) / maxAxisValue
          stickMoveDir.x = if abs(axisValue) > deadZone: axisValue else: 0
        of uint8(SDL_CONTROLLER_AXIS_LEFTY):
          let axisValue = float(event.caxis.value) / maxAxisValue
          stickMoveDir.y = if abs(axisValue) > deadZone: -axisValue else: 0
        else:
          discard

    of ControllerButtonDown:
      for control in controls:
        if control.button == event.cbutton.button:
          control.pressed = true
          control.down = true

    of ControllerButtonUp:
      for control in controls:
        if control.button == event.cbutton.button:
          control.released = true
          control.down = false

    of KeyDown:
      if not event.key.repeat:
        for control in controls:
          if control.key == event.key.keysym.sym:
            control.pressed = true
            control.down = true

    of KeyUp:
        for control in controls:
          if control.key == event.key.keysym.sym:
            control.released = true
            control.down = false

    else:
      discard

proc buttonDown*(action: Action): bool =
  result = controls[int(action)].down

proc buttonPressed*(action: Action): bool =
  result = controls[int(action)].pressed

proc buttonReleased*(action: Action): bool =
  result = controls[int(action)].released

proc moveDir*(): Vector2 =
  result = if stickMoveDir == vec2(0, 0): buttonMoveDir else: stickMoveDir.normalize()

proc init*() =
  for i in 0..(numJoysticks() -1):
    if isGameController(i):
      controller = gameControllerOpen(i)


proc update*(dt: float) =
  for control in controls:
    control.pressed = false
    control.released = false

  while events.len > 0:
    var event = events.dequeue()
    handleEvent(event)

  buttonMoveDir = vec2(0,0)
  if buttonDown(left):
    buttonMoveDir.x -= 1
  if buttonDown(right):
    buttonMoveDir.x += 1
  if buttonDown(up):
    buttonMoveDir.y += 1
  if buttonDown(down):
    buttonMoveDir.y -= 1

