#ifndef INCLUDE_MOON_PHASE_INF
    #define INCLUDE_MOON_PHASE_INF

    #ifdef OVERWORLD
        #if SUN_MOON_STYLE == 1
            float moonPhaseFactor = abs(moonPhase - 4.0) * 0.25;

            float halfCheck = step(0.5, moonPhaseFactor);
            float firstHalf = mix(MOON_PHASE_DARK, MOON_PHASE_PARTIAL, smoothstep(0.0, 0.5, moonPhaseFactor));
            float secondHalf = mix(MOON_PHASE_PARTIAL, MOON_PHASE_FULL, smoothstep(0.5, 1.0, moonPhaseFactor));

            float moonPhaseFactor2 = mix(firstHalf, secondHalf, halfCheck);
            float moonPhaseInfluence = mix(1.0, moonPhaseFactor2, 1.0 - sunVisibility2);
        #else
            float moonPhaseInfluence = mix(
                1.0,
                moonPhase == 0 ? MOON_PHASE_FULL : moonPhase != 4 ? MOON_PHASE_PARTIAL : MOON_PHASE_DARK,
                1.0 - sunVisibility2
            );
        #endif
    #else
        float moonPhaseInfluence = 1.0;
    #endif
#endif