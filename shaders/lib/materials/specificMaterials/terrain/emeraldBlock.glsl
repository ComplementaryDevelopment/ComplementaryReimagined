materialMask = OSIEBCA; // Intense Fresnel

float factor = pow2(sqrt2(GetLuminance(color.rgb)));
float factor2 = pow2(factor);
float factor4 = pow2(factor2);

smoothnessG = factor - factor4 * 0.4;
highlightMult = 3.0 * factor4;

smoothnessD = factor4 * 0.75;

#ifdef COATED_TEXTURES
    noiseFactor = 0.5;
#endif