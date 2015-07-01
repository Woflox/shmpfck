#version 130

in vec2 vertex;
in vec4 color;

out vec4 vColor;

void main(void)
{
   vec4 pos = vec4(vertex.x, vertex.y, 0.0, 1.0);

   gl_Position = gl_ModelViewProjectionMatrix * pos;
   vColor = gl_Color;
}
