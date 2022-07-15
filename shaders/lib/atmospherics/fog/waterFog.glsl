#ifndef INCLUDE_WATER_FOG
#define INCLUDE_WATER_FOG
    float GetWaterFog(float lViewPos) {
        float fog = lViewPos / 48.0;
        fog *= fog;
        return 1.0 - exp(-fog);
    }
#endif