int mat = currentRenderedItemId;

#ifdef GBUFFERS_HAND
    float lViewPos = 0.0;
#endif

int subsurfaceMode;
bool noDirectionalShading, noVanillaAO, centerShadowBias;
float noPuddles;

if (currentRenderedItemId < 45000) {
    #include "/lib/materials/materialHandling/terrainMaterials.glsl"
} else

if (currentRenderedItemId < 45064) {
    if (currentRenderedItemId < 45032) {
        if (currentRenderedItemId < 45016) {
            if (currentRenderedItemId < 45008) {
                if (currentRenderedItemId == 45000) { // Armor Trims
                    smoothnessG = 0.5;
                    highlightMult = 2.0;
                    smoothnessD = 0.5;

                    #ifdef GLOWING_ARMOR_TRIM
                        emission = 1.5;
                    #endif
                } else if (currentRenderedItemId == 45004) { // Wooden Tools, Bow, Fishing Rod
                    #include "/lib/materials/specificMaterials/planks/sprucePlanks.glsl"
                    smoothnessG = min(smoothnessG, 0.4);
                    smoothnessD = smoothnessG;
                }
            } else {
                if (currentRenderedItemId == 45008) { // Stone Tools
                    if (CheckForStick(color.rgb)) {
                        #include "/lib/materials/specificMaterials/planks/sprucePlanks.glsl"
                    } else {
                        #include "/lib/materials/specificMaterials/terrain/stone.glsl"
                    }
                } else /*if (currentRenderedItemId == 45012)*/ { // Iron Tools, Iron Armor, Iron Ingot, Iron Nugget, Iron Horse Armor, Flint and Steel, Flint, Spyglass, Shears, Chainmail Armor
                    if (CheckForStick(color.rgb)) {
                        #include "/lib/materials/specificMaterials/planks/sprucePlanks.glsl"
                    } else {
                        #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"
                    }
                }
            }
        } else {
            if (currentRenderedItemId < 45024) {
                if (currentRenderedItemId == 45016) { // Golden Tools, Golden Armor, Gold Ingot, Gold Nugget, Golden Apple, Enchanted Golden Apple, Golden Carrot, Golden Horse Armor, Copper Ingot
                    if (CheckForStick(color.rgb)) {
                        #include "/lib/materials/specificMaterials/planks/sprucePlanks.glsl"
                    } else {
                        #include "/lib/materials/specificMaterials/terrain/goldBlock.glsl"
                    }
                } else /*if (currentRenderedItemId == 45020)*/ { // Diamond Tools, Diamond Armor, Diamond, Diamond Horse Armor, Emerald
                    if (CheckForStick(color.rgb)) {
                        #include "/lib/materials/specificMaterials/planks/sprucePlanks.glsl"
                    } else {
                        #include "/lib/materials/specificMaterials/terrain/diamondBlock.glsl"
                    }
                }
            } else {
                if (currentRenderedItemId == 45024) { // Netherite Tools, Netherite Armor, Netherite Ingot
                    materialMask = OSIEBCA; // Intense Fresnel
                    smoothnessG = color.r * 1.5;
                    smoothnessG = min1(smoothnessG);
                    highlightMult = smoothnessG * 2.0;
                    smoothnessD = smoothnessG * smoothnessG * 0.5;

                    #ifdef COATED_TEXTURES
                        noiseFactor = 0.33;
                    #endif
                } else /*if (currentRenderedItemId == 45028)*/ { // Trident Item
                    #include "/lib/materials/specificMaterials/others/trident.glsl"
                }
            }
        }
    } else {
        if (currentRenderedItemId < 45048) {
            if (currentRenderedItemId < 45040) {
                if (currentRenderedItemId == 45032) { // Lava Bucket
                    if (color.r + color.g > color.b * 2.0) {
                        emission = color.r + color.g - color.b * 1.5;
                        emission *= 1.8;
                        color.rg += color.b * vec2(0.4, 0.15);
                        color.b *= 0.8;
                    } else {
                        #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"
                    }
                } else /*if (currentRenderedItemId == 45036)*/ { // Bucket++
                    if (GetMaxColorDif(color.rgb) < 0.01) {
                        #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"
                    } else {
                        float factor = color.b;
                        smoothnessG = factor;
                        highlightMult = factor * 2.0;
                        smoothnessD = factor;
                    }
                }
            } else {
                if (currentRenderedItemId == 45040) { // Blaze Rod, Blaze Powder
                    noSmoothLighting = false;
                    lmCoordM.x = 0.85;
                    emission = color.g;
                    color.rgb = sqrt1(color.rgb);
                } else /*if (currentRenderedItemId == 45044)*/ { // Bottle o' Enchanting, Glow Inc Sac
                    emission = color.b * 2.0;
                }
            }
        } else {
            if (currentRenderedItemId < 45056) {
                if (currentRenderedItemId == 45048) { // Fire Charge
                    emission = max0(color.r + color.g - color.b * 0.5);
                } else /*if (currentRenderedItemId == 45052)*/ { // Chorus Fruit
                    emission = max0(color.b * 2.0 - color.r) * 1.5;
                }
            } else {
                if (currentRenderedItemId == 45056) { // Amethyst Shard
                    materialMask = OSIEBCA; // Intense Fresnel
                    float factor = pow2(color.r);
                    smoothnessG = 0.8 - factor * 0.3;
                    highlightMult = factor * 3.0;
                    smoothnessD = factor;
                } else /*if (currentRenderedItemId == 45060)*/ { // Shield
                    float factor = min(color.r * color.g * color.b * 4.0, 0.7) * 0.7;
                    smoothnessG = factor;
                    highlightMult = factor * 3.0;
                    smoothnessD = factor;
                }
            }
        }
    }
} else {
    if (currentRenderedItemId < 45096) {
        if (currentRenderedItemId < 45080) {
            if (currentRenderedItemId < 45072) {
                if (currentRenderedItemId == 45064) { // Turtle Shell
                    float factor = color.g * 0.7;
                    smoothnessG = factor;
                    highlightMult = factor * 3.0;
                    smoothnessD = factor;
                } else /*if (currentRenderedItemId == 45068)*/ { // Ender Pearl
                    smoothnessG = 1.0;
                    highlightMult = 2.0;
                    smoothnessD = 1.0;
                }
            } else {
                if (currentRenderedItemId == 45072) { // Eye of Ender
                    smoothnessG = 1.0;
                    highlightMult = 2.0;
                    smoothnessD = 1.0;
                    emission = max0(color.g - color.b * 0.25);
                    color.rgb = pow(color.rgb, vec3(1.0 - 0.75 * emission));
                } else /*if (currentRenderedItemId == 45076)*/ { // Clock
                    if (
                        CheckForColor(color.rgb, vec3(255, 255, 0)) ||
                        CheckForColor(color.rgb, vec3(204, 204, 0)) ||
                        CheckForColor(color.rgb, vec3(73, 104, 216)) ||
                        CheckForColor(color.rgb, vec3(58, 83, 172)) ||
                        CheckForColor(color.rgb, vec3(108, 108, 137)) ||
                        CheckForColor(color.rgb, vec3(86, 86, 109))
                    ) {
                        emission = 1.0;
                        color.rgb += vec3(0.1);
                    }

                    #include "/lib/materials/specificMaterials/terrain/goldBlock.glsl"
                }
            }
        } else {
            if (currentRenderedItemId < 45088) {
                if (currentRenderedItemId == 45080) { // Compass
                    if (color.r - 0.1 > color.b + color.g) {
                        emission = color.r * 1.5;
                    }

                    #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"
                } else /*if (currentRenderedItemId == 45084)*/ { // Echo Shard, Recovery Compass, Music Disc 5
                    emission = max0(color.b + color.g - color.r * 2.0);

                    #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"
                }
            } else {
                if (currentRenderedItemId == 45088) { // Nether Star
                    emission = pow2(color.r + color.g) * 0.5;
                } else /*if (currentRenderedItemId == 45092)*/ { // End Crystal
                    if (color.g < color.r) {
                        emission = 3.0;
                        color.r *= 1.1;
                    }
                }
            }
        }
    } else {
        if (currentRenderedItemId < 45112) {
            if (currentRenderedItemId < 45104) {
                if (currentRenderedItemId == 45096) { // Glow Berries
                    // iris needs to add support
                } else /*if (currentRenderedItemId == 45100)*/ { // Glowstone Dust
                    emission = dot(color.rgb, color.rgb) * 0.5 + 1.0;
                }
            } else {
                if (currentRenderedItemId == 45104) { // Prismarine Crystals
                    emission = pow1_5(color.r) * 2.5 + 0.2;
                } else /*if (currentRenderedItemId == 45108)*/ { // Totem of Undying
                    #include "/lib/materials/specificMaterials/terrain/goldBlock.glsl"
                }
            }
        } else {
            if (currentRenderedItemId < 45120) {
                if (currentRenderedItemId == 45112) { // Trial Key
                    emission = max0(color.r - color.b) * 3.0;
                    color.rgb = pow(color.rgb, vec3(1.0 + 0.5 * sqrt(emission)));
                } else /*if (currentRenderedItemId == 45116)*/ { //

                }
            } else {
                if (currentRenderedItemId == 45120) { //

                } else /*if (currentRenderedItemId == 45124)*/ { //

                }
            }
        }
    }
}