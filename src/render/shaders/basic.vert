varying vec4 vColor;

void main(void)
{
   vec4 pos = vec4(gl_Vertex.xy, 0, 1);

   gl_Position = gl_ModelViewProjectionMatrix * pos;
   vColor = gl_Color;
}
