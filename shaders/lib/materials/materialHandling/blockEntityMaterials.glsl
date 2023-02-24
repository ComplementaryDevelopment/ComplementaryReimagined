if (blockEntityId > 1) {
    if (blockEntityId < 60012) {
        if (blockEntityId < 60004) {
            if (blockEntityId == 10548) { // Enchanting Table:Book
                smoothnessG = pow2(color.g) * 0.35;

                if (color.b < 0.0001 && color.r > color.g) {
                    emission = color.g * 4.0;
                }
            } else if (blockEntityId == 60000) { // End Portal, End Gateway
                #include "/lib/materials/specificMaterials/others/endPortalEffect.glsl"
            }
        } else {
            if (blockEntityId == 60004) { // Signs
                noSmoothLighting = true;

                if (glColor.r + glColor.g + glColor.b <= 2.99 || lmCoord.x > 0.999) { // Sign Text
                    #include "/lib/materials/specificMaterials/others/signText.glsl"
                }

                #ifdef COATED_TEXTURES
                    noiseFactor = 0.66;
                #endif
            } else /*if (blockEntityId == 60008)*/ { // Chest
                noSmoothLighting = true;

                smoothnessG = pow2(color.g);

                #ifdef COATED_TEXTURES
                    noiseFactor = 0.66;
                #endif
            }
        }
    } else {
        if (blockEntityId < 60020) {
            if (blockEntityId == 60012) { // Ender Chest
                noSmoothLighting = true;

                float factor = min(pow2(color.g), 0.25);
                smoothnessG = factor * 2.0;

                if (color.g > color.r || color.b > color.g)
                    emission = pow2(factor) * 20.0;
                emission += 0.35;
                
                #ifdef COATED_TEXTURES
                    noiseFactor = 0.66;
                #endif
            } else /*if (blockEntityId == 60016)*/ { // Shulker Box+, Banner+, Head+, Bed+
                noSmoothLighting = true;
                #ifdef COATED_TEXTURES
                    noiseFactor = 0.2;
                #endif
            }
        } else {
            if (blockEntityId == 60020) { // Conduit
                noSmoothLighting = true;
                lmCoordM.x = 0.9;

                if (color.b > color.r) { // Conduit:Wind, Conduit:Blue Pixels of The Eye
                    emission = color.r * 16.0;
                } else if (color.r > color.b * 2.5) { // Conduit:Red Pixels of The Eye
                    emission = 20.0;
                    color.rgb *= vec3(1.0, 0.25, 0.1);
                }
            } else /*if (blockEntityId == 60024)*/ { //
            
            }
        }
    }
}