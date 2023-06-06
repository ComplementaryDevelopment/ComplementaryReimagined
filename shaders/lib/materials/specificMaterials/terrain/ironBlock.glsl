materialMask = OSIEBCA; // Intense Fresnel
smoothnessG = pow2(pow2(color.r));
highlightMult = smoothnessG * 3.0;
smoothnessD = smoothnessG;

color.rgb *= 0.6 + 0.5 * GetLuminance(color.rgb);

#ifdef COATED_TEXTURES
    noiseFactor = 0.33;
#endif