const postFrag = """

uniform sampler2D sceneTex;
uniform float t;
uniform float scanLines;
uniform float zoom;
uniform float aspectRatio;

varying vec2 texCoords;
varying vec2 screenTexCoords;

const float contrastBoost = 1.75;
const float chromaticAberration = 0.00275;

float noise(float x)
{
  x = mod(x, 13) * mod(x, 123);
	x = mod(x, 0.01);
	x *= 100;
  return x;
}

void main (void)
{
  float scanLine = mod(screenTexCoords.y * scanLines, 1);

  float filmGrain = noise(texCoords.x * texCoords.y * t * 1000);
  vec2 colorOffset = vec2(chromaticAberration / aspectRatio, 0);

  gl_FragColor.r = texture(sceneTex, texCoords - colorOffset * 0.75).r;
  gl_FragColor.g = texture(sceneTex, texCoords).g;
  gl_FragColor.b = texture(sceneTex, texCoords + colorOffset).b;
  gl_FragColor.a = 1;

	vec3 lerpfactor = vec3(pow(gl_FragColor.r, 0.15),
                         pow(gl_FragColor.g, 0.15),
                         pow(gl_FragColor.b, 0.15));
  gl_FragColor.rgb = lerpfactor * gl_FragColor * ((scanLine + 1) * 0.5) +
                    (1-lerpfactor) * gl_FragColor * filmGrain * scanLine * 2;
  gl_FragColor.rgb *= contrastBoost;
}
"""
