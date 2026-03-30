smoothnessG = dot(color.rgb, color.rgb) * 0.17;
smoothnessD = smoothnessG;
smoothnessG = max(smoothnessG, 0.3 * color.g * float(color.g > color.b * 1.5));