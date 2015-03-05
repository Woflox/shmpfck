type
  FireType* {.pure.} = enum
    automatic
    charge
  Weapon* = ref object
    fireType* : FireType
