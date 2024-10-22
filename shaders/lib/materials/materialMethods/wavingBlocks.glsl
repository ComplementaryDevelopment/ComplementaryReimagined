#if COLORED_LIGHTING_INTERNAL > 0
    #include "/lib/misc/voxelization.glsl"
#endif

vec3 GetRawWave(in vec3 pos, float wind) {
    float magnitude = sin(wind * 0.0027 + pos.z + pos.y) * 0.04 + 0.04;
    float d0 = sin(wind * 0.0127);
    float d1 = sin(wind * 0.0089);
    float d2 = sin(wind * 0.0114);
    vec3 wave;
    wave.x = sin(wind*0.0063 + d0 + d1 - pos.x + pos.z + pos.y) * magnitude;
    wave.z = sin(wind*0.0224 + d1 + d2 + pos.x - pos.z + pos.y) * magnitude;
    wave.y = sin(wind*0.0015 + d2 + d0 + pos.z + pos.y - pos.y) * magnitude;

    return wave;
}

vec3 GetWave(in vec3 pos, float waveSpeed) {
    float wind = frameTimeCounter * waveSpeed * WAVING_SPEED;
    vec3 wave = GetRawWave(pos, wind);

    #define WAVING_I_RAIN_MULT_M WAVING_I_RAIN_MULT * 0.01

    #if WAVING_I_RAIN_MULT > 100
        float windRain = frameTimeCounter * waveSpeed * WAVING_I_RAIN_MULT_M * WAVING_SPEED;
        vec3 waveRain = GetRawWave(pos, windRain);
        wave = mix(wave, waveRain, rainFactor);
    #endif

    #ifdef NO_WAVING_INDOORS
        wave *= clamp(lmCoord.y - 0.87, 0.0, 0.1);
    #else
        wave *= 0.1;
    #endif

    float wavingIntensity = WAVING_I * mix(1.0, WAVING_I_RAIN_MULT_M, rainFactor);

    return wave * wavingIntensity;
}

void DoWave_Foliage(inout vec3 playerPos, vec3 worldPos, float waveMult) {
    worldPos.y *= 0.5;

    vec3 wave = GetWave(worldPos, 170.0);
    wave.x = wave.x * 8.0 + wave.y * 4.0;
    wave.y = 0.0;
    wave.z = wave.z * 3.0;

    playerPos.xyz += wave * waveMult;
}

void DoWave_Leaves(inout vec3 playerPos, vec3 worldPos, float waveMult) {
    worldPos *= vec3(0.75, 0.375, 0.75);

    vec3 wave = GetWave(worldPos, 170.0);
    wave *= vec3(8.0, 3.0, 4.0);

    wave *= 1.0 - inSnowy; // Leaves with snow on top look wrong

    playerPos.xyz += wave * waveMult;
}

void DoWave_Water(inout vec3 playerPos, vec3 worldPos) {
    float waterWaveTime = frameTimeCounter * 6.0 * WAVING_SPEED;
    worldPos.xz *= 14.0;

    float wave  = sin(waterWaveTime * 0.7 + worldPos.x * 0.14 + worldPos.z * 0.07);
          wave += sin(waterWaveTime * 0.5 + worldPos.x * 0.10 + worldPos.z * 0.05);

    #ifdef NO_WAVING_INDOORS
        wave *= clamp(lmCoord.y - 0.87, 0.0, 0.1);
    #else
        wave *= 0.1;
    #endif

    playerPos.y += wave * 0.125 - 0.05;

    #if defined GBUFFERS_WATER && WATER_STYLE == 1
        normal = mix(normal, tangent, wave * 0.01);
    #endif
}

void DoWave_Lava(inout vec3 playerPos, vec3 worldPos) {
    if (fract(worldPos.y + 0.005) > 0.06) {
        float lavaWaveTime = frameTimeCounter * 3.0 * WAVING_SPEED;
        worldPos.xz *= 14.0;

        float wave  = sin(lavaWaveTime * 0.7 + worldPos.x * 0.14 + worldPos.z * 0.07);
              wave += sin(lavaWaveTime * 0.5 + worldPos.x * 0.05 + worldPos.z * 0.10);

        playerPos.y += wave * 0.0125;
    }
}

void DoWave(inout vec3 playerPos, int mat) {
    vec3 worldPos = playerPos.xyz + cameraPosition.xyz;

    #if defined GBUFFERS_TERRAIN || defined SHADOW
        #ifdef WAVING_FOLIAGE
            if (mat == 10005) { // Grounded Waving Foliage
                if (gl_MultiTexCoord0.t < mc_midTexCoord.t || fract(worldPos.y + 0.21) > 0.26)
                DoWave_Foliage(playerPos.xyz, worldPos, 1.0);
            } else if (mat == 10021) { // Upper Layer Waving Foliage
                DoWave_Foliage(playerPos.xyz, worldPos, 1.0);
            }

            #if defined WAVING_LEAVES || defined WAVING_LAVA || defined WAVING_LILY_PAD
                else
            #endif
        #endif

        #ifdef WAVING_LEAVES
            if (mat == 10009) { // Leaves
                DoWave_Leaves(playerPos.xyz, worldPos, 1.0);
            } else if (mat == 10013) { // Vine
                // Reduced waving on vines to prevent clipping through blocks
                DoWave_Leaves(playerPos.xyz, worldPos, 0.75);
            }
            #if defined NETHER || defined DO_NETHER_VINE_WAVING_OUTSIDE_NETHER
                else if (mat == 10884 || mat == 10885) { // Weeping Vines, Twisting Vines
                    float waveMult = 1.0;
                    #if COLORED_LIGHTING_INTERNAL > 0
                        vec3 playerPosP = playerPos + vec3(0.0, 0.1, 0.0);
                        vec3 voxelPosP = SceneToVoxel(playerPosP);
                        vec3 playerPosN = playerPos - vec3(0.0, 0.1, 0.0);
                        vec3 voxelPosN = SceneToVoxel(playerPosN);

                        if (CheckInsideVoxelVolume(voxelPosP)) {
                            int voxelP = int(texelFetch(voxel_sampler, ivec3(voxelPosP), 0).r);
                            int voxelN = int(texelFetch(voxel_sampler, ivec3(voxelPosN), 0).r);
                            if (voxelP != 0 && voxelP != 65 || voxelN != 0 && voxelN != 65) // not air, not weeping vines
                                waveMult = 0.0;
                        }
                    #endif
                    DoWave_Foliage(playerPos.xyz, worldPos, waveMult);
                }
            #endif

            #if defined WAVING_LAVA || defined WAVING_LILY_PAD
                else
            #endif
        #endif

        #ifdef WAVING_LAVA
            if (mat == 10068) { // Lava
                DoWave_Lava(playerPos.xyz, worldPos);

                #ifdef GBUFFERS_TERRAIN
                    // G8FL735 Fixes Optifine-Iris parity. Optifine has 0.9 gl_Color.rgb on a lot of versions
                    glColorRaw.rgb = min(glColorRaw.rgb, vec3(0.9));
                #endif
            }

            #ifdef WAVING_LILY_PAD
                else
            #endif
        #endif

        #ifdef WAVING_LILY_PAD
            if (mat == 10489) { // Lily Pad
                DoWave_Water(playerPos.xyz, worldPos);
            }
        #endif
    #endif

    #if defined GBUFFERS_WATER || defined SHADOW
        #ifdef WAVING_WATER_VERTEX
            #if defined WAVING_ANYTHING_TERRAIN && defined SHADOW
                else
            #endif

            if (mat == 32000) { // Water
                if (fract(worldPos.y + 0.005) > 0.06)
                DoWave_Water(playerPos.xyz, worldPos);
            }
        #endif
    #endif
}