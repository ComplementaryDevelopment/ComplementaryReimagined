float lColor = length(color.rgb);
smoothnessG = lColor * 0.2;
smoothnessD = lColor * 0.15;

#ifdef COATED_TEXTURES
    noiseFactor = 0.66;
#endif