if (entityId < 50128) { // 50000 to 50128
    if (entityId < 50064) { // 50000 to 50064
        if (entityId < 50032) { // 50000 to 50032
            if (entityId < 50016) { // 50000 to 50016
                if (entityId < 50008) { // 50000 to 50008
                    if (entityId == 50000) { // End Crystal
                        lmCoordM.x *= 0.7;

                        if (color.g * 1.2 < color.r) {
                            emission = 12.0 * color.g;
                            color.r *= 1.1;
                        }
                    } else if (entityId == 50004) { // Lightning Bolt
                        #include "/lib/materials/specificMaterials/others/lightningBolt.glsl"
                    }
                } else { // 50008 to 50016
                    if (entityId == 50008) { // Item Frame, Glow Item Frame
                        noSmoothLighting = true;
                    } else /*if (entityId == 50012)*/ { // Iron Golem
                        #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"

                        smoothnessD *= 0.4;
                    }
                }
            } else { // 50016 to 50032
                if (entityId < 50024) { // 50016 to 50024
                    if (entityId == 50016 || entityId == 50017) { // Player
                        if (entityColor.a < 0.001) {
                            #ifdef COATED_TEXTURES
                                noiseFactor = 0.5;
                            #endif

                            if (CheckForColor(texelFetch(tex, ivec2(0, 0), 0).rgb, vec3(23, 46, 92))) {
                                for (int i = 63; i >= 56; i--) {
                                    vec3 dif = color.rgb - texelFetch(tex, ivec2(i, 0), 0).rgb;
                                    if (dif == clamp(dif, vec3(-0.001), vec3(0.001))) {
                                        emission = 2.0 * texelFetch(tex, ivec2(i, 1), 0).r;
                                    }
                                }
                            }
                        }
                    } else /*if (entityId == 50020)*/ { // Blaze
                        lmCoordM = vec2(0.9, 0.0);
                        emission = min(color.r, 0.7) * 1.4;

                        float dotColor = dot(color.rgb, color.rgb);
                        if (abs(dotColor - 1.5) > 1.4) {
                            emission = 5.0;
                        }
                    }
                } else { // 50024 to 50032
                    if (entityId == 50024) { // Creeper
                        emission = max0(color.b - color.g - color.r) * 10.0;
                    } else /*if (entityId == 50028)*/ { // Drowned
                        if (atlasSize.x < 900) {
                            if (CheckForColor(color.rgb, vec3(143, 241, 215)) ||
                                CheckForColor(color.rgb, vec3( 49, 173, 183)) ||
                                CheckForColor(color.rgb, vec3(101, 224, 221))) emission = 2.5;
                        }
                    }
                }
            }
        } else { // 50032 to 50064
            if (entityId < 50048) { // 50032 to 50048
                if (entityId < 50040) { // 50032 to 50040
                    if (entityId == 50032) { // Guardian
                        vec3 absDif = abs(vec3(color.r - color.g, color.g - color.b, color.r - color.b));
                        float maxDif = max(absDif.r, max(absDif.g, absDif.b));
                        if (maxDif < 0.1 && color.b > 0.5 && color.b < 0.88) {
                            emission = pow2(pow1_5(color.b)) * 5.0;
                            color.rgb *= color.rgb;
                        }
                    } else /*if (entityId == 50036)*/ { // Elder Guardian
                        if (CheckForColor(color.rgb, vec3(203, 177, 165)) ||
                            CheckForColor(color.rgb, vec3(214, 155, 126))) {
                            emission = pow2(pow1_5(color.b)) * 10.0;
                            color.r *= 1.2;
                        }
                    }
                } else { // 50040 to 50048
                    if (entityId == 50040) { // Endermite
                        if (CheckForColor(color.rgb, vec3(87, 23, 50))) {
                            emission = 8.0;
                            color.rgb *= color.rgb;
                        }
                    } else /*if (entityId == 50044)*/ { // Ghast
                        if (entityColor.a < 0.001)
                            emission = max0(color.r - color.g - color.b) * 6.0;
                    }
                }
            } else { // 50048 to 50064
                if (entityId < 50056) { // 50048 to 50056
                    if (entityId == 50048) { // Glow Squid
                        lmCoordM.x = 0.0;
                        float dotColor = dot(color.rgb, color.rgb);
                        emission = pow2(pow2(min(dotColor * 0.65, 1.5))) + 0.45;
                    } else /*if (entityId == 50052)*/ { // Magma Cube
                        emission = color.g * 6.0;
                    }
                } else { // 50056 to 50064
                    if (entityId == 50056) { // Stray
                        if (CheckForColor(color.rgb, vec3(230, 242, 246)) && texCoord.y > 0.35)
                            emission = 1.75;
                    } else /*if (entityId == 50060)*/ { // Vex
                        lmCoordM = vec2(0.0);
                        emission = pow2(pow2(color.r)) * 3.5 + 0.5;
                        color.a *= color.a;
                    }
                }
            }
        }
    } else { // 50064 to 50128
        if (entityId < 50096) { // 50064 to 50096
            if (entityId < 50080) { // 50064 to 50080
                if (entityId < 50072) { // 50064 to 50072
                    if (entityId == 50064) { // Witch
                        emission = 2.0 * color.g * float(color.g * 1.5 > color.b + color.r);
                    } else /*if (entityId == 50068)*/ { // Wither, Wither Skull
                        lmCoordM.x = 0.9;
                        emission = 3.0 * float(dot(color.rgb, color.rgb) > 1.0);
                    }
                } else { // 50072 to 50080
                    if (entityId == 50072) { // Experience Orb
                        emission = 7.5;

                        color.rgb *= color.rgb;
                    } else /*if (entityId == 50076)*/ { // Boats
                        playerPos.y += 0.38; // consistentBOAT2176: to avoid water shadow and the black inner shadow bug
                    }
                }
            } else { // 50080 to 50096
                if (entityId < 50088) { // 50080 to 50088
                    if (entityId == 50080) { // Allay
                        if (atlasSize.x < 900) {
                            lmCoordM = vec2(0.0);
                            emission = float(color.r > 0.9 && color.b > 0.9) * 5.0 + color.g;
                        } else {
                            lmCoordM.x = 0.8;
                        }
                    } else /*if (entityId == 50084)*/ { // Slime, Chicken
                        //only code is in Vertex Shader for now
                    }
                } else { // 50088 to 50096
                    if (entityId == 50088) { // Entity Flame (Iris Feature)
                        emission = 1.3;
                    } else /*if (entityId == 50092)*/ { // Trident Entity
                        #ifdef IS_IRIS
                            // Only on Iris, because otherwise it would be inconsistent with the Trident item
                            #include "/lib/materials/specificMaterials/others/trident.glsl"
                        #endif
                    }
                }
            }
        } else { // 50096 to 50128
            if (entityId < 50112) { // 50096 to 50112
                if (entityId < 50104) { // 50096 to 50104
                    if (entityId == 50096) { // Minecart++
                        if (atlasSize.x < 900 && color.r * color.g * color.b + color.b > 0.3) {
                            #include "/lib/materials/specificMaterials/terrain/ironBlock.glsl"

                            smoothnessD *= 0.6;
                        }
                    } else /*if (entityId == 50100)*/ { // Bogged
                        if (CheckForColor(color.rgb, vec3(239, 254, 194)))
                            emission = 2.5;
                    }
                } else { // 50104 to 50112
                    if (entityId == 50104) { // Piglin++, Hoglin+
                        if (atlasSize.x < 900) {
                            if (CheckForColor(color.rgb, vec3(255)) || CheckForColor(color.rgb, vec3(255, 242, 246))) {
                                vec2 tSize = textureSize(tex, 0);
                                vec4 checkColorOneRight = texelFetch(tex, ivec2(texCoord * tSize) + ivec2(1, 0), 0);
                                if (
                                    CheckForColor(checkColorOneRight.rgb, vec3(201, 130, 101)) ||
                                    CheckForColor(checkColorOneRight.rgb, vec3(241, 158, 152)) ||
                                    CheckForColor(checkColorOneRight.rgb, vec3(223, 127, 119)) ||
                                    CheckForColor(checkColorOneRight.rgb, vec3(241, 158, 152)) ||
                                    CheckForColor(checkColorOneRight.rgb, vec3(165, 99, 80)) ||
                                    CheckForColor(checkColorOneRight.rgb, vec3(213, 149, 122)) ||
                                    CheckForColor(checkColorOneRight.rgb, vec3(255))
                                ) {
                                    emission = 1.0;
                                }
                            }
                        }
                    } else /*if (entityId == 50108)*/ { // Creaking
                        if (color.r > 0.7 && color.r > color.g * 1.2 && color.g > color.b * 2.0) { // Eyes
                            lmCoordM.x = 0.5;
                            emission = 5.0 * color.g;
                            color.rgb *= color.rgb;
                        }
                    }
                }
            } else { // 50112 to 50128
                if (entityId < 50120) { // 50112 to 50120
                    if (entityId == 50112) { // Name Tag
                        noDirectionalShading = true;
                        color.rgb *= 1.5;
                        if (color.a < 0.5) {
                            color.a = 0.12;
                            color.rgb *= 5.0;
                        }
                    } else /*if (entityId == 50116)*/ { // Copper Golem
                        #include "/lib/materials/specificMaterials/terrain/copperBlock.glsl"

                        smoothnessD *= 0.5;
                    }
                } else { // 50120 to 50128
                    if (entityId == 50120) { // Parched
                        if (CheckForColor(color.rgb, vec3(254, 235, 194))) {
                            vec2 tSize = textureSize(tex, 0);
                            vec4 checkColorOneDown = texelFetch(tex, ivec2(texCoord * tSize) + ivec2(0, 1), 0);
                            if (CheckForColor(checkColorOneDown.rgb, vec3(135, 126, 118)) ||
                                CheckForColor(checkColorOneDown.rgb, vec3(106, 103, 98))
                            ) {
                                emission = 1.75;
                            }
                        }
                    } else /*if (entityId == 50124)*/ { // Zombie Nautilus
                        if (CheckForColor(color.rgb, vec3(143, 241, 215)) || CheckForColor(color.rgb, vec3(101, 224, 221)))
                            emission = 1.5;
                    }
                }
            }
        }
    }
} else { // 50128 to 50256
    if (entityId < 50192) { // 50128 to 50192
        if (entityId < 50160) { // 50128 to 50160
            if (entityId < 50144) { // 50128 to 50144
                if (entityId < 50136) { // 50128 to 50136
                    if (entityId < 50132) { // 50128 to 50132
                        // 50128
                        // 50129
                        // 50130
                        // 50131
                    } else { // 50132 to 50136
                        // 50132
                        // 50133
                        // 50134
                        // 50135
                    }
                } else { // 50136 to 50144
                    if (entityId < 50140) { // 50136 to 50140
                        // 50136
                        // 50137
                        // 50138
                        // 50139
                    } else { // 50140 to 50144
                        // 50140
                        // 50141
                        // 50142
                        // 50143
                    }
                }
            } else { // 50144 to 50160
                if (entityId < 50152) { // 50144 to 50152
                    if (entityId < 50148) { // 50144 to 50148
                        // 50144
                        // 50145
                        // 50146
                        // 50147
                    } else { // 50148 to 50152
                        // 50148
                        // 50149
                        // 50150
                        // 50151
                    }
                } else { // 50152 to 50160
                    if (entityId < 50156) { // 50152 to 50156
                        // 50152
                        // 50153
                        // 50154
                        // 50155
                    } else { // 50156 to 50160
                        // 50156
                        // 50157
                        // 50158
                        // 50159
                    }
                }
            }
        } else { // 50160 to 50192
            if (entityId < 50176) { // 50160 to 50176
                if (entityId < 50168) { // 50160 to 50168
                    if (entityId < 50164) { // 50160 to 50164
                        // 50160
                        // 50161
                        // 50162
                        // 50163
                    } else { // 50164 to 50168
                        // 50164
                        // 50165
                        // 50166
                        // 50167
                    }
                } else { // 50168 to 50176
                    if (entityId < 50172) { // 50168 to 50172
                        // 50168
                        // 50169
                        // 50170
                        // 50171
                    } else { // 50172 to 50176
                        // 50172
                        // 50173
                        // 50174
                        // 50175
                    }
                }
            } else { // 50176 to 50192
                if (entityId < 50184) { // 50176 to 50184
                    if (entityId < 50180) { // 50176 to 50180
                        // 50176
                        // 50177
                        // 50178
                        // 50179
                    } else { // 50180 to 50184
                        // 50180
                        // 50181
                        // 50182
                        // 50183
                    }
                } else { // 50184 to 50192
                    if (entityId < 50188) { // 50184 to 50188
                        // 50184
                        // 50185
                        // 50186
                        // 50187
                    } else { // 50188 to 50192
                        // 50188
                        // 50189
                        // 50190
                        // 50191
                    }
                }
            }
        }
    } else { // 50192 to 50256
        if (entityId < 50224) { // 50192 to 50224
            if (entityId < 50208) { // 50192 to 50208
                if (entityId < 50200) { // 50192 to 50200
                    if (entityId < 50196) { // 50192 to 50196
                        // 50192
                        // 50193
                        // 50194
                        // 50195
                    } else { // 50196 to 50200
                        // 50196
                        // 50197
                        // 50198
                        // 50199
                    }
                } else { // 50200 to 50208
                    if (entityId < 50204) { // 50200 to 50204
                        // 50200
                        // 50201
                        // 50202
                        // 50203
                    } else { // 50204 to 50208
                        // 50204
                        // 50205
                        // 50206
                        // 50207
                    }
                }
            } else { // 50208 to 50224
                if (entityId < 50216) { // 50208 to 50216
                    if (entityId < 50212) { // 50208 to 50212
                        // 50208
                        // 50209
                        // 50210
                        // 50211
                    } else { // 50212 to 50216
                        // 50212
                        // 50213
                        // 50214
                        // 50215
                    }
                } else { // 50216 to 50224
                    if (entityId < 50220) { // 50216 to 50220
                        // 50216
                        // 50217
                        // 50218
                        // 50219
                    } else { // 50220 to 50224
                        // 50220
                        // 50221
                        // 50222
                        // 50223
                    }
                }
            }
        } else { // 50224 to 50256
            if (entityId < 50240) { // 50224 to 50240
                if (entityId < 50232) { // 50224 to 50232
                    if (entityId < 50228) { // 50224 to 50228
                        // 50224
                        // 50225
                        // 50226
                        // 50227
                    } else { // 50228 to 50232
                        // 50228
                        // 50229
                        // 50230
                        // 50231
                    }
                } else { // 50232 to 50240
                    if (entityId < 50236) { // 50232 to 50236
                        // 50232
                        // 50233
                        // 50234
                        // 50235
                    } else { // 50236 to 50240
                        // 50236
                        // 50237
                        // 50238
                        // 50239
                    }
                }
            } else { // 50240 to 50256
                if (entityId < 50248) { // 50240 to 50248
                    if (entityId < 50244) { // 50240 to 50244
                        // 50240
                        // 50241
                        // 50242
                        // 50243
                    } else { // 50244 to 50248
                        // 50244
                        // 50245
                        // 50246
                        // 50247
                    }
                } else { // 50248 to 50256
                    if (entityId < 50252) { // 50248 to 50252
                        // 50248
                        // 50249
                        // 50250
                        // 50251
                    } else { // 50252 to 50256
                        // 50252
                        // 50253
                        // 50254
                        // 50255
                    }
                }
            }
        }
    }
}
