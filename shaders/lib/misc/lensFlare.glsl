float fovmult = gbufferProjection[1][1] / 1.37373871;

float BaseLens(vec2 lightPos, float size, float dist, float hardness) {
    vec2 lensCoord = (texCoord + (lightPos * dist - 0.5)) * vec2(aspectRatio, 1.0);
    float lens = clamp(1.0 - length(lensCoord) / (size * fovmult), 0.0, 1.0 / hardness) * hardness;
    lens *= lens; lens *= lens;
    return lens;
}

float OverlapLens(vec2 lightPos, float size, float dista, float distb) {
    return BaseLens(lightPos, size, dista, 2.0) * BaseLens(lightPos, size, distb, 2.0);
}

float PointLens(vec2 lightPos, float size, float dist) {
    float lens = BaseLens(lightPos, size, dist, 1.5) + BaseLens(lightPos, size * 4.0, dist, 1.0) * 0.5;
    return lens * (0.5 + 0.5 * sunFactor);
}

float RingLensTransform(float lensFlare) {
    return pow(1.0 - pow(1.0 - pow(lensFlare, 0.25), 10.0), 5.0);
}
float RingLens(vec2 lightPos, float size, float distA, float distB) {
    float lensFlare1 = RingLensTransform(BaseLens(lightPos, size, distA, 1.0));
    float lensFlare2 = RingLensTransform(BaseLens(lightPos, size, distB, 1.0));

    float lensFlare = clamp(lensFlare2 - lensFlare1, 0.0, 1.0);
    lensFlare *= sqrt(lensFlare);

    lensFlare *= 1.0 - length(texCoord - lightPos - 0.5);
    return lensFlare;
}

vec2 lensFlareCheckOffsets[4] = vec2[4](
    vec2( 1.0,0.0),
    vec2(-1.0,1.0),
    vec2( 0.0,1.0),
    vec2( 1.0,1.0)
);

void DoLensFlare(inout vec3 color, vec3 viewPos, float dither) {
    #if LENSFLARE_MODE == 1
        if (sunVec.z > 0.0) return;
    #endif

    vec4 clipPosSun = gbufferProjection * vec4(sunVec + 0.001, 1.0); //+0.001 fixes black screen with camera rotation set to 0,0
    vec3 lightPos3 = clipPosSun.xyz / clipPosSun.w * 0.5;
    vec2 lightPos = lightPos3.xy;
    vec3 screenPosSun = lightPos3 + 0.5;

    float flareFactor = 1.0;
    vec2 cScale = 40.0 / vec2(viewWidth, viewHeight);
    for (int i = 0; i < 4; i++) {
        vec2 cOffset = (lensFlareCheckOffsets[i] - dither) * cScale;
        vec2 checkCoord1 = screenPosSun.xy + cOffset;
        vec2 checkCoord2 = screenPosSun.xy - cOffset;

        float zSample1 = texture2D(depthtex0, checkCoord1).r;
        float zSample2 = texture2D(depthtex0, checkCoord2).r;
        #ifdef VL_CLOUDS_ACTIVE
            float cloudLinearDepth1 = texture2D(colortex4, checkCoord1).r;
            float cloudLinearDepth2 = texture2D(colortex4, checkCoord2).r;
            zSample1 = min(zSample1, cloudLinearDepth1);
            zSample2 = min(zSample2, cloudLinearDepth2);
        #endif

        if (zSample1 < 1.0)
            flareFactor -= 0.125;
        if (zSample2 < 1.0)
            flareFactor -= 0.125;
    }

    float str = length(lightPos * vec2(aspectRatio, 1.0));
    str = pow(clamp(str * 8.0, 0.0, 1.0), 2.0) - clamp(str * 3.0 - 1.5, 0.0, 1.0);
    flareFactor *= str;

    #ifdef SUN_MOON_DURING_RAIN
        flareFactor *= 0.65 - 0.4 * rainFactor;
    #else
        flareFactor *= 1.0 - rainFactor;
    #endif

    vec3 flare = (
        BaseLens(lightPos, 0.3, -0.45, 1.0) * vec3(2.2, 1.2, 0.1) * 0.07 +
        BaseLens(lightPos, 0.3,  0.10, 1.0) * vec3(2.2, 0.4, 0.1) * 0.03 +
        BaseLens(lightPos, 0.3,  0.30, 1.0) * vec3(2.2, 0.2, 0.1) * 0.04 +
        BaseLens(lightPos, 0.3,  0.50, 1.0) * vec3(2.2, 0.4, 2.5) * 0.05 +
        BaseLens(lightPos, 0.3,  0.70, 1.0) * vec3(1.8, 0.4, 2.5) * 0.06 +
        BaseLens(lightPos, 0.3,  0.90, 1.0) * vec3(0.1, 0.2, 2.5) * 0.07 +

        OverlapLens(lightPos, 0.08, -0.28, -0.39) * vec3(2.5, 1.2, 0.1) * 0.015 +
        OverlapLens(lightPos, 0.08, -0.20, -0.31) * vec3(2.5, 0.5, 0.1) * 0.010 +
        OverlapLens(lightPos, 0.12,  0.06,  0.19) * vec3(2.5, 0.2, 0.1) * 0.020 +
        OverlapLens(lightPos, 0.12,  0.15,  0.28) * vec3(1.8, 0.1, 1.2) * 0.015 +
        OverlapLens(lightPos, 0.12,  0.24,  0.37) * vec3(1.0, 0.1, 2.5) * 0.010 +

        PointLens(lightPos, 0.03, -0.55) * vec3(2.5, 1.6, 0.0) * 0.06 +
        PointLens(lightPos, 0.02, -0.40) * vec3(2.5, 1.0, 0.0) * 0.045 +
        PointLens(lightPos, 0.04,  0.43) * vec3(2.5, 0.6, 0.6) * 0.06 +
        PointLens(lightPos, 0.02,  0.60) * vec3(0.2, 0.6, 2.5) * 0.045 +
        PointLens(lightPos, 0.03,  0.67) * vec3(0.7, 1.1, 3.0) * 0.075 +

        RingLens(lightPos, 0.22, 0.44, 0.46) * vec3(0.10, 0.35, 2.50) * 1.5 +
        RingLens(lightPos, 0.15, 0.98, 0.99) * vec3(0.15, 0.40, 2.55) * 2.5
    );

    #if LENSFLARE_MODE == 2
        if (sunVec.z > 0.0) {
            flare = flare * 0.2 + GetLuminance(flare) * vec3(0.3, 0.4, 0.6);
            flare *= clamp01(1.0 - (SdotU + 0.1) * 5.0);
            flareFactor *= LENSFLARE_I > 1.001 ? sqrt(LENSFLARE_I) : LENSFLARE_I;
        } else
    #endif
    {
        flareFactor *= LENSFLARE_I;
        flare *= clamp01((SdotU + 0.1) * 5.0);
    }

    flare *= flareFactor;

    color = mix(color, vec3(1.0), flare);
}