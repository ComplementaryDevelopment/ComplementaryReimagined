smoothnessG = pow2(dot(color.rgb, color.rgb)) * 0.105;
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.77;
#endif