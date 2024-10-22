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
                color.a = pow(color.a, 1.0 - fresnel * 0.65);
                reflectMult = 0.75;
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
                    #ifdef SPECIAL_PORTAL_EFFECTS
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
            if (mat == 32000) { // Water
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
                lmCoordM.x = 0.88;

                translucentMultCalculated = true;
                translucentMult = vec4(0.0, 0.0, 0.0, 1.0);

                if (color.b > 0.5) {
                    if (color.g - color.b < 0.01 && color.g < 0.99) {
                        #include "/lib/materials/specificMaterials/translucents/glass.glsl"
                    } else { // Beacon:Center
                        lmCoordM = vec2(0.0);
                        noDirectionalShading = true;

                        float lColor = length(color.rgb);
                        vec3 baseColor = vec3(0.1, 1.0, 0.92);
                        if (lColor > 1.5)       color.rgb = baseColor + 0.22;
                        else if (lColor > 1.3)  color.rgb = baseColor + 0.15;
                        else if (lColor > 1.15) color.rgb = baseColor + 0.09;
                        else                    color.rgb = baseColor + 0.05;
                        emission = 4.0;
                    }
                } else { // Beacon:Obsidian
                    float factor = color.r * 1.5;

                    smoothnessG = factor;
                    highlightMult = 2.0 + min1(smoothnessG * 2.0) * 1.5;
                    smoothnessG = min1(smoothnessG);
                }

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