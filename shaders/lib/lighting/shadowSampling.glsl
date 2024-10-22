vec3 GetShadowPos(vec3 playerPos) {
    vec3 shadowPos = PlayerToShadow(playerPos);
    float distb = sqrt(shadowPos.x * shadowPos.x + shadowPos.y * shadowPos.y);
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);
    shadowPos.xy /= distortFactor;
    shadowPos.z *= 0.2;
    return shadowPos * 0.5 + 0.5;
}

vec3 SampleShadow(vec3 shadowPos, float colorMult, float colorPow) {
    float shadow0 = shadow2D(shadowtex0, vec3(shadowPos.st, shadowPos.z)).x;

    vec3 shadowcol = vec3(0.0);
    if (shadow0 < 1.0) {
        float shadow1 = shadow2D(shadowtex1, vec3(shadowPos.st, shadowPos.z)).x;
        if (shadow1 > 0.9999) {
            shadowcol = texture2D(shadowcolor0, shadowPos.st).rgb * shadow1;

            shadowcol *= colorMult;
            shadowcol = pow(shadowcol, vec3(colorPow));
        }
    }

    return shadowcol * (1.0 - shadow0) + shadow0;
}

float InterleavedGradientNoiseForShadows() {
    float n = 52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y);
    #if !defined GBUFFERS_ENTITIES && !defined GBUFFERS_HAND && !defined GBUFFERS_TEXTURED && defined TAA
        return fract(n + goldenRatio * mod(float(frameCounter), 3600.0));
    #else
        return fract(n);
    #endif
}

vec2 offsetDist(float x, int s) {
    float n = fract(x * 2.427) * 3.1415;
    return vec2(cos(n), sin(n)) * 1.4 * x / s;
}

vec3 SampleTAAFilteredShadow(vec3 shadowPos, float lViewPos, float offset, bool leaves, float colorMult, float colorPow) {
    vec3 shadow = vec3(0.0);
    float gradientNoise = InterleavedGradientNoiseForShadows();

    #if SHADOW_QUALITY == 0
        int shadowSamples = 0; // We don't use SampleTAAFilteredShadow on Shadow Quality 0
    #elif SHADOW_QUALITY == 1
        int shadowSamples = 1;
    #elif SHADOW_QUALITY == 2 || SHADOW_QUALITY == 3
        int shadowSamples = 2;
    #elif SHADOW_QUALITY == 4
        int shadowSamples = 2;
        if (lViewPos < 10.0) shadowSamples = 6;
    #elif SHADOW_QUALITY == 5
        int shadowSamples = 6;
        if (lViewPos < 10.0) shadowSamples = 12;
    #endif

    #if !defined GBUFFERS_ENTITIES && !defined GBUFFERS_HAND && !defined GBUFFERS_TEXTURED
        offset *= 1.3875;
    #else
        shadowSamples *= 2;
        offset *= 0.69375;
    #endif

    float shadowPosZM = shadowPos.z;
    for (int i = 0; i < shadowSamples; i++) {
        vec2 offset2 = offsetDist(gradientNoise + i, shadowSamples) * offset;
        if (leaves) shadowPosZM = shadowPos.z - 0.12 * offset * (gradientNoise + i) / shadowSamples;
        shadow += SampleShadow(vec3(shadowPos.st + offset2, shadowPosZM), colorMult, colorPow);
        shadow += SampleShadow(vec3(shadowPos.st - offset2, shadowPosZM), colorMult, colorPow);
    }

    shadow /= shadowSamples * 2.0;

    return shadow;
}

vec2 shadowOffsets[4] = vec2[4](
    vec2( 1.0, 0.0),
    vec2( 0.0, 1.0),
    vec2(-1.0, 0.0),
    vec2( 0.0,-1.0));

vec3 SampleBasicFilteredShadow(vec3 shadowPos, float offset) {
    float shadow = 0.0;

    for (int i = 0; i < 4; i++) {
        shadow += shadow2D(shadowtex0, vec3(offset * shadowOffsets[i] + shadowPos.st, shadowPos.z)).x;
    }

    return vec3(shadow * 0.25);
}

vec3 GetShadow(vec3 shadowPos, float lViewPos, float lightmapY, float offset, bool leaves) {
    #if SHADOW_QUALITY > 0
        #if ENTITY_SHADOWS_DEFINE == -1 && defined GBUFFERS_BLOCK
            offset *= 4.0;
        #else
            #ifdef OVERWORLD
                offset *= 1.0 + rainFactor2 * 2.0;
            #else
                offset *= 3.0;
            #endif
        #endif
    #endif

    float colorMult = 1.2 + 3.8 * lightmapY; // Natural strength is 5.0
    float colorPow = 1.1 - 0.6 * pow2(pow2(pow2(lightmapY)));

    #if SHADOW_QUALITY >= 1
        vec3 shadow = SampleTAAFilteredShadow(shadowPos, lViewPos, offset, leaves, colorMult, colorPow);
    #else
        vec3 shadow = SampleBasicFilteredShadow(shadowPos, offset);
    #endif

    return shadow;
}