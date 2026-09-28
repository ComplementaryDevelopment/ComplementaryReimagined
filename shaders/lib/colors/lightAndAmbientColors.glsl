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
        const int LIGHT_COLORS_SURFACE = 0;
        const int LIGHT_COLORS_CLOUDS = 1;
        const int LIGHT_COLORS_SHAFTS = 2;

        struct LightAndAmbientColors {
            vec3 light;
            vec3 ambient;
        };

        // Constant variants let the begin pass and the fallback share these calculations.
        LightAndAmbientColors GetOverworldLightColors(int variant) {
            bool lightShafts = variant == LIGHT_COLORS_SHAFTS;
            vec3 noonClearLightColor = lightShafts
                ? vec3(0.4, 0.75, 1.3)
                : vec3(0.65, 0.55, 0.375) * 2.05;
            vec3 noonClearAmbientColor = pow(skyColor, vec3(0.75)) * 0.85;

            vec3 sunsetClearLightColor = lightShafts
                ? pow(vec3(0.62, 0.39, 0.24), vec3(1.5 + invNoonFactor)) * 6.8
                : pow(vec3(0.64, 0.45, 0.3), vec3(1.5 + invNoonFactor)) * 5.0;
            vec3 sunsetClearAmbientColor = noonClearAmbientColor * vec3(1.21, 0.92, 0.76) * 0.95;

            vec3 nightClearLightColor;
            if (lightShafts) {
                nightClearLightColor = vec3(0.08, 0.12, 0.23);
            } else if (variant == LIGHT_COLORS_CLOUDS) {
                nightClearLightColor = 0.9 * vec3(0.11, 0.14, 0.20);
            } else {
                nightClearLightColor = 0.9 * vec3(0.15, 0.14, 0.20) * (0.4 + vsBrightness * 0.4);
            }
            vec3 nightClearAmbientColor = 0.9 * vec3(0.09, 0.12, 0.17) * (1.55 + vsBrightness * 0.77);

            #ifdef SPECIAL_BIOME_WEATHER
                vec3 drlcSnowM = inSnowy * vec3(-0.06, 0.0, 0.04);
                vec3 drlcDryM = inDry * vec3(0.01, -0.035, -0.06);
            #else
                vec3 drlcSnowM = vec3(0.0), drlcDryM = vec3(0.0);
            #endif
            #if RAIN_STYLE == 2
                vec3 drlcRainMP = vec3(-0.03, 0.0, 0.02);
                #ifdef SPECIAL_BIOME_WEATHER
                    vec3 drlcRainM = inRainy * drlcRainMP;
                #else
                    vec3 drlcRainM = drlcRainMP;
                #endif
            #else
                vec3 drlcRainM = vec3(0.0);
            #endif
            vec3 dayRainLightColor = vec3(0.21, 0.16, 0.13) * 0.85 + noonFactor * vec3(0.0, 0.02, 0.06)
                                    + drlcRainM + drlcSnowM + drlcDryM;
            vec3 dayRainAmbientColor = vec3(0.2, 0.2, 0.25) * (1.8 + 0.5 * vsBrightness);

            vec3 nightRainLightColor = vec3(0.03, 0.035, 0.05) * (0.5 + 0.5 * vsBrightness);
            vec3 nightRainAmbientColor = vec3(0.16, 0.20, 0.3) * (0.75 + 0.6 * vsBrightness);

            float noonFactorDM = lightShafts ? noonFactor * noonFactor : noonFactor;
            vec3 dayLightColor = mix(sunsetClearLightColor, noonClearLightColor, noonFactorDM);
            vec3 dayAmbientColor = mix(sunsetClearAmbientColor, noonClearAmbientColor, noonFactorDM);

            vec3 clearLightColor = mix(nightClearLightColor, dayLightColor, sunVisibility2);
            vec3 clearAmbientColor = mix(nightClearAmbientColor, dayAmbientColor, sunVisibility2);

            float rainShadowVisReduce = 0.0
                #ifdef SUN_MOON_DURING_RAIN
                    #ifdef SPECIAL_BIOME_WEATHER
                        + 0.2 * inSnowy + 0.2 * inDry
                    #elif RAIN_STYLE == 2
                        + 0.2
                    #endif
                #else
                    + 0.4
                #endif
            ;

            vec3 rainLightColor = mix(nightRainLightColor, dayRainLightColor * (1.0 - rainShadowVisReduce), sunVisibility2) * 2.5;
            vec3 rainAmbientColor = mix(nightRainAmbientColor, dayRainAmbientColor * (1.0 + rainShadowVisReduce), sunVisibility2);

            return LightAndAmbientColors(
                mix(clearLightColor, rainLightColor, rainFactor),
                mix(clearAmbientColor, rainAmbientColor, rainFactor)
            );
        }

        #if defined COMPOSITE1
            LightAndAmbientColors overworldColors = GetOverworldLightColors(LIGHT_COLORS_SHAFTS);
        #elif defined DEFERRED1
            LightAndAmbientColors overworldColors = GetOverworldLightColors(LIGHT_COLORS_CLOUDS);
        #else
            LightAndAmbientColors overworldColors = GetOverworldLightColors(LIGHT_COLORS_SURFACE);
        #endif
        vec3 lightColor = overworldColors.light;
        vec3 ambientColor = overworldColors.ambient;
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
