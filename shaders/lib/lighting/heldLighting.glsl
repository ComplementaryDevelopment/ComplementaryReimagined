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
        int heldLightId = heldItemId - 44000; // item.properties light IDs
        int heldLightId2 = heldItemId2 - 44000;
        vec3 heldLightCol = GetSpecialBlocklightColor(heldLightId).rgb;
        vec3 heldLightCol2 = GetSpecialBlocklightColor(heldLightId2).rgb;

        if (heldItemId == 45032) { heldLightCol = lavaSpecialLightColor; heldLight = 15; } // Lava Bucket
        if (heldItemId2 == 45032) { heldLightCol2 = lavaSpecialLightColor; heldLight2 = 15; }

        #ifdef INCLUDE_VOXELIZATION
            // The shadow pass passes every held light source through a reserved voxel texel, see HELD_ITEM_VOXEL_OFFSET.
            // This is to make the held-item light smooth instead of jumping between voxels
            int heldVoxelLightId = int(texelFetch(voxel_sampler, HELD_ITEM_VOXEL_TEXEL, 0).x & 32767u) - int(HELD_ITEM_VOXEL_OFFSET);
            // Skip items item.properties already handles, they would be lit twice
            if (heldVoxelLightId > 1 && heldVoxelLightId < 200 && heldVoxelLightId != heldLightId && heldVoxelLightId != heldLightId2) {
                vec4 heldVoxelColor = GetSpecialBlocklightColor(heldVoxelLightId);
                // Modded blocks which are not added to item.properties would not be catched above and have no alpha, so we force it to 1.0 to make them emit light.
                float heldVoxelAlpha = heldVoxelColor.a > 0.0 ? heldVoxelColor.a : 1.0;

                // This falloff seemed about right based on the voxel alpha
                float heldVoxelReach = 6.0 * pow(heldVoxelAlpha, 0.5);
                float heldVoxelLight = (6.0 + heldVoxelReach) * 1.196;
                if (heldLight <= 0.0) {
                    heldLight = heldVoxelLight;
                    heldLightCol = heldVoxelColor.rgb;
                } else if (heldLight2 <= 0.0) {
                    heldLight2 = heldVoxelLight;
                    heldLightCol2 = heldVoxelColor.rgb;
                }
            }
        #endif

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

    vec3 heldLighting = pow2(heldLight * DoLuminanceCorrection(heldLightCol))
                        + pow2(heldLight2 * DoLuminanceCorrection(heldLightCol2));

    #if COLORED_LIGHTING_INTERNAL > 0
        AddSpecialLightDetail(heldLighting, color.rgb, emission);
    #endif

    return heldLighting;
}
