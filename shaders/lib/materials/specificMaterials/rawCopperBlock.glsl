materialMask = OSIEBCA * 2.0; // Copper Fresnel
smoothnessG = pow2(color.r + color.g * 0.25) * 0.4;
smoothnessG = min1(smoothnessG);
smoothnessD = min1(smoothnessG * smoothnessG * 2.0);