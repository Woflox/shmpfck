#version 130

uniform vec2 screenSize;

in vec2 vertex;
in vec4 color;

out vec4 vColor;

void main(void)
{
   vec4 pos = vec4(vertex.x, vertex.y, 0.0, 1.0);

   gl_Position = gl_ModelViewProjectionMatrix * pos;
   gl_Position.xy *= screenSize;
   gl_Position.x = round(gl_Position.x);
   gl_Position.y = round(gl_Position.y);
   gl_Position.xy /= screenSize;
   vColor = gl_Color;
}
