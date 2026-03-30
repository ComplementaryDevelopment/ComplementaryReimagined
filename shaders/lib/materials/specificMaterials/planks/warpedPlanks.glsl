smoothnessG = pow2(color.g) * 0.5;
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.77;
#endif