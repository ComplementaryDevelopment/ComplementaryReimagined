vec3 GetMinimumLighting(float lightmapYM) {
    #if !defined END && CAVE_LIGHTING > 0
        vec3 minLighting = vec3(0.005625 + vsBrightness * 0.043);
        #if CAVE_LIGHTING != 100
            #define CAVE_LIGHTING_M CAVE_LIGHTING * 0.01
            minLighting *= CAVE_LIGHTING_M;
        #endif
        minLighting *= vec3(0.45, 0.475, 0.6);
        minLighting *= 1.0 - lightmapYM;
    #else
        vec3 minLighting = vec3(0.0);
    #endif

    minLighting += nightVision * vec3(0.5, 0.5, 0.75);

    return minLighting;
}