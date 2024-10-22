smoothnessG = color.g;
smoothnessD = color.g;

emission = min(max0(dot(color.rgb, color.rgb) - 1.0) * 6.0, 1.0);