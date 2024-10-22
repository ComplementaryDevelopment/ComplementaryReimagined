#ifndef INCLUDE_MOON_PHASE_INF
    #define INCLUDE_MOON_PHASE_INF

    #ifdef OVERWORLD
        float moonPhaseInfluence = mix(
            1.0,
            moonPhase == 0 ? MOON_PHASE_FULL : moonPhase != 4 ? MOON_PHASE_PARTIAL : MOON_PHASE_DARK,
            1.0 - sunVisibility2
        );
    #else
        float moonPhaseInfluence = 1.0;
    #endif
#endif