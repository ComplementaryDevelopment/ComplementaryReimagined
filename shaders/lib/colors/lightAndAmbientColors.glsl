#ifndef INCLUDE_LIGHT_AND_AMBIENT_COLORS
    #define INCLUDE_LIGHT_AND_AMBIENT_COLORS

    #if defined OVERWORLD && defined FRAME_DATA_READ
        #if defined COMPOSITE1
            vec3 lightColor   = fdLightColorC1.xyz;
            vec3 ambientColor = fdAmbientColorC1.xyz;
        #elif defined DEFERRED1
            vec3 lightColor   = fdLightColorD1.xyz;
            vec3 ambientColor = fdAmbientColor.xyz;
        #else
            vec3 lightColor   = fdLightColor.xyz;
            vec3 ambientColor = fdAmbientColor.xyz;
        #endif
    #elif defined OVERWORLD
        #ifdef COMPOSITE1
            #define LAAC_COMPOSITE1
        #endif
        #ifdef DEFERRED1
            #define LAAC_DEFERRED1
        #endif
        #include "/lib/colors/overworldLightColors.glsl"
    #elif defined NETHER
        vec3 lightColor   = vec3(0.0);
        vec3 ambientColor = (netherColor + 0.5 * lavaLightColor) * (0.9 + 0.45 * vsBrightness);
    #elif defined END
        vec3 endLightColor = vec3(0.68, 0.51, 1.07);
        vec3 endOrangeCol = vec3(1.0, 0.3, 0.0);
        float endLightBalancer = 0.2 * vsBrightness;
        vec3 lightColor    = endLightColor * (0.35 - endLightBalancer);
        vec3 ambientColor  = endLightColor * (0.2 + endLightBalancer);
    #endif

    #define HIGHLIGHT_COLOR (normalize(pow(lightColor, vec3(0.37))) * (0.3 + 1.5 * sunVisibility2) * (1.0 - 0.85 * rainFactor))

#endif //INCLUDE_LIGHT_AND_AMBIENT_COLORS
