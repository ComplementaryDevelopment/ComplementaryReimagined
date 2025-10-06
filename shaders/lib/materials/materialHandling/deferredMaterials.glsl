if (materialMaskInt <= 240) {
    #ifdef IPBR
        #include "/lib/materials/materialHandling/deferredIPBR.glsl"
    #elif defined CUSTOM_PBR
        #if RP_MODE == 2 // seuspbr
            float metalness = materialMaskInt / 240.0;

            intenseFresnel = metalness;
        #elif RP_MODE == 3 // labPBR
            float metalness = float(materialMaskInt >= 215);

            intenseFresnel = materialMaskInt / 240.0;
        #endif
        reflectColor = mix(vec3(1.0), color.rgb / (max(color.r, max(color.g, color.b)) + 0.00001), metalness);
    #endif
} else {
    if (materialMaskInt == 254) { // No SSAO, No TAA
        ssao = 1.0;
        entityOrHand = true;
    }
}