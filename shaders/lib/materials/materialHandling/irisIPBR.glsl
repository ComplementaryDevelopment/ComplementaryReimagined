int mat = currentRenderedItemId;

#ifdef GBUFFERS_HAND
    float lViewPos = 0.0;
#endif

int subsurfaceMode;
bool centerShadowBias;
float noPuddles;

if (currentRenderedItemId < 45000) {
    #include "/lib/materials/materialHandling/terrainIPBR.glsl"
} else

if (currentRenderedItemId < 45128) {
    if (currentRenderedItemId < 45064) {
        if (currentRenderedItemId < 45032) {
            if (currentRenderedItemId < 45016) {
                if (currentRenderedItemId < 45008) {
                    if (currentRenderedItemId < 45004) { // Armor Trims
                        smoothnessG = 0.5;
                        highlightMult = 2.0;
                        smoothnessD = 0.5;

                        #ifdef GLOWING_ARMOR_TRIM
                            emission = 1.0;
                        #endif

                        #if HIDE_ARMOR > 0 && defined GBUFFERS_ENTITIES
                            HideArmorDontSkip(color, playerPos);
                        #endif
                    } else { // Wooden Tools, Bow, Fishing Rod
                        #include "/lib/materials/specificMaterials/planks/sprucePlanks.glsl"
                        smoothnessG = min(smoothnessG, 0.4);
                        smoothnessD = smoothnessG;
                    }
                } else {
                    if (currentRenderedItemId < 45012) { // Stone Tools
                        if (CheckForStick(color.rgb)) {
                            #include "/lib/materials/specificMaterials/planks/sprucePlanks.glsl"
                        } else {
                            #include "/lib/materials/specificMaterials/terrain/stone.glsl"
                        }
                    } else { // Iron Tools, Iron Armor, Iron Ingot, Iron Nugget, Iron Horse Armor, Flint and Steel, Flint, Spyglass, Shears, Chainmail Armor
                        if (CheckForStick(color.rgb)) {
                            #include "/lib/materials/specificMaterials/planks/sprucePlanks.glsl"
                        } else {
                            #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"
                        }

                        #if HIDE_ARMOR > 0 && defined GBUFFERS_ENTITIES
                            if (currentRenderedItemId == 45013) { // Iron Armor, Chainmail Armor
                                HideArmor(color, playerPos);
                            }
                        #endif
                    }
                }
            } else {
                if (currentRenderedItemId < 45024) {
                    if (currentRenderedItemId < 45020) { // Golden Tools, Golden Armor, Gold Ingot, Gold Nugget, Golden Apple, Enchanted Golden Apple, Golden Carrot, Golden Horse Armor
                        if (CheckForStick(color.rgb)) {
                            #include "/lib/materials/specificMaterials/planks/sprucePlanks.glsl"
                        } else {
                            #include "/lib/materials/specificMaterials/terrain/goldBlock.glsl"
                        }

                        #if HIDE_ARMOR > 0 && defined GBUFFERS_ENTITIES
                            if (currentRenderedItemId == 45017) { // Gold Armor
                                HideArmor(color, playerPos);
                            }
                        #endif
                    } else { // Diamond Tools, Diamond Armor, Diamond, Diamond Horse Armor, Emerald
                        if (CheckForStick(color.rgb)) {
                            #include "/lib/materials/specificMaterials/planks/sprucePlanks.glsl"
                        } else {
                            #include "/lib/materials/specificMaterials/terrain/diamondBlock.glsl"
                        }

                        #if HIDE_ARMOR > 0 && defined GBUFFERS_ENTITIES
                            if (currentRenderedItemId == 45021) { // Diamond Armor
                                HideArmor(color, playerPos);
                            }
                        #endif
                    }
                } else {
                    if (currentRenderedItemId < 45028) { // Netherite Tools, Netherite Armor, Netherite Ingot
                        materialMask = OSIEBCA; // Intense Fresnel
                        smoothnessG = color.b * 1.65;
                        smoothnessG = min1(smoothnessG);
                        highlightMult = smoothnessG * 2.0;
                        smoothnessD = smoothnessG * smoothnessG * 0.5;

                        #ifdef COATED_TEXTURES
                            noiseFactor = 0.33;
                        #endif

                        #if HIDE_ARMOR > 0 && defined GBUFFERS_ENTITIES
                            if (currentRenderedItemId == 45025) { // Netherite Armor
                                HideArmor(color, playerPos);
                            }
                        #endif
                    } else { // Trident Item
                        #include "/lib/materials/specificMaterials/others/trident.glsl"
                    }
                }
            }
        } else {
            if (currentRenderedItemId < 45048) {
                if (currentRenderedItemId < 45040) {
                    if (currentRenderedItemId < 45036) { // Lava Bucket
                        if (color.r + color.g > color.b * 2.0) {
                            emission = color.r + color.g - color.b * 1.5;
                            emission *= 1.8;
                            color.rg += color.b * vec2(0.4, 0.15);
                            color.b *= 0.8;
                        } else {
                            #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"
                        }
                    } else { // Bucket++
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
                    if (currentRenderedItemId < 45044) { // Blaze Rod, Blaze Powder
                        noSmoothLighting = false;
                        lmCoordM.x = 0.85;
                        emission = color.g;
                        color.rgb = sqrt1(color.rgb);
                    } else { // Bottle o' Enchanting, Glow Inc Sac
                        emission = color.b * 2.0;
                    }
                }
            } else {
                if (currentRenderedItemId < 45056) {
                    if (currentRenderedItemId < 45052) { // Fire Charge
                        emission = max0(color.r + color.g - color.b * 0.5);
                    } else { // Chorus Fruit
                        emission = max0(color.b * 2.0 - color.r) * 1.5;
                    }
                } else {
                    if (currentRenderedItemId < 45060) { // Amethyst Shard
                        materialMask = OSIEBCA; // Intense Fresnel
                        float factor = pow2(color.r);
                        smoothnessG = 0.8 - factor * 0.3;
                        highlightMult = factor * 3.0;
                        smoothnessD = factor;
                    } else { // Shield
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
                    if (currentRenderedItemId < 45068) { // Turtle Shell
                        float factor = color.g * 0.7;
                        smoothnessG = factor;
                        highlightMult = factor * 3.0;
                        smoothnessD = factor;

                        #if HIDE_ARMOR > 0 && defined GBUFFERS_ENTITIES
                            HideArmor(color, playerPos);
                        #endif
                    } else { // Ender Pearl
                        smoothnessG = 1.0;
                        highlightMult = 2.0;
                        smoothnessD = 1.0;
                    }
                } else {
                    if (currentRenderedItemId < 45076) { // Eye of Ender
                        smoothnessG = 1.0;
                        highlightMult = 2.0;
                        smoothnessD = 1.0;
                        emission = max0(color.g - color.b * 0.25);
                        color.rgb = pow(color.rgb, vec3(1.0 - 0.75 * emission));
                    } else { // Clock
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
                    if (currentRenderedItemId < 45084) { // Compass
                        if (color.r - 0.1 > color.b + color.g) {
                            emission = color.r * 1.5;
                        }

                        #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"
                    } else { // Echo Shard, Recovery Compass, Music Disc 5
                        emission = max0(color.b + color.g - color.r * 2.0);

                        #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"
                    }
                } else {
                    if (currentRenderedItemId < 45092) { // Nether Star
                        emission = pow2(color.r + color.g) * 0.5;
                    } else { // End Crystal
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
                    if (currentRenderedItemId < 45100) { // Glow Berries
                        // iris needs to add support
                    } else { // Glowstone Dust
                        emission = dot(color.rgb, color.rgb) * 0.5 + 1.0;
                    }
                } else {
                    if (currentRenderedItemId < 45108) { // Prismarine Crystals
                        emission = pow1_5(color.r) * 2.5 + 0.2;
                    } else { // Totem of Undying
                        #include "/lib/materials/specificMaterials/terrain/goldBlock.glsl"
                    }
                }
            } else {
                if (currentRenderedItemId < 45120) {
                    if (currentRenderedItemId < 45116) { // Trial Key, Ominous Trial Key
                        emission = abs(color.r - color.b) * 3.0;
                        color.rgb = pow(color.rgb, vec3(1.0 + 0.5 * sqrt(emission)));
                    } else { // Copper Tools, Copper Armor, Copper Ingot, Copper Horse Armor
                        #include "/lib/materials/specificMaterials/terrain/copperBlock.glsl"

                        smoothnessD *= 0.5;

                        #if HIDE_ARMOR > 0 && defined GBUFFERS_ENTITIES
                            if (currentRenderedItemId == 45117) { // Copper Armor
                                HideArmor(color, playerPos);
                            }
                        #endif
                    }
                } else {
                    if (currentRenderedItemId < 45124) { // Ghast Harness+
                        vec2 tSize = textureSize(tex, 0);
                        vec4 checkColorOneDown = texelFetch(tex, ivec2(texCoord * tSize) + ivec2(0, 1), 0);
                        if (
                            CheckForColor(color.rgb, vec3(139, 193, 205)) ||
                            CheckForColor(color.rgb, vec3(208, 234, 233)) ||
                            CheckForColor(color.rgb, vec3(109, 152, 161)) ||
                            CheckForColor(color.rgb, vec3(255)) && CheckForColor(checkColorOneDown.rgb, vec3(109, 152, 161)) ||
                            CheckForColor(color.rgb, vec3(168, 208, 217))
                        ) {
                            smoothnessG = 1.0;
                            highlightMult = 2.0 - dot(color.rgb, vec3(0.25));
                            smoothnessD = 1.0;
                        }
                    } else { // Elytra
                        #if HIDE_ARMOR > 0 && defined GBUFFERS_ENTITIES
                            HideElytra(color, playerPos);
                        #endif
                    }
                }
            }
        }
    }
} else {
    if (currentRenderedItemId < 45192) {
        if (currentRenderedItemId < 45160) {
            if (currentRenderedItemId < 45144) {
                if (currentRenderedItemId < 45136) {
                    if (currentRenderedItemId < 45132) { // Leather Armor
                        #if HIDE_ARMOR > 0 && defined GBUFFERS_ENTITIES
                            HideArmor(color, playerPos);
                        #endif
                    } else { // 45132 to 45136
                        // 45132
                        // 45133
                        // 45134
                        // 45135
                    }
                } else {
                    if (currentRenderedItemId < 45140) { // 45136 to 45140
                        // 45136
                        // 45137
                        // 45138
                        // 45139
                    } else { // 45140 to 45144
                        // 45140
                        // 45141
                        // 45142
                        // 45143
                    }
                }
            } else {
                if (currentRenderedItemId < 45152) {
                    if (currentRenderedItemId < 45148) { // 45144 to 45148
                        // 45144
                        // 45145
                        // 45146
                        // 45147
                    } else { // 45148 to 45152
                        // 45148
                        // 45149
                        // 45150
                        // 45151
                    }
                } else {
                    if (currentRenderedItemId < 45156) { // 45152 to 45156
                        // 45152
                        // 45153
                        // 45154
                        // 45155
                    } else { // 45156 to 45160
                        // 45156
                        // 45157
                        // 45158
                        // 45159
                    }
                }
            }
        } else {
            if (currentRenderedItemId < 45176) {
                if (currentRenderedItemId < 45168) {
                    if (currentRenderedItemId < 45164) { // 45160 to 45164
                        // 45160
                        // 45161
                        // 45162
                        // 45163
                    } else { // 45164 to 45168
                        // 45164
                        // 45165
                        // 45166
                        // 45167
                    }
                } else {
                    if (currentRenderedItemId < 45172) { // 45168 to 45172
                        // 45168
                        // 45169
                        // 45170
                        // 45171
                    } else { // 45172 to 45176
                        // 45172
                        // 45173
                        // 45174
                        // 45175
                    }
                }
            } else {
                if (currentRenderedItemId < 45184) {
                    if (currentRenderedItemId < 45180) { // 45176 to 45180
                        // 45176
                        // 45177
                        // 45178
                        // 45179
                    } else { // 45180 to 45184
                        // 45180
                        // 45181
                        // 45182
                        // 45183
                    }
                } else {
                    if (currentRenderedItemId < 45188) { // 45184 to 45188
                        // 45184
                        // 45185
                        // 45186
                        // 45187
                    } else { // 45188 to 45192
                        // 45188
                        // 45189
                        // 45190
                        // 45191
                    }
                }
            }
        }
    } else {
        if (currentRenderedItemId < 45224) {
            if (currentRenderedItemId < 45208) {
                if (currentRenderedItemId < 45200) {
                    if (currentRenderedItemId < 45196) { // 45192 to 45196
                        // 45192
                        // 45193
                        // 45194
                        // 45195
                    } else { // 45196 to 45200
                        // 45196
                        // 45197
                        // 45198
                        // 45199
                    }
                } else {
                    if (currentRenderedItemId < 45204) { // 45200 to 45204
                        // 45200
                        // 45201
                        // 45202
                        // 45203
                    } else { // 45204 to 45208
                        // 45204
                        // 45205
                        // 45206
                        // 45207
                    }
                }
            } else {
                if (currentRenderedItemId < 45216) {
                    if (currentRenderedItemId < 45212) { // 45208 to 45212
                        // 45208
                        // 45209
                        // 45210
                        // 45211
                    } else { // 45212 to 45216
                        // 45212
                        // 45213
                        // 45214
                        // 45215
                    }
                } else {
                    if (currentRenderedItemId < 45220) { // 45216 to 45220
                        // 45216
                        // 45217
                        // 45218
                        // 45219
                    } else { // 45220 to 45224
                        // 45220
                        // 45221
                        // 45222
                        // 45223
                    }
                }
            }
        } else {
            if (currentRenderedItemId < 45240) {
                if (currentRenderedItemId < 45232) {
                    if (currentRenderedItemId < 45228) { // 45224 to 45228
                        // 45224
                        // 45225
                        // 45226
                        // 45227
                    } else { // 45228 to 45232
                        // 45228
                        // 45229
                        // 45230
                        // 45231
                    }
                } else {
                    if (currentRenderedItemId < 45236) { // 45232 to 45236
                        // 45232
                        // 45233
                        // 45234
                        // 45235
                    } else { // 45236 to 45240
                        // 45236
                        // 45237
                        // 45238
                        // 45239
                    }
                }
            } else {
                if (currentRenderedItemId < 45248) {
                    if (currentRenderedItemId < 45244) { // 45240 to 45244
                        // 45240
                        // 45241
                        // 45242
                        // 45243
                    } else { // 45244 to 45248
                        // 45244
                        // 45245
                        // 45246
                        // 45247
                    }
                } else {
                    if (currentRenderedItemId < 45252) { // 45248 to 45252
                        // 45248
                        // 45249
                        // 45250
                        // 45251
                    } else { // 45252 to 45256
                        // 45252
                        // 45253
                        // 45254
                        // 45255
                    }
                }
            }
        }
    }
}
