uniform sampler2D sceneTex;
uniform float t;
uniform float aspectRatio;
uniform float blur;
uniform float brightnessCompensation;

varying vec2 texCoords;

const float pi2 = 3.1415926536 * 2;
const int numSamples = 6;
const float contrastBoost = 2;

float noise(float x)
{
  x = mod(x, 13) * mod(x, 123);
	x = mod(x, 0.01);
	x *= 100;
  return x;
}

void main (void)
{
  gl_FragColor = vec4(0, 0, 0, 1);

  float filmGrain;

  for (int i = 0; i < numSamples; i++)
  {
    filmGrain = noise(texCoords.x * texCoords.y * (t + i) * 1000);
    float noise2 = noise(texCoords.x * texCoords.y * (t + i) * 10000);
    float r = sqrt(filmGrain);
    float angle = noise2 * pi2;
    vec2 discOffset = vec2(r * cos(angle), r * sin(angle)) * blur;
    vec2 offsetTexCoords = texCoords;
    offsetTexCoords.x += discOffset.x / aspectRatio;
    offsetTexCoords.y += discOffset.y;

    vec3 sample = texture(sceneTex, offsetTexCoords).rgb;
    gl_FragColor.rgb += sample * sample;
  }
  gl_FragColor.rgb /= numSamples;

  gl_FragColor.r = sqrt(gl_FragColor.r);
  gl_FragColor.g = sqrt(gl_FragColor.g);
  gl_FragColor.b = sqrt(gl_FragColor.b);

  vec3 lerpfactor = vec3(pow(gl_FragColor.r, 0.2),
                         pow(gl_FragColor.g, 0.2),
                         pow(gl_FragColor.b, 0.2));
  gl_FragColor.rgb = lerpfactor * gl_FragColor +
                    (1-lerpfactor) * gl_FragColor * filmGrain * 2;

  gl_FragColor.rgb *= contrastBoost;
  gl_FragColor.rgb = clamp(gl_FragColor.rgb, 0, 1);
  gl_FragColor.r *= mix(brightnessCompensation, 1, sqrt(gl_FragColor.r));
  gl_FragColor.g *= mix(brightnessCompensation, 1, sqrt(gl_FragColor.g));
  gl_FragColor.b *= mix(brightnessCompensation, 1, sqrt(gl_FragColor.b));
}
