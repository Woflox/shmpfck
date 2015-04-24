const postFrag = """

uniform sampler2D sceneTex;

varying vec2 texCoords;

void main (void)
{
  gl_FragColor = texture(sceneTex, texCoords);
}
"""
