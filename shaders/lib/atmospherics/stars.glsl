#include "/lib/colors/skyColors.glsl"

float GetStarNoise(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
}

vec2 GetStarCoord(vec3 viewPos, float sphereness) {
    vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos * 1000.0, 1.0)).xyz);
    vec3 starCoord = wpos / (wpos.y + length(wpos.xz) * sphereness);
    vec3 moonPos = vec3(gbufferModelViewInverse * vec4(- sunVec * 70.0, 1.0));
    vec3 moonCoord = moonPos / (moonPos.y + length(moonPos.xz) * sphereness);
    return starCoord.xz - moonCoord.xz;
}

vec3 GetStars(vec2 starCoord, float VdotU, float VdotS) {
    if (VdotU < 0.0) return vec3(0.0);

    starCoord *= 0.25;
    float starFactor = 1024.0;
    starCoord = floor(starCoord * starFactor) / starFactor;

    float star = 1.0;
    star *= GetStarNoise(starCoord.xy);
    star *= GetStarNoise(starCoord.xy+0.1);
    star *= GetStarNoise(starCoord.xy+0.23);

    #if NIGHT_STAR_AMOUNT == 2
        star -= 0.7;
    #else
        star -= 0.6;
        star *= 0.65;
    #endif
    star = max0(star);
    star *= star;

    float starFogFactor = min1(VdotU * 3.0);
    star *= starFogFactor * (1.0 - sunVisibility);
    star *= max0(1.0 - pow(abs(VdotS) * 1.002, 100.0));

    vec3 stars = 40.0 * star * vec3(0.38, 0.4, 0.5) * invRainFactor;

    return stars;
}