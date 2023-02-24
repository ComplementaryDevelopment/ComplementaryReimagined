smoothnessG = pow2(pow2(color.g));
smoothnessD = smoothnessG;
smoothnessG = max(smoothnessG, 0.3 * color.g * float(color.g > color.b * 1.5));