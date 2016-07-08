import ../util/random
import voice
import strutils

const prose = staticRead("../../content/prose.txt")
let proseLines = prose.splitLines()

proc sayProse* () =
  say(proseLines.randomChoice())
