materialMask = OSIEBCA * 5.0; // Redstone Fresnel

float factor = pow2(color.r);
smoothnessG = 0.4;
highlightMult = factor + 0.2;

smoothnessD = factor * 0.5 + 0.1;

#ifdef COATED_TEXTURES
    noiseFactor = 0.77;
#endif