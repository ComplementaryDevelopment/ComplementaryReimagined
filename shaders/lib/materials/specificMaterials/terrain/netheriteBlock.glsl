smoothnessG = pow2(color.r * 2.0);
smoothnessG = min1(smoothnessG);
highlightMult = smoothnessG * 2.0;
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.33;
#endif