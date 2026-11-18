vec3 GetHeldLighting(vec3 playerPos, vec3 color, float emission) {
    float heldLight = heldBlockLightValue; float heldLight2 = heldBlockLightValue2;

    #ifndef IS_IRIS
        if (heldLight > 15.1) heldLight = 0.0;
        if (heldLight2 > 15.1) heldLight2 = 0.0;
    #endif

    #if COLORED_LIGHTING_INTERNAL == 0
        if (heldItemId == 44013) heldLight = 15; if (heldItemId2 == 44013) heldLight2 = 15; // Lava Bucket

        vec3 heldLightCol = blocklightCol; vec3 heldLightCol2 = blocklightCol;
    #else
        vec4 specialHeldLightCol = GetSpecialBlocklightColor(heldItemId - 44000);
        vec4 specialHeldLightCol2 = GetSpecialBlocklightColor(heldItemId2 - 44000);

        vec3 heldLightCol = specialHeldLightCol.rgb;
        vec3 heldLightCol2 = specialHeldLightCol2.rgb;

        if (specialHeldLightCol.a > 0.0) heldLight = min(15.0, heldLight + 15.0 * sqrt3(max(specialHeldLightCol.a, 0.1)));
        if (specialHeldLightCol2.a > 0.0) heldLight2 = min(15.0, heldLight2 + 15.0 * sqrt3(max(specialHeldLightCol2.a, 0.1)));

        #if COLORED_LIGHT_SATURATION != 100
            heldLightCol = mix(blocklightCol, heldLightCol, COLORED_LIGHT_SATURATION * 0.01);
            heldLightCol2 = mix(blocklightCol, heldLightCol2, COLORED_LIGHT_SATURATION * 0.01);
        #endif

        // Color Balance / consistencyCB72412HF
        heldLightCol = 0.13 * DoLuminanceCorrection(heldLightCol + blocklightCol * 0.05);
        heldLightCol2 = 0.13 * DoLuminanceCorrection(heldLightCol2 + blocklightCol * 0.05);
    #endif

    vec3 playerPosLightM = playerPos + relativeEyePosition;
    playerPosLightM.y += 0.7;
    float lViewPosL = length(playerPosLightM) * 1.33;

    heldLight = GetTweakedSmoothLightmap(max0(heldLight - lViewPosL) * 0.065);
    heldLight2 = GetTweakedSmoothLightmap(max0(heldLight2 - lViewPosL) * 0.065);

    vec3 heldLighting = pow2(heldLight * heldLightCol) + pow2(heldLight2 * heldLightCol2);

    #if HELD_LIGHTING_MODE == 1 // Subtle
        heldLighting *= 0.065;
    #endif

    #ifdef GBUFFERS_ENTITIES
        if (entityId == 50016 || entityId == 50017) { // Player or Current Player
            heldLighting *= 0.65;
        }
    #endif

    #if COLORED_LIGHTING_INTERNAL > 0
        AddSpecialLightDetail(heldLighting, color.rgb, emission);
    #endif

    return heldLighting;
}
