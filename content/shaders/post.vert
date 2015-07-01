#version 130

uniform float zoom;

in vec2 vertex;

out vec2 texCoords;
out vec2 screenTexCoords;

void main(void)
{
   vec4 pos = vec4(vertex.x, vertex.y, 0.0, 1.0);

   texCoords = (pos.xy * zoom + 1.0) / 2.0;
   screenTexCoords = (pos.xy + 1.0) / 2.0;
   gl_Position = pos;
}
