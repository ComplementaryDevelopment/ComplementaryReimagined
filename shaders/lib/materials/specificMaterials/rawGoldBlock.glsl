materialMask = OSIEBCA * 3.0; // Gold Fresnel
smoothnessG = pow2(pow2(color.g));
smoothnessD = 0.5 * (smoothnessG + color.b);