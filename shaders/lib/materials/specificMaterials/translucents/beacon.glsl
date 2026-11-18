lmCoordM.x = 0.88;

translucentMultCalculated = true;
translucentMult = vec4(0.0, 0.0, 0.0, 1.0);

if (color.b > 0.5) {
    if (color.g - color.b < 0.01 && color.g < 0.99) {
        #ifdef GBUFFERS_WATER
            #include "/lib/materials/specificMaterials/translucents/glass.glsl"
        #endif
    } else { // Beacon:Center
        lmCoordM = vec2(0.0);
        noDirectionalShading = true;

        float lColor = length(color.rgb);
        vec3 baseColor = vec3(0.1, 1.0, 0.92);
        if (lColor > 1.65)      color.rgb = baseColor + 0.2;
        else if (lColor > 1.5)  color.rgb = baseColor + 0.15;
        else if (lColor > 1.3)  color.rgb = baseColor + 0.08;
        else if (lColor > 1.15) color.rgb = baseColor + 0.035;
        else                    color.rgb = baseColor;
        emission = 3.5;
    }
} else { // Beacon:Obsidian
    float factor = color.r * 1.5;

    smoothnessG = factor;
    highlightMult = 2.0 + min1(smoothnessG * 2.0) * 1.5;
    smoothnessG = min1(smoothnessG);
}
