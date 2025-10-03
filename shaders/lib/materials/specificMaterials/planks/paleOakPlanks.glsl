smoothnessG = pow2(color.g) * 0.22;
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.66;
#endif