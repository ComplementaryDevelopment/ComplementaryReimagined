#if MC_VERSION >= 11300
    smoothnessG = pow2(color.r) * 1.5;
    smoothnessG = min1(smoothnessG);
#else
    smoothnessG = color.r * 0.4 + 0.2;
#endif
smoothnessD = smoothnessG;