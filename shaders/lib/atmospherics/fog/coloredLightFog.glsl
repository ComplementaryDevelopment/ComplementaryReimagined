vec3 GetColoredLightFog(vec3 nPlayerPos, vec3 translucentMult, float lViewPos, float lViewPos1, float dither) {
    vec3 lightFog = vec3(0.0);

    float stepMult = 8.0;

    float maxDist = min(effectiveACLdistance * 0.5, far);
    int sampleCount = int(maxDist / stepMult + 0.001);
    vec3 traceAdd = nPlayerPos * stepMult;
    vec3 tracePos = traceAdd * dither;

    for (int i = 0; i < sampleCount; i++) {
        float lTracePos = length(tracePos);
        if (lTracePos > lViewPos1) break;
        if (any(greaterThan(abs(tracePos * 2.0), vec3(voxelVolumeSize)))) break;

        vec3 voxelPos = SceneToVoxel(tracePos);
        voxelPos = clamp01(voxelPos / vec3(voxelVolumeSize));

        vec4 lightVolume = GetLightVolume(voxelPos);
        vec3 lightSample = lightVolume.rgb;

        float lTracePosM = length(
            vec3(
                tracePos.x, 
                #if COLORED_LIGHTING_INTERNAL <= 512
                    tracePos.y * 2.0, 
                #elif COLORED_LIGHTING_INTERNAL == 768
                    tracePos.y * 3.0, 
                #elif COLORED_LIGHTING_INTERNAL == 1024
                    tracePos.y * 4.0, 
                #endif
                tracePos.z
            )
        );
        lightSample *= max0(1.0 - lTracePosM / maxDist);
        lightSample *= pow2(min1(lTracePos * 0.03125));

        if (lTracePos > lViewPos) lightSample *= translucentMult;
        lightFog += lightSample;

        tracePos += traceAdd;
    }

    #ifdef NETHER
        lightFog *= netherColor * 5.0;
    #endif

    lightFog *= 1.0 - maxBlindnessDarkness;

    return pow(lightFog / sampleCount, vec3(0.25));
}