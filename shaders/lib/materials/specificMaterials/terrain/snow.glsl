smoothnessG = (1.0 - pow(color.g, 64.0) * 0.3) * 0.4;
highlightMult = 2.0;

smoothnessD = smoothnessG;

#ifdef GBUFFERS_TERRAIN
    DoBrightBlockTweaks(color.rgb, 0.5, shadowMult, highlightMult);
#endif

#if RAIN_PUDDLES >= 1
    noPuddles = 1.0;
#endif