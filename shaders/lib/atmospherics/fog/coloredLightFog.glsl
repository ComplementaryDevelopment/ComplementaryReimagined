vec3 GetColoredLightFog(vec3 nPlayerPos, vec3 translucentMult, float lViewPos, float lViewPos1, float dither) {
    vec3 lightFog = vec3(0.0);

    float stepMult = 8.0;

    #ifdef CAVE_SMOKE
        float caveFactor = GetCaveFactor();
    #endif

    float maxDist = min(effectiveACLdistance * 0.5, far);
    float halfMaxDist = maxDist * 0.5;
    int sampleCount = int(maxDist / stepMult + 0.001);
    vec3 traceAdd = nPlayerPos * stepMult;
    vec3 tracePos = traceAdd * dither;

    for (int i = 0; i < sampleCount; i++) {
        tracePos += traceAdd;

        float lTracePos = length(tracePos);
        if (lTracePos > lViewPos1) break;

        vec3 voxelPos = SceneToVoxel(tracePos);
        voxelPos = clamp01(voxelPos / vec3(voxelVolumeSize));

        vec4 lightVolume = GetLightVolume(voxelPos);
        vec3 lightSample = lightVolume.rgb;

        float lTracePosM = length(vec3(tracePos.x, tracePos.y * 2.0, tracePos.z));
        lightSample *= max0(1.0 - lTracePosM / maxDist);
        lightSample *= pow2(min1(lTracePos * 0.03125));

        #ifdef CAVE_SMOKE
            if (caveFactor > 0.00001) {
                vec3 smokePos = 0.0025 * (tracePos + cameraPosition);
                vec3 smokeWind = frameTimeCounter * vec3(0.006, 0.003, 0.0);
                float smoke = Noise3D(smokePos + smokeWind)
                            * Noise3D(smokePos * 3.0 - smokeWind)
                            * Noise3D(smokePos * 9.0 + smokeWind);
                smoke = smoothstep1(smoke);
                lightSample *= mix(1.0, smoke * 16.0, caveFactor);
                lightSample += caveFogColor * pow2(smoke) * 0.05 * caveFactor;
            }
        #endif

        if (lTracePos > lViewPos) lightSample *= translucentMult;
        lightFog += lightSample;
    }

    #ifdef NETHER
        lightFog *= netherColor * 5.0;
    #endif

    lightFog *= 1.0 - maxBlindnessDarkness;

    return pow(lightFog / sampleCount, vec3(0.25));
}