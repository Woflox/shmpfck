#version 130

uniform float zoom;

varying vec2 texCoords;
varying vec2 screenTexCoords;

void main(void)
{
   vec4 pos = vec4(gl_Vertex.xy, 0, 1);

   texCoords = (pos.xy * zoom + 1) / 2;
   screenTexCoords = (pos.xy + 1) / 2;
   gl_Position = pos;
}
