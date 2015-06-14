uniform sampler2D sceneTex;
uniform float t;
uniform float aspectRatio;
uniform float zoom;
uniform float screenHeight;
uniform float scanLines;
uniform float brightnessCompensation;

varying vec2 texCoords;
varying vec2 screenTexCoords;

const float contrastBoost = 2;
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
  float scanLineOffset = 0.5 / screenHeight;
  float scanLine = mod((screenTexCoords.y - scanLineOffset) * scanLines, 1);
  scanLine = 1 - abs((scanLine * 2) - 1);

  float filmGrain = noise(texCoords.x * texCoords.y * t * 1000);
  float aberrationBoost = clamp(pow(noise(texCoords.y * t + 1000), 10) * 0.01, 0, 1);
  vec2 noiseTexCoords = texCoords;
  noiseTexCoords.x += aberrationBoost * 0.2;
  vec2 colorOffset = vec2((chromaticAberration + aberrationBoost) / (aspectRatio / zoom), 0);

  gl_FragColor.r = texture(sceneTex, noiseTexCoords - colorOffset * 0.75).r;
  gl_FragColor.g = texture(sceneTex, noiseTexCoords).g;
  gl_FragColor.b = texture(sceneTex, noiseTexCoords + colorOffset).b;
  gl_FragColor.a = 1;
  gl_FragColor.rgb = (gl_FragColor - (1 - filmGrain) * 0.015 ) - scanLine * 0.5;
  gl_FragColor.rgb *= contrastBoost * (0.75 + filmGrain * 0.25);
  gl_FragColor.rgb = clamp(gl_FragColor.rgb, 0, 1);
  gl_FragColor.rgb *= gl_FragColor.rgb +
                     (1 - gl_FragColor.rgb) * brightnessCompensation;
}
