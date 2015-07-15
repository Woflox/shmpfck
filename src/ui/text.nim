import uiobject
import ../util/util
import ../geometry/shape
import tables
import opengl

let
  baseLetterSize = vec2(2,3)
  baseLetterSpacing = 1.0

  bottomLeft = vec2(0,0)
  topLeft = vec2(0,3)
  topRight = vec2(2,3)
  bottomRight = vec2(2,0)
  centerLeft = vec2(0, 1.5)
  centerRight = vec2(2, 1.5)
  center = vec2(1,1.5)
  centerBottom = vec2(1,0)
  centerTop = vec2(1,3)

let letters =
  { 'a': @[@[bottomLeft, vec2(0,2), centerTop, vec2(2,2), bottomRight],
           @[vec2(0,1.125), vec2(2,1.125)]],
    'b': @[@[bottomLeft, topLeft, vec2(1.5, 3), vec2(2, 2.5,), vec2(2, 2), vec2(1.5, 1.5), vec2(2, 1), vec2(2, 0.5), vec2(1.5, 0), bottomLeft],
           @[vec2(0, 1.5), vec2(1.5, 1.5)]],
    'c': @[@[bottomRight, bottomLeft, topLeft, topRight]],
    'd': @[@[bottomLeft, topLeft, vec2(1.125, 3), vec2(2, 2.125), vec2(2, 0.875), vec2(1.125, 0), bottomLeft]],
    'e': @[@[bottomRight, bottomLeft, topLeft, topRight],
           @[centerLeft, vec2(1.5, 1.5)]],
    'f': @[@[bottomLeft, topLeft, topRight],
           @[centerLeft, vec2(1.5, 1.5)]],
    'g': @[@[vec2(1, 1.25), vec2(2, 1.25), bottomRight, bottomLeft, topLeft, topRight, vec2(2,2.25)]],
    'h': @[@[bottomLeft, topLeft],
           @[bottomRight, topRight],
           @[centerLeft, centerRight]],
    'i': @[@[bottomLeft, bottomRight],
           @[topLeft, topRight],
           @[centerBottom, centerTop]],
    'j': @[@[vec2(0, 0.875), vec2(0.875, 0), bottomRight, topRight]],
    'k': @[@[bottomLeft, topLeft],
           @[vec2(0,1.25), vec2(0.25,1.5), topRight],
           @[vec2(0.25, 1.5), bottomRight]],
    'l': @[@[topLeft, bottomLeft, bottomRight]],
    'm': @[@[bottomLeft, topLeft, center, topRight, bottomRight]],
    'n': @[@[bottomLeft, topLeft, bottomRight, topRight]],
    'o': @[@[bottomLeft, topLeft, topRight, bottomRight, bottomLeft]],
    'p': @[@[bottomLeft, topLeft, topRight, centerRight, centerLeft]],
    'q': @[@[bottomLeft, topLeft, topRight, vec2(2, 0.75), vec2(1.25,0), bottomLeft],
           @[vec2(1.25, 0.75), bottomRight]],
    'r': @[@[bottomLeft, topLeft, topRight, centerRight, centerLeft],
           @[vec2(0.5,1.5), bottomRight]],
    's': @[@[bottomLeft, bottomRight, centerRight, centerLeft, topLeft, topRight]],
    't': @[@[centerBottom, centerTop],
           @[topLeft, topRight]],
    'u': @[@[topLeft, bottomLeft, bottomRight, topRight]],
    'v': @[@[topLeft, centerBottom, topRight]],
    'w': @[@[topLeft, bottomLeft, center, bottomRight, topRight]],
    'x': @[@[topLeft, bottomRight],
           @[bottomLeft, topRight]],
    'y': @[@[topLeft, center, centerBottom],
           @[topRight, center]],
    'z': @[@[topLeft, topRight, bottomLeft, bottomRight]],
    '0': @[@[bottomLeft, topLeft, topRight, bottomRight, bottomLeft]],
    '1': @[@[centerBottom, centerTop]],
    '2': @[@[topLeft, topRight, centerRight, centerLeft, bottomLeft, bottomRight]],
    '3': @[@[topLeft, topRight, bottomRight, bottomLeft],
           @[centerLeft, centerRight]],
    '4': @[@[topLeft, centerLeft, centerRight],
           @[topRight, bottomRight]],
    '5': @[@[topRight, topLeft, centerLeft, centerRight, bottomRight, bottomLeft]],
    '6': @[@[topRight, topLeft, bottomLeft, bottomRight, centerRight, centerLeft]],
    '7': @[@[topLeft, topRight, bottomRight]],
    '8': @[@[bottomLeft, topLeft, topRight, bottomRight, bottomLeft],
           @[centerLeft, centerRight]],
    '9': @[@[bottomRight, topRight, topLeft, centerLeft, centerRight]],
    '.': @[@[centerBottom,]],
    ':': @[@[vec2(1,0.5)],
           @[vec2(1,2.5)]],
    '?': @[@[topLeft, topRight, vec2(2, 1.75), vec2(1,1.25), vec2(1,1)],
           @[centerBottom, centerBottom]],
    '!': @[@[centerTop, vec2(1,1)],
           @[centerBottom, vec2(1, 0.25)]],
    ',': @[@[vec2(0.75,0), vec2(1,0.25), vec2(1,0.5)]],
    '"': @[@[vec2(0.75,3), vec2(0.75,2.5)],
           @[vec2(1.25,3), vec2(1.25,2.5)]],
    '\'': @[@[centerTop, vec2(1,2.5)]],
    ';': @[@[vec2(0.75,0), vec2(1,0.25), vec2(1,0.5)],
           @[vec2(1,2.5)]],
    '-': @[@[centerLeft, centerRight]],
    '<': @[@[vec2(1.75,3), vec2(0.25,1.5), vec2(1.75,0)]],
    '>': @[@[vec2(0.25,5), vec2(1.75,1.5), vec2(0.25,0)]],
    '/': @[@[bottomLeft, topRight]],
    '(': @[@[vec2(1.25,3), vec2(0.5, 2.25), vec2(0.5, 0.75), vec2(1.25,0)]],
    ')': @[@[vec2(0.75,3), vec2(1.5,2.25), vec2(1.5,0.75), vec2(0.75,0)]],
    '+': @[@[centerLeft, centerRight],
           @[vec2(1,2.5), vec2(1,0.5)]],
    '%': @[@[topRight, bottomLeft],
           @[vec2(0,3),vec2(0.5,3),vec2(0.5,2.5),vec2(0,2.5),vec2(0,3)],
           @[vec2(2,0),vec2(1.5,0),vec2(1.5,0.5),vec2(2,0.5),vec2(2,0)]],
    '[': @[@[vec2(1.25,3), vec2(0.75,3), vec2(0.75,0), vec2(1.25,0)]],
    ']': @[@[vec2(0.75,3), vec2(1.25,3), vec2(1.25,0), vec2(0.75,0)]],
    '|': @[@[centerTop, centerBottom]]}.toTable()


type
  TextStyle* = object
    color: Color
    size: float
  TextObject* = ref object of UIObject
    text: string
    style: TextStyle

let hudTextStyle* = TextStyle(color: color(1,1,1,1), size: 0.25)

proc setText* (self: TextObject, text: string) =
  self.text = text
  self.size = vec2(self.style.size * ((baseLetterSize.x + baseLetterSpacing) * float(self.text.len) - baseLetterSpacing) / baseLetterSize.y,
                   self.style.size)

proc newTextObject* (text: string, style: TextStyle, position: Vector2, hAlign: HAlign, vAlign: VAlign): TextObject =
  result = TextObject(position: position, style: style, hAlign: hAlign, vAlign: vAlign, innerElements: @[], shapes: @[])
  result.setText(text)

proc toLowercase(c: char): char =
  if c >= 'A' and c <= 'Z':
    result = char(int(c) + (int('a') - int('A')))
  else:
    result = c

method renderLine(self: TextObject) =
  var offset = 0.0
  let scale = self.style.size / baseLetterSize.y
  let increment = (baseLetterSize.x + baseLetterSpacing) * scale
  glColor4d(self.style.color)
  for letter in self.text:
    if letter != ' ':
      let lowerCase = toLowercase(letter)
      if letters.hasKey(lowerCase):
        for vertexList in letters[toLowercase(letter)]:
          for i in 0..vertexList.high - 1:
            glVertex2d(vertexList[i]*scale + self.bounds.minPos + vec2(offset, 0))
            glVertex2d(vertexList[i+1]*scale + self.bounds.minPos + vec2(offset, 0))
      else:
        echo "MISSING GEOMETRY FOR LETTER: ",letter
    offset += increment

method renderPoint(self: TextObject) =
  var offset = 0.0
  let scale = self.style.size / baseLetterSize.y
  let increment = (baseLetterSize.x + baseLetterSpacing) * scale
  glColor4d(self.style.color)
  for letter in self.text:
    if letter != ' ':
      for vertexList in letters[toLowercase(letter)]:
        for i in 0..vertexList.high:
          glVertex2d(vertexList[i]*scale + self.bounds.minPos + vec2(offset, 0))
    offset += increment
