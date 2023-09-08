uniform int moonPhase;

float moonPhaseInfluence = mix(
    1.0,
    moonPhase == 0 ? MOON_PHASE_FULL : moonPhase != 4 ? MOON_PHASE_PARTIAL : MOON_PHASE_DARK,
    1.0 - sunVisibility2
);