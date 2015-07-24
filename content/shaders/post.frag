#version 130

uniform sampler2D sceneTex;
uniform float t;
uniform float aspectRatio;
uniform float zoom;
uniform float scanLineOffset;
uniform float scanLines;
uniform float brightnessCompensation;

const float chromaticAberration = 0.002;
const float pi2 = 3.1415926536 * 2.0;
const float contrastBoost = 2.0;

in vec2 texCoords;
in vec2 screenTexCoords;

out vec4 color;

float uniformRandom(float x)
{
  x = mod(x, 13.0) * mod(x, 123.0);
	return fract(x * 100.0);
}

void main (void)
{
  float scanLine = cos((screenTexCoords.y - scanLineOffset) * scanLines * pi2) * (-0.5) + 0.5;

  float filmGrain = uniformRandom(texCoords.x * texCoords.y * t * 1000.0);
  float aberrationBoost = clamp(pow(uniformRandom(texCoords.y * t + 1000.0), 7.0) * 0.007, 0.0, 1.0);
  vec2 noiseTexCoords = texCoords;
  noiseTexCoords.x += aberrationBoost * 0.4 / aspectRatio;
  vec2 colorOffset = vec2((chromaticAberration + aberrationBoost) / aspectRatio, 0);

  color.r = texture(sceneTex, noiseTexCoords - colorOffset * 0.75).r;
  color.g = texture(sceneTex, noiseTexCoords).g;
  color.b = texture(sceneTex, noiseTexCoords + colorOffset).b;
  color.a = 1.0;

  color.rgb -= scanLine * min(color.rgb * 1.5, 0.5) + (1.0 - filmGrain) * 0.02;
  color.rgb *= 0.9 + filmGrain * 0.1;
}
