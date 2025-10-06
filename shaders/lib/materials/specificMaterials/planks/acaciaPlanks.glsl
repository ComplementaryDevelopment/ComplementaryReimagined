smoothnessG = pow2(pow2(color.r)) * 0.45;
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.5;
#endif