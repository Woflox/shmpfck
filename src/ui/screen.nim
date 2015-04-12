import ../util/util
import ../globals/globals
import uiobject
import text
import opengl

type
  Screen = ref object of UIObject

let baseScreenHeight* = 10.0

proc newScreen(): Screen =
  Screen(hAlign: HAlign.center, vAlign: VAlign.center, position: vec2(0,0), innerElements: @[], shapes: @[])

let hudScreen* = newScreen()
hudScreen.innerElements.add(newTextObject("FPS: ", hudTextStyle, vec2(0.5, -0.5), HAlign.left, VAlign.top))

var currentScreen* = hudScreen

method update* (self: Screen, dt: float) =
  let aspect = screenSize.x / screenSize.y
  self.bounds = boundingBox(vec2(-baseScreenHeight * aspect / 2, -baseScreenHeight / 2),
                            vec2(baseScreenHeight * aspect / 2, baseScreenHeight / 2))
  for element in self.innerElements:
    element.updateLayout(self.bounds)
  procCall UIObject(self).update(dt)

proc render* (self: Screen) =
  glPushMatrix()
  glScaled(1 / (baseScreenHeight / 2), 1 / (baseScreenHeight / 2), 1)

  glEnable (GL_BLEND);
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glBegin(GL_TRIANGLES)
  for element in self.innerElements:
    element.renderSolid()
  glEnd()
  glBegin(GL_LINES)
  for element in self.innerElements:
    element.renderLine()
  glEnd()
  glBegin(GL_POINTS)
  for element in self.innerElements:
    element.renderPoint()
  glEnd()
  glPopMatrix()
