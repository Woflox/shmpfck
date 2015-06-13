uniform sampler2D sceneTex;
uniform float t;
uniform float scanLines;
uniform float aspectRatio;
uniform float zoom;

varying vec2 texCoords;
varying vec2 screenTexCoords;

const float contrastBoost = 2.0;
const float chromaticAberration = 0.0025;

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
  if (scanLine > 0.6)
    scanLine = 1;
  else if (scanLine < 0.4)
    scanLine = 0;

  float filmGrain = noise(texCoords.x * texCoords.y * t * 1000);
  float aberrationBoost = pow(noise(texCoords.y * t + 1000), 10) * 0.01;
  vec2 noiseTexCoords = texCoords;
  noiseTexCoords.x += aberrationBoost * 0.2;
  vec2 colorOffset = vec2((chromaticAberration + aberrationBoost) / (aspectRatio / zoom), 0);

  gl_FragColor.r = texture(sceneTex, noiseTexCoords - colorOffset * 0.75).r;
  gl_FragColor.g = texture(sceneTex, noiseTexCoords).g;
  gl_FragColor.b = texture(sceneTex, noiseTexCoords + colorOffset).b;
  gl_FragColor.a = 1;

	vec3 lerpfactor = vec3(pow(gl_FragColor.r, 0.15),
                         pow(gl_FragColor.g, 0.15),
                         pow(gl_FragColor.b, 0.15));
  gl_FragColor.rgb = lerpfactor * gl_FragColor +
                    (1-lerpfactor) * gl_FragColor * filmGrain * 2 - scanLine * 0.5;
  gl_FragColor.rgb *= contrastBoost;
}
