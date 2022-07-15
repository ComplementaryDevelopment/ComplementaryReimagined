smoothnessG = pow2(pow2(color.r)) * 0.65;
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.5;
#endif