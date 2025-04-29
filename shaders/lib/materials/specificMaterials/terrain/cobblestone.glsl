smoothnessG = pow2(pow2(color.g)) * 1.5;
smoothnessG = min1(smoothnessG);
smoothnessD = smoothnessG;
smoothnessG = max(smoothnessG, 0.3 * color.g * float(color.g > color.b * 1.5));