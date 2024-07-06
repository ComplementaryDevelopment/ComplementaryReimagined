#include "/lib/atmospherics/stars.glsl"

// Nebula implementation by flytrap https://godotshaders.com/shader/2d-nebula-shader/

#ifndef HQ_NIGHT_NEBULA
    const int OCTAVE = 5;
#else
    const int OCTAVE = 8;
#endif
const float timescale = 5.0;
const float zoomScale = 3.5;
const vec4 CLOUD1_COL = vec4(0.41, 0.64, 0.97, 0.4);
const vec4 CLOUD2_COL = vec4(0.81, 0.55, 0.21, 0.2);
const vec4 CLOUD3_COL = vec4(0.51, 0.81, 0.98, 1.0);

float sinM(float x) {
    return sin(mod(x, 2.0 * pi));
}

float cosM(float x) {
    return cos(mod(x, 2.0 * pi));
}

float rand(vec2 inCoord){
    return fract(sinM(dot(inCoord, vec2(23.53, 44.0))) * 42350.45);
}

float perlin(vec2 inCoord){
    vec2 i = floor(inCoord);
    vec2 j = fract(inCoord);
    vec2 coord = smoothstep(0.0, 1.0, j);

    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    return mix(mix(a, b, coord.x), mix(c, d, coord.x), coord.y);
}

float fbmCloud(vec2 inCoord, float minimum){
    float value = 0.0;
    float scale = 0.5;

    for (int i = 0; i < OCTAVE; i++){
        value += perlin(inCoord) * scale;
        inCoord *= 2.0;
        scale *= 0.5;
    }

    return smoothstep(0.0, 1.0, (smoothstep(minimum, 1.0, value) - minimum) / (1.0 - minimum));
}

float fbmCloud2(vec2 inCoord, float minimum){
    float value = 0.0;
    float scale = 0.5;

    for (int i = 0; i < OCTAVE; i++){
        value += perlin(inCoord) * scale;
        inCoord *= 2.0;
        scale *= 0.5;
    }

    return (smoothstep(minimum, 1.0, value) - minimum) / (1.0 - minimum);
}

vec3 GetNightNebula(vec3 viewPos, float VdotU, float VdotS) {
    float nebulaFactor = pow2(max0(VdotU) * min1(nightFactor * 2.0)) * invRainFactor - maxBlindnessDarkness;
    if (nebulaFactor < 0.001) return vec3(0.0);

    vec2 UV = GetStarCoord(viewPos, 0.75);
    float TIME = syncedTime * 0.003 + 15.0;

    float timescaled = TIME * timescale;
    vec2 zoomUV2
    = vec2(zoomScale * UV.x + 0.03  * timescaled * sinM(0.07 * timescaled), zoomScale * UV.y + 0.03  * timescaled * cosM(0.06 * timescaled));
    vec2 zoomUV3
    = vec2(zoomScale * UV.x + 0.027 * timescaled * sinM(0.07 * timescaled), zoomScale * UV.y + 0.025 * timescaled * cosM(0.06 * timescaled));
    vec2 zoomUV4
    = vec2(zoomScale * UV.x + 0.021 * timescaled * sinM(0.07 * timescaled), zoomScale * UV.y + 0.021 * timescaled * cosM(0.07 * timescaled));
    float tide = 0.05 * sinM(TIME);
    float tide2 = 0.06 * cosM(0.3 * TIME);

    vec4 nebulaTexture = vec4(vec3(0.0), 0.5 + 0.2 * sinM(0.23 * TIME + UV.x - UV.y));
    nebulaTexture += fbmCloud2(zoomUV3, 0.24 + tide) * CLOUD1_COL;
    nebulaTexture += fbmCloud(zoomUV2 * 0.9, 0.33 - tide) * CLOUD2_COL;
    nebulaTexture = mix(nebulaTexture, CLOUD3_COL, fbmCloud(vec2(0.9 * zoomUV4.x, 0.9 * zoomUV4.y), 0.25 + tide2));

    nebulaFactor *= 1.0 - pow2(pow2(pow2(abs(VdotS))));
    nebulaTexture.a *= min1(pow2(pow2(nebulaTexture.a))) * nebulaFactor;

    float starFactor = 1024.0;
    vec2 starCoord = floor(UV * 0.25 * starFactor) / starFactor;
    nebulaTexture.rgb *= 1.5 + 10.0 * pow2(max0(GetStarNoise(starCoord) * GetStarNoise(starCoord + 0.1) - 0.6));

    #if NIGHT_NEBULA_I != 100
        #define NIGHT_NEBULA_IM NIGHT_NEBULA_I * 0.01
        nebulaTexture.a *= NIGHT_NEBULA_IM;
    #endif

    #ifdef ATM_COLOR_MULTS
        nebulaTexture.rgb *= sqrtAtmColorMult; // C72380KD - Reduced atmColorMult impact on some things
    #endif

    return max(nebulaTexture.rgb * nebulaTexture.a, vec3(0.0));
}