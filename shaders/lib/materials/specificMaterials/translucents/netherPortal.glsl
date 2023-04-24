lmCoordM = vec2(0.0);
color = vec4(0.0);

int sampleCount = 8;

float multiplier = 0.4 / (-viewVector.z * sampleCount);
vec2 interval = viewVector.xy * multiplier;
vec2 coord = signMidCoordPos * 0.5 + 0.5;
vec2 absMidCoordPos2 = absMidCoordPos * 2.0;
vec2 midCoord = texCoord - absMidCoordPos * signMidCoordPos;
vec2 minimumMidCoordPos = midCoord - absMidCoordPos;

for (int i = 0; i < sampleCount; i++) {
    float portalStep = (i + dither) / sampleCount;
    coord += interval * portalStep;
    vec2 sampleCoord = fract(coord) * absMidCoordPos2 + minimumMidCoordPos;
    vec4 psample = texture2DLod(tex, sampleCoord, 0);

    float factor = 1.0 - portalStep;
    psample *= pow(factor, 0.1);

    emission = max(emission, psample.r);

    color += psample;
}
color /= sampleCount;

color.rgb *= color.rgb * vec3(1.25, 1.0, 0.65);
color.a = sqrt1(color.a) * 0.8;

emission *= emission;
emission *= emission;
emission *= emission;
emission = clamp(emission * 120.0, 0.03, 1.2) * 8.0;