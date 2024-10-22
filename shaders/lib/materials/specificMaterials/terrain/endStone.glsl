float factor = pow2(pow2(color.r));
smoothnessG = factor * 0.65;
smoothnessD = smoothnessG * 0.6;

#ifdef COATED_TEXTURES
    noiseFactor = 0.66;
#endif