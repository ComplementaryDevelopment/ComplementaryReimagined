#ifdef SHADOW
    vec2 lmCoord = vec2(0.0);
#endif

vec3 GetWave(in vec3 pos, float waveSpeed) {
    float wind = frameTimeCounter * waveSpeed;

    float magnitude = sin(wind * 0.0027 + pos.z + pos.y) * 0.04 + 0.04;
    float d0 = sin(wind * 0.0127);
    float d1 = sin(wind * 0.0089);
    float d2 = sin(wind * 0.0114);
    vec3 wave;
    wave.x = sin(wind*0.0063 + d0 + d1 - pos.x + pos.z + pos.y) * magnitude;
    wave.z = sin(wind*0.0224 + d1 + d2 + pos.x - pos.z + pos.y) * magnitude;
    wave.y = sin(wind*0.0015 + d2 + d0 + pos.z + pos.y - pos.y) * magnitude;

    wave *= max0(lmCoord.y - 0.9);

    return wave;
}

void DoWave_Foliage(inout vec3 playerPos, vec3 worldPos) {
    worldPos.y *= 0.5;

    vec3 wave = GetWave(worldPos, 170.0);
    wave.x = wave.x * 8.0 + wave.y * 4.0;
    wave.y = 0.0;
    wave.z = wave.z * 3.0;

    playerPos.xyz += wave;
}

void DoWave_GroundedFoliage(inout vec3 playerPos, vec3 worldPos) {
    if (gl_MultiTexCoord0.t < mc_midTexCoord.t || fract(worldPos.y + 0.21) > 0.26) {
        DoWave_Foliage(playerPos, worldPos);
    }
}

void DoWave_Leaves(inout vec3 playerPos, vec3 worldPos) {
    worldPos *= vec3(0.5, 0.25, 0.5);

    vec3 wave = GetWave(worldPos, 170.0);
    wave *= vec3(8.0, 3.0, 4.0);

    playerPos.xyz += wave;
}

void DoWave(inout vec3 playerPos, int mat) {
    vec3 worldPos = playerPos.xyz + cameraPosition.xyz;

    if (mat == 10004) { // Grounded Waving Foliage
        DoWave_GroundedFoliage(playerPos.xyz, worldPos);
    } else if (mat == 10020) { // Upper Layer Waving Foliage
        DoWave_Foliage(playerPos.xyz, worldPos);
    }

    #if WAVING_BLOCKS >= 2
        else if (mat == 10008 || mat == 10012) { // Leaves, Vine
            DoWave_Leaves(playerPos.xyz, worldPos);
        }
    #endif
}