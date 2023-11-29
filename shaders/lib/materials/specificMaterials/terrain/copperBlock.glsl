materialMask = OSIEBCA * 2.0; // Copper Fresnel
smoothnessG = pow2(pow2(color.r)) + pow2(max0(color.g - color.r * 0.5)) * 0.3;
smoothnessG = min1(smoothnessG);
smoothnessD = smoothnessG;

color.rgb *= 0.6 + 0.7 * GetLuminance(color.rgb);

#ifdef COATED_TEXTURES
    noiseFactor = 0.5;
#endif