#ifndef INCLUDE_WATER_FOG
#define INCLUDE_WATER_FOG
    float GetWaterFog(float lViewPos) {
        #if WATER_FOG_MULT != 100
            #define WATER_FOG_MULT_M WATER_FOG_MULT * 0.01;
            lViewPos *= WATER_FOG_MULT_M;
        #endif

        #if LIGHTSHAFT_QUALI > 0 && defined REALTIME_SHADOWS
            float fog = lViewPos / 48.0;
            fog *= fog;
        #else
            float fog = lViewPos / 32.0;
        #endif

        return 1.0 - exp(-fog);
    }
#endif