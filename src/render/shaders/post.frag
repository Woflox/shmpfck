const postFrag = """

uniform sampler2D sceneTex;
uniform float t;
uniform float scanLines;
uniform float zoom;

varying vec2 texCoords;
varying vec2 screenTexCoords;

const float scanLineOpacity = 0.9;
const float contrastBoost = 2;
const float chromaticAberration = 0.00187;

void main (void)
{
  float scanLine = mod(screenTexCoords.y * scanLines, 1);
  scanLine = (1 - scanLineOpacity) + scanLineOpacity * scanLine;

  float x = texCoords.x * texCoords.y * t * 1000;
	x = mod(x, 13) * mod(x, 123);
	x = mod(x, 0.01);
	x *= 100;

  vec2 offset = vec2(chromaticAberration * zoom, 0);
  gl_FragColor.r = texture(sceneTex, texCoords - offset).r;
  gl_FragColor.g = texture(sceneTex, texCoords).g;
  gl_FragColor.b = texture(sceneTex, texCoords + offset).b;
  gl_FragColor.a = 1;
  gl_FragColor.rgb *= scanLine;

	vec3 lerpfactor = vec3(pow(gl_FragColor.r, 0.15),
                         pow(gl_FragColor.g, 0.15),
                         pow(gl_FragColor.b, 0.15));
  gl_FragColor.rgb = lerpfactor * gl_FragColor + (1-lerpfactor) * gl_FragColor * x * 2;
  gl_FragColor.rgb *= contrastBoost;
}
"""
