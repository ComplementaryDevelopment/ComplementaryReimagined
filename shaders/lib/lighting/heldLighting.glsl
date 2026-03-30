vec3 GetHeldLighting(vec3 playerPos, vec3 color, float emission) {
    float heldLight = heldBlockLightValue; float heldLight2 = heldBlockLightValue2;

    #ifndef IS_IRIS
        if (heldLight > 15.1) heldLight = 0.0;
        if (heldLight2 > 15.1) heldLight2 = 0.0;
    #endif

    #if COLORED_LIGHTING_INTERNAL == 0
        vec3 heldLightCol = blocklightCol; vec3 heldLightCol2 = blocklightCol;

        if (heldItemId == 45032) heldLight = 15; if (heldItemId2 == 45032) heldLight2 = 15; // Lava Bucket
    #else
        vec3 heldLightCol = GetSpecialBlocklightColor(heldItemId - 44000).rgb;
        vec3 heldLightCol2 = GetSpecialBlocklightColor(heldItemId2 - 44000).rgb;

        if (heldItemId == 45032) { heldLightCol = lavaSpecialLightColor; heldLight = 15; } // Lava Bucket
        if (heldItemId2 == 45032) { heldLightCol2 = lavaSpecialLightColor; heldLight2 = 15; }

        #if COLORED_LIGHT_SATURATION != 100
            heldLightCol = mix(blocklightCol, heldLightCol, COLORED_LIGHT_SATURATION * 0.01);
            heldLightCol2 = mix(blocklightCol, heldLightCol2, COLORED_LIGHT_SATURATION * 0.01);
        #endif
    #endif

    vec3 playerPosLightM = playerPos + relativeEyePosition;
         playerPosLightM.y += 0.7;
    float lViewPosL = length(playerPosLightM) + 6.0;
    #if HELD_LIGHTING_MODE == 1
        lViewPosL *= 1.5;
    #endif

    heldLight = pow2(pow2(heldLight * 0.47 / lViewPosL));
    heldLight2 = pow2(pow2(heldLight2 * 0.47 / lViewPosL));

    vec3 heldLighting = pow2(heldLight * DoLuminanceCorrection(heldLightCol + 0.001))
                        + pow2(heldLight2 * DoLuminanceCorrection(heldLightCol2 + 0.001));

    #if COLORED_LIGHTING_INTERNAL > 0
        AddSpecialLightDetail(heldLighting, color.rgb, emission);
    #endif

    return heldLighting;
}