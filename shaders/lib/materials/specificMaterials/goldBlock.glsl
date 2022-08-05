materialMask = OSIEBCA * 3.0; // Gold Fresnel

float colorG2 = pow2(color.g);
float colorG4 = pow2(colorG2);
float factor = max(color.g, 0.8);

smoothnessG = min1(factor - colorG4 * 0.5);
highlightMult = 3.5 * colorG2;

smoothnessD = colorG4;

color.rgb *= 0.9;

#ifdef COATED_TEXTURES
    noiseFactor = 0.33;
#endif