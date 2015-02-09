import sdl2
import ../util/util
import tables

type
  keyConfig = object
    key: string


var keyMap = {"left"  : keyConfig(key: "Left"),
              "right" : keyConfig(key: "Right"),
              "up"    : keyConfig(key: "Up"),
              "down"  : keyConfig(key: "Down"),
              "select": keyConfig(key: "Return"),
              "pause" : keyConfig(key: "Escape"),
              "fire1" : keyConfig(key: "z"),
              "fire2" : keyConfig(key: "c"),
              "fire3" : keyConfig(key: "s"),
              "fire4" : keyConfig(key: "x")}

proc update(dt: float) =
  discard
