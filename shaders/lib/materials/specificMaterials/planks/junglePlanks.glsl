smoothnessG = pow2(pow2(pow2(color.g))) * 12.0;
smoothnessG = min1(smoothnessG);
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.66;
#endif