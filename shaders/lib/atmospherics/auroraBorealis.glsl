vec3 GetAuroraBorealis(vec3 viewPos, float VdotU, float dither) {
    float visibility = sqrt1(clamp01(VdotU * 1.5 - 0.225)) - sunVisibility - rainFactor - blindness - darknessFactor;
    visibility *= 1.0 - VdotU * 0.9;

    #if AURORA_CONDITION == 1 || AURORA_CONDITION == 3
        visibility -= moonPhase;
    #endif
    #if AURORA_CONDITION == 2 || AURORA_CONDITION == 3
        visibility *= inSnowy;
    #endif
    #if AURORA_CONDITION == 4
        visibility = max(visibility * inSnowy, visibility - moonPhase);
    #endif

    if (visibility > 0.0) {
        vec3 aurora = vec3(0.0);

        vec3 wpos = mat3(gbufferModelViewInverse) * viewPos;
             wpos.xz /= wpos.y;
        vec2 cameraPositionM = cameraPosition.xz * 0.0075;
             cameraPositionM.x += syncedTime * 0.04;

        #ifdef DEFERRED1
            int sampleCount = 25;
            int sampleCountP = sampleCount + 5;
        #elif defined GBUFFERS_WATER
            int sampleCount = 10;
            int sampleCountP = sampleCount + 10;
        #endif

        float ditherM = dither + 5.0;
        float auroraAnimate = frameTimeCounter * 0.001;
        for (int i = 0; i < sampleCount; i++) {
            float current = pow2((i + ditherM) / sampleCountP);

            vec2 planePos = wpos.xz * (0.8 + current) * 11.0 + cameraPositionM;
            #if AURORA_STYLE == 1
                planePos = floor(planePos) * 0.0007;

                float noise = texture2D(noisetex, planePos).b;
                noise = pow2(pow2(pow2(pow2(1.0 - 2.0 * abs(noise - 0.5)))));

                noise *= pow1_5(texture2D(noisetex, planePos * 100.0 + auroraAnimate).b);
            #else
                planePos *= 0.0007;

                float noise = texture2D(noisetex, planePos).r;
                noise = pow2(pow2(pow2(pow2(1.0 - 2.0 * abs(noise - 0.5)))));

                noise *= texture2D(noisetex, planePos * 3.0 + auroraAnimate).b;
                noise *= texture2D(noisetex, planePos * 5.0 - auroraAnimate).b;
            #endif

            float currentM = 1.0 - current;
            aurora += noise * currentM * mix(vec3(7.0, 2.2, 12.0), vec3(6.0, 16.0, 12.0), pow2(pow2(currentM)));
        }

        #if AURORA_STYLE == 1
            aurora *= 1.3;
        #else
            aurora *= 1.8;
        #endif

        #ifdef ATM_COLOR_MULTS
            aurora *= sqrtAtmColorMult; // C72380KD - Reduced atmColorMult impact on some things
        #endif

        return aurora * visibility / sampleCount;
    }

    return vec3(0.0);
}