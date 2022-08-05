materialMask = OSIEBCA; // Intense Fresnel

float factor = color.r * 1.5;

smoothnessG = factor;
highlightMult = 2.0 + min1(smoothnessG * 2.0) * 1.5;
smoothnessG = min1(smoothnessG);

smoothnessD = min1(factor + 0.07);

#ifdef COATED_TEXTURES
    noiseFactor = 1.25;
#endif