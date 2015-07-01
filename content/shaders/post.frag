#version 130

uniform sampler2D sceneTex;
uniform float t;
uniform float aspectRatio;
uniform float zoom;
uniform float scanLineOffset;
uniform float scanLines;

varying vec2 texCoords;
varying vec2 screenTexCoords;

const float chromaticAberration = 0.0025;
const float pi2 = 3.1415926536 * 2;
const float contrastBoost = 2.0;

float noise(float x)
{
  x = mod(x, 13) * mod(x, 123);
	x = mod(x, 0.01);
	x *= 100;
  return x;
}

void main (void)
{
  float scanLine = cos((screenTexCoords.y - scanLineOffset) * scanLines * pi2) * (-0.5) + 0.5;

  float aberrationBoost = clamp(pow(noise(texCoords.y * t + 1000), 10) * 0.01, 0, 1);
  vec2 noiseTexCoords = texCoords;
  noiseTexCoords.x += aberrationBoost * 0.6 / (aspectRatio / zoom);
  vec2 colorOffset = vec2((chromaticAberration + aberrationBoost) / (aspectRatio / zoom), 0);

  gl_FragColor.r = texture(sceneTex, noiseTexCoords - colorOffset * 0.75).r;
  gl_FragColor.g = texture(sceneTex, noiseTexCoords).g;
  gl_FragColor.b = texture(sceneTex, noiseTexCoords + colorOffset).b;
  gl_FragColor.a = 1;
  gl_FragColor.rgb -= scanLine * 0.5;
}
