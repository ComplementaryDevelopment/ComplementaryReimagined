if (color.g < 0.05 && color.b > 0.3) {
    smoothnessG = 0.4;
    highlightMult = 1.5;
    smoothnessD = 0.3;

    emission = 0.9 + pow2(pow2(pow2(color.b))) * 10.0;
    color.r *= 1.15;
} else {
    #include "/lib/materials/specificMaterials/obsidian.glsl"
}