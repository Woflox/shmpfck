#version 130

uniform sampler2D sceneTex;
uniform float t;
uniform float aspectRatio;
uniform float blur;

const float pi2 = 3.1415926536 * 2.0;
const int numSamples = 6;
const float contrastBoost = 4.0;
const float gamma = 2.2;

in vec2 texCoords;

out vec4 color;

float noise(float x)
{
  x = mod(x, 13.0) * mod(x, 123.0);
	x = mod(x, 0.01);
	x *= 100.0;
  return x;
}

void main (void)
{
  color = vec4(0.0, 0.0, 0.0, 1.0);

  for (int i = 0; i < numSamples; i++)
  {
    float noise1 = noise(texCoords.x * texCoords.y * (t + float(i)) * 1000.0);
    float noise2 = noise(texCoords.x * texCoords.y * (t + float(i)) * 10000.0);
    float r = sqrt(noise1);
    float angle = noise2 * pi2;
    vec2 discOffset = vec2(r * cos(angle), r * sin(angle)) * blur;
    vec2 offsetTexCoords = texCoords;
    offsetTexCoords.x += discOffset.x / aspectRatio;
    offsetTexCoords.y += discOffset.y;

    vec3 sample = texture(sceneTex, offsetTexCoords).rgb;
    color.r += pow(sample.r, 2.2);
    color.g += pow(sample.g, 2.2);
    color.b += pow(sample.b, 2.2);
  }
  color.rgb /= float(numSamples);

  color.rgb *= contrastBoost;

  color.r = pow(color.r, 1.0 / 2.2);
  color.g = pow(color.g, 1.0 / 2.2);
  color.b = pow(color.b, 1.0 / 2.2);
}
