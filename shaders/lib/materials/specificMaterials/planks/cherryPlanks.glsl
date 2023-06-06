smoothnessG = pow2(pow2(color.g)) * 0.7;
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.66;
#endif