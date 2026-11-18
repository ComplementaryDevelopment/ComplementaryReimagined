smoothnessG = color.g;
smoothnessD = color.g;

float factor = min(dot(color.rgb, color.rgb), 2.5);
emission = min(max0(factor - 1.0) * 6.0, 1.0);

#ifdef COLORED_DYNAMIC_LIGHTING
    emission *= 0.5 + 0.5 * pow2(pow2(factor)) * 0.2;
#endif
