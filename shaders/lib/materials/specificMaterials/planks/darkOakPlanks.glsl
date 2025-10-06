smoothnessG = dot(color.rgb, vec3(0.2));
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.66;
#endif