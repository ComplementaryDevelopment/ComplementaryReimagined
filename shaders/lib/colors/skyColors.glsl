#ifndef INCLUDE_SKY_COLORS
    #define INCLUDE_SKY_COLORS

    #ifdef OVERWORLD
        vec3 skyColorM = skyColor / (length(clamp(skyColorSmooth, skyColor * 0.9, skyColor * 1.1)) + 0.0001);
        vec3 skyColorNoon = skyColorM * (1.28 - 0.47 * rainFactor);
        vec3 skyColorSunset = skyColorM * (1.18 - 0.44 * rainFactor) * invNightFactor * invNightFactor;

        #ifdef SPECIAL_BIOME_WEATHER
            vec3 nmscSnowM = inSnowy * vec3(-0.3, 0.05, 0.2);
            vec3 nmscDryM = inDry * vec3(-0.3);
            vec3 ndscSnowM = inSnowy * vec3(-0.25, -0.01, 0.25);
            vec3 ndscDryM = inDry * vec3(-0.05, -0.09, -0.1);
        #else
            vec3 nmscSnowM = vec3(0.0), nmscDryM = vec3(0.0), ndscSnowM = vec3(0.0), ndscDryM = vec3(0.0);
        #endif
        #if RAIN_STYLE == 2
            vec3 nmscRainMP = vec3(-0.15, 0.025, 0.1);
            vec3 ndscRainMP = vec3(-0.125, -0.005, 0.125);
            #ifdef SPECIAL_BIOME_WEATHER
                vec3 nmscRainM = inRainy * ndscRainMP;
                vec3 ndscRainM = inRainy * ndscRainMP;
            #else
                vec3 nmscRainM = ndscRainMP;
                vec3 ndscRainM = ndscRainMP;
            #endif
        #else
            vec3 nmscRainM = vec3(0.0), ndscRainM = vec3(0.0);
        #endif
        vec3 nmscWeatherM = vec3(-0.1, -0.4, -0.6) + vec3(0.0, 0.06, 0.12) * noonFactor;
        vec3 ndscWeatherM = vec3(-0.15, -0.3, -0.42) + vec3(0.0, 0.02, 0.08) * noonFactor;

        vec3 skyColorSqrt       = sqrt(skyColorNoon);
        vec3 noonUpSkyColor     = pow(skyColorSqrt, vec3(2.9));
        vec3 noonMiddleSkyColor = skyColorSqrt * (vec3(1.15) + rainFactor * (nmscWeatherM + nmscRainM + nmscSnowM + nmscDryM))
                                + noonUpSkyColor * 0.6;
        vec3 noonDownSkyColor   = skyColorSqrt * (vec3(0.9) + rainFactor * (ndscWeatherM + ndscRainM + ndscSnowM + ndscDryM))
                                + noonUpSkyColor * 0.25;

        vec3 sunsetUpSkyColor     = skyColorSunset * (vec3(0.8, 0.58, 0.58) + vec3(0.1, 0.2, 0.35) * rainFactor2);
        vec3 sunsetMiddleSkyColor = skyColorSunset * (vec3(1.8, 1.3, 1.2) + vec3(0.15, 0.25, -0.05) * rainFactor2);
        vec3 sunsetDownSkyColorP  = vec3(1.45, 0.86, 0.5) - vec3(0.8, 0.3, 0.0) * rainFactor;
        vec3 sunsetDownSkyColor   = sunsetDownSkyColorP * 0.5 + 0.25 * sunsetMiddleSkyColor;

        vec3 dayUpSkyColor     = mix(noonUpSkyColor, sunsetUpSkyColor, invNoonFactor2);
        vec3 dayMiddleSkyColor = mix(noonMiddleSkyColor, sunsetMiddleSkyColor, invNoonFactor2);
        vec3 dayDownSkyColor   = mix(noonDownSkyColor, sunsetDownSkyColor, invNoonFactor2);

        vec3 nightColFactor      = vec3(0.07, 0.14, 0.24) * (1.0 - 0.5 * rainFactor) + skyColor;
        vec3 nightUpSkyColor     = pow(nightColFactor, vec3(0.90)) * 0.4;
        vec3 nightMiddleSkyColor = sqrt(nightUpSkyColor) * 0.68;
        vec3 nightDownSkyColor   = nightMiddleSkyColor * vec3(0.82, 0.82, 0.88);
    #endif

#endif //INCLUDE_SKY_COLORS