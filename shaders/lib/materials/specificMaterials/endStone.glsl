float factor = pow2(pow2(color.r));
smoothnessG = factor * 0.65;
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.66;
#endif