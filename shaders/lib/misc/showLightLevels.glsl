#if SHOW_LIGHT_LEVEL == 1
    if (heldItemId == 40000 || heldItemId2 == 40000)
#elif SHOW_LIGHT_LEVEL == 2
    if (heldBlockLightValue > 7.4 || heldBlockLightValue2 > 7.4)
#endif

if (NdotU > 0.99) {
    #ifdef OVERWORLD
        #if MC_VERSION < 11800
            float lxMin = 0.533334;
        #else
            float lxMin = 0.000001;
        #endif
            float lyMin = 0.533334;
    #else
        float lxMin = 0.8;
        float lyMin = 0.533334;
    #endif

    bool xDanger = lmCoord.x < lxMin;
    #ifndef NETHER
        bool yDanger = lmCoord.y < lyMin;
    #else
        bool yDanger = lmCoord.x < lyMin;
    #endif

    if (xDanger) {
        vec2 indicatePos = playerPos.xz + cameraPosition.xz;
        indicatePos = 1.0 - 2.0 * abs(fract(indicatePos) - 0.5);
        float minPos = min(indicatePos.x, indicatePos.y);

        if (minPos > 0.5) {
            color.rgb = yDanger ? vec3(0.4, 0.05, 0.05) : vec3(0.3, 0.3, 0.05);

            smoothnessG = 0.5;
            highlightMult = 1.0;
            smoothnessD = 0.0;

            emission = 3.0;
        }
    }
}