const postVert = """

varying vec2 texCoords;

void main(void)
{
   vec4 pos = vec4(gl_Vertex.xy, 0, 1);

   texCoords = (pos.xy + 1) / 2;
   gl_Position = pos;
}
"""
