smoothnessG = pow2(pow2(color.g)) * 1.5;
smoothnessG = min1(smoothnessG);
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.77;
#endif