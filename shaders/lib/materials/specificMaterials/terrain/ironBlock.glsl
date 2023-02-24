materialMask = OSIEBCA; // Intense Fresnel
smoothnessG = pow2(pow2(color.r));
highlightMult = smoothnessG * 3.0;
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.33;
#endif