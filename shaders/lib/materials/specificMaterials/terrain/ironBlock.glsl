#ifdef GBUFFERS_TERRAIN
    smoothnessG = pow2(pow2(color.r));
#else
    smoothnessG = pow2(color.r);
#endif
highlightMult = smoothnessG * 3.0;
smoothnessD = smoothnessG;
materialMask = OSIEBCA; // Intense Fresnel

color.rgb *= 0.6 + 0.5 * GetLuminance(color.rgb);

#ifdef COATED_TEXTURES
    noiseFactor = 0.33;
#endif