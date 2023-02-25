#ifndef INCLUDE_WATER_FOG
#define INCLUDE_WATER_FOG
    float GetWaterFog(float lViewPos) {
        #if LIGHTSHAFT_QUALITY > 0 && defined REALTIME_SHADOWS
            float fog = lViewPos / 48.0;
            fog *= fog;
        #else
            float fog = lViewPos / 32.0;
        #endif

        return 1.0 - exp(-fog);
    }
#endif