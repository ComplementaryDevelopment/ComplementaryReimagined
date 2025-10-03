materialMask = OSIEBCA; // Intense Fresnel
float factor = pow2(color.r);
smoothnessG = 0.8 - factor * 0.3;
highlightMult = factor * 3.0;
smoothnessD = factor;