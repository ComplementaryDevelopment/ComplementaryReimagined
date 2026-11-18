if (mat < 32008) {
    if (mat < 30016) {
        if (mat < 30008) {
            if (mat == 30000) { //

            } else if (mat == 30004) { //

            }
        } else {
            if (mat == 30008) { // Tinted Glass
                #ifdef CONNECTED_GLASS_EFFECT
                    uint voxelID = uint(254);
                    bool isPane = false;
                    DoConnectedGlass(colorP, color, noGeneratedNormals, playerPos, worldGeoNormal, voxelID, isPane);
                #endif
                color.a = pow(color.a, 1.0 - fresnelM);
                reflectMult = 1.0;

                #if MIRROR_TINTED_GLASS == 0
                    DoTranslucentTweaks(color, fresnelM, reflectMult, lViewPos);
                #elif MIRROR_TINTED_GLASS == 35
                    color.a = color.a * 0.65 + 0.35;
                    fresnelM = fresnelM * 0.75 + 0.25;
                    reflectMult /= color.a * 0.5 + 0.5;
                    noGeneratedNormals = true;
                #elif MIRROR_TINTED_GLASS == 70
                    color.a = color.a * 0.3 + 0.7;
                    fresnelM = fresnelM * 0.5 + 0.5;
                    reflectMult /= color.a;
                    noGeneratedNormals = true;
                #elif MIRROR_TINTED_GLASS == 100
                    color.a = 0.99;
                    fresnelM = 1.0;
                    noGeneratedNormals = true;
                #endif
            } else /*if (mat == 30012)*/ { // Slime Block
                translucentMultCalculated = true;
                reflectMult = 0.7;
                translucentMult.rgb = pow2(color.rgb) * 0.2;

                smoothnessG = color.g * 0.7;
                highlightMult = 2.5;
            }
        }
    } else {
        if (mat < 32000) {
            if (mat < 31000) {
                if (mat == 30016) { // Honey Block
                    translucentMultCalculated = true;
                    reflectMult = 1.0;
                    translucentMult.rgb = pow2(color.rgb) * 0.2;

                    smoothnessG = color.r * 0.7;
                    highlightMult = 2.5;
                } else /*if (mat == 30020)*/ { // Nether Portal
                    #if SPECIAL_PORTAL_EFFECT >= 2
                        #include "/lib/materials/specificMaterials/translucents/netherPortal.glsl"
                    #endif
                }
            } else { // (31XXX)
                if (mat % 2 == 0) { // Stained Glass
                    #ifdef CONNECTED_GLASS_EFFECT
                        uint voxelID = uint(200 + (mat - 31000) / 2);
                        bool isPane = false;
                        DoConnectedGlass(colorP, color, noGeneratedNormals, playerPos, worldGeoNormal, voxelID, isPane);
                    #endif
                    #include "/lib/materials/specificMaterials/translucents/stainedGlass.glsl"
                } else /*if (mat % 2 == 1)*/ { // Stained Glass Pane
                    #ifdef CONNECTED_GLASS_EFFECT
                        uint voxelID = uint(200 + (mat - 31000) / 2);
                        bool isPane = true;
                        DoConnectedGlass(colorP, color, noGeneratedNormals, playerPos, worldGeoNormal, voxelID, isPane);
                    #endif
                    #include "/lib/materials/specificMaterials/translucents/stainedGlass.glsl"
                    noSmoothLighting = true;
                }
            }
        } else {
            if (mat < 32004) { // Water
                #include "/lib/materials/specificMaterials/translucents/water.glsl"
            } else /*if (mat == 32004)*/ { // Ice
                smoothnessG = pow2(color.g) * color.g;
                highlightMult = pow2(min1(pow2(color.g) * 1.5)) * 3.5;

                reflectMult = 0.7;
            }
        }
    }
} else {
    if (mat < 32024) {
        if (mat < 32016) {
            if (mat == 32008) { // Glass
                #ifdef CONNECTED_GLASS_EFFECT
                    uint voxelID = uint(217);
                    bool isPane = false;
                    DoConnectedGlass(colorP, color, noGeneratedNormals, playerPos, worldGeoNormal, voxelID, isPane);
                #endif
                #include "/lib/materials/specificMaterials/translucents/glass.glsl"
            } else /*if (mat == 32012)*/ { // Glass Pane
                #ifdef CONNECTED_GLASS_EFFECT
                    uint voxelID = uint(218);
                    bool isPane = true;
                    DoConnectedGlass(colorP, color, noGeneratedNormals, playerPos, worldGeoNormal, voxelID, isPane);
                #endif
                if (color.a < 0.001 && abs(NdotU) > 0.95) discard; // Fixing artifacts on CTM/Opti connected glass panes
                #include "/lib/materials/specificMaterials/translucents/glass.glsl"
                noSmoothLighting = true;
            }
        } else {
            if (mat == 32016) { // Beacon
                #include "/lib/materials/specificMaterials/translucents/beacon.glsl"
            } else /*if (mat == 32020)*/ { //

            }
        }
    } else {
        if (mat < 32032) {
            if (mat == 32024) { //

            } else /*if (mat == 32028)*/ { //

            }
        } else {
            if (mat == 32032) { //

            } else /*if (mat == 32036)*/ { //

            }
        }
    }
}
