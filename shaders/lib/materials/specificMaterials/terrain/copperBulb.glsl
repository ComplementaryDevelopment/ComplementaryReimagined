noSmoothLighting = true;

vec3 hsvColor = rgb2hsv(color.rgb);
if (abs(hsvColor.r - 0.09722) < 0.04305 && hsvColor.b > 0.7) { // Active Light Part
    smoothnessG = 0.75;
    smoothnessD = 0.35;

    float blockRes = absMidCoordPos.x * atlasSize.x;
    vec2 signMidCoordPosM = (floor((signMidCoordPos + 1.0) * blockRes) + 0.5) / blockRes - 1.0;
    float dotsignMidCoordPos = dot(signMidCoordPosM, signMidCoordPosM);
    float lBlockPosM = pow2(max0(1.0 - 1.7 * pow2(pow2(dotsignMidCoordPos))));

    emission = pow2(lmCoordM.x) + 0.3 * color.r;
    emission *= (0.7 + 2.0 * pow2(lBlockPosM));
} else if (color.r > 2.5 * (color.g + color.b)) { // Middle Redstone Part
    emission = 4.0;
    color.rgb *= color.rgb;
} else { // Copper Base
    #include "/lib/materials/specificMaterials/terrain/copperBlock.glsl"
}