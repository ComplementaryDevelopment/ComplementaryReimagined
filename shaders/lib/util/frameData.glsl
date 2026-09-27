#if FRAME_DATA_BUFFER == 1 && defined IS_IRIS && defined IRIS_FEATURE_SSBO && defined IRIS_FEATURE_COMPUTE_SHADERS && !defined GBUFFERS_COLORWHEEL && !defined GBUFFERS_COLORWHEEL_TRANSLUCENT && !defined SHADOW_COLORWHEEL

    #ifdef BEGIN_PASS
        #define FRAME_DATA_WRITE
        #define FRAME_DATA_QUALIFIER writeonly
    #else
        #define FRAME_DATA_READ
        #define FRAME_DATA_QUALIFIER readonly

        // Avoid extra register pressure in composite1
        #ifndef COMPOSITE1
            #define FRAME_DATA_READ_TIME
        #endif
    #endif

    #ifndef VOXY_PATCH
        #extension GL_ARB_shader_storage_buffer_object : enable

        // Keep in sync with program/voxy.json
        layout(std430, binding = 8) FRAME_DATA_QUALIFIER buffer FrameDataBuffer {
            vec4 fdTime;                // timeAngle, noonFactorRaw, noonFactor, nightFactor
            vec4 fdSunVec;
            vec4 fdUpVec;
            vec4 fdEastVec;
            vec4 fdNorthVec;
            vec4 fdUnderwaterColorM1;
            vec4 fdLightColor;
            vec4 fdAmbientColor;
            vec4 fdLightColorD1;
            vec4 fdLightColorC1;
            vec4 fdAmbientColorC1;
            vec4 fdHighlightColor;
            vec4 fdDayUpSkyColor;
            vec4 fdDayMiddleSkyColor;
            vec4 fdDayDownSkyColor;
            vec4 fdNightUpSkyColor;
            vec4 fdNightMiddleSkyColor;
            vec4 fdNightDownSkyColor;
        };
    #endif
#endif
