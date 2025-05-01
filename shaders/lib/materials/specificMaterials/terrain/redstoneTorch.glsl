if (color.r > 0.65) {
    emission = (3.5 - 2.25 * color.g) * 0.97;
    color.rgb *= color.rgb;

    #if MC_VERSION >= 12102 // redstone torch model got changed in 1.21.2
        color.gb = max(color.gb * vec2(0.75, 0.5), pow2(color.gb));
    #endif
} else if (color.r > color.g * 2.0) {
    materialMask = OSIEBCA * 5.0; // Redstone Fresnel

    float factor = pow2(color.r);
    smoothnessG = 0.4;
    highlightMult = factor + 0.4;

    smoothnessD = factor * 0.7 + 0.3;
}