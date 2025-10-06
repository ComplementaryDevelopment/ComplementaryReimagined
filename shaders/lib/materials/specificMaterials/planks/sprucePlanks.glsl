smoothnessG = pow2(dot(color.rgb, vec3(0.3)));
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.66;
#endif