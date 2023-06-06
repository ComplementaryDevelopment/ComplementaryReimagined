materialMask = OSIEBCA; // Intense Fresnel

float factor = max(color.g, 0.8);
float factor2 = pow2(factor);
float factor4 = pow2(factor2);

smoothnessG = factor - pow2(pow2(color.g)) * 0.4;
highlightMult = 3.0 * max(pow2(factor4), 0.2);

smoothnessD = factor4 * 0.75;

#if MC_VERSION < 11300
    highlightMult *= 2.0;
    smoothnessD /= 0.75;
#endif

color.rgb *= 0.7 + 0.4 * GetLuminance(color.rgb);

#ifdef COATED_TEXTURES
    noiseFactor = 0.5;
#endif