#ifndef INCLUDE_LIGHT_AND_AMBIENT_COLORS
#define INCLUDE_LIGHT_AND_AMBIENT_COLORS

#if defined OVERWORLD
    vec3 noonClearLightColor   = vec3(0.7, 0.55, 0.5) * 1.5;
    vec3 noonClearAmbientColor = pow(skyColor, vec3(0.6)) * 0.85;

    #ifndef COMPOSITE
        vec3 sunsetClearLightColor = pow(vec3(0.6, 0.41, 0.24), vec3(1.5 + invNoonFactor)) * 4.5; //ground and cloud color
    #else
        vec3 sunsetClearLightColor = pow(vec3(0.6, 0.40, 0.24), vec3(1.5 + invNoonFactor)) * 6.4; //light shaft color
    #endif
    vec3 sunsetClearAmbientColor   = noonClearAmbientColor * vec3(1.0, 0.8, 0.7);

    #if !defined COMPOSITE && !defined DEFERRED1
        vec3 nightClearLightColor = vec3(0.15, 0.14, 0.20) * (0.4 + vsBrightness * 0.4); //ground color
    #elif defined DEFERRED1
        vec3 nightClearLightColor = vec3(0.11, 0.14, 0.20) * 1.0; //cloud color
    #else
        vec3 nightClearLightColor = vec3(0.07, 0.12, 0.27) * (0.25 + vsBrightness * 0.25); //light shaft color
    #endif
    vec3 nightClearAmbientColor   = vec3(0.09, 0.12, 0.17) * (1.55 + vsBrightness * 0.77);

    vec3 dayRainLightColor   = vec3(0.11, 0.13, 0.2) * (0.75 + vsBrightness * 0.25);
    vec3 dayRainAmbientColor = dayRainLightColor * 3.5;

    vec3 nightRainLightColor   = vec3(0.005, 0.0055, 0.0095);
    vec3 nightRainAmbientColor = vec3(0.1, 0.11, 0.19) * (1.5 + vsBrightness * 0.5);

    vec3 dayLightColor   = mix(noonClearLightColor, sunsetClearLightColor, invNoonFactor);
    vec3 dayAmbientColor = mix(noonClearAmbientColor, sunsetClearAmbientColor, invNoonFactor);

    vec3 clearLightColor   = mix(nightClearLightColor, dayLightColor, sunVisibility2);
    vec3 clearAmbientColor = mix(nightClearAmbientColor, dayAmbientColor, sunVisibility2);

    vec3 rainLightColor   = mix(nightRainLightColor, dayRainLightColor, sunVisibility2) * 2.0;
    vec3 rainAmbientColor = mix(nightRainAmbientColor, dayRainAmbientColor, sunVisibility2);

    vec3 lightColor   = mix(clearLightColor, rainLightColor, rainFactor);
    vec3 ambientColor = mix(clearAmbientColor, rainAmbientColor, rainFactor);
#elif defined NETHER
    vec3 netherColor  = max(normalize(sqrt(fogColor)), vec3(0.0));
    vec3 lightColor   = vec3(0.0);
    vec3 ambientColor = netherColor * (0.35 + 0.1 * vsBrightness);
#elif defined END
    vec3 endLightColor = vec3(0.65, 0.50, 1.0);
    vec3 lightColor    = endLightColor * (0.09 + 0.03 * vsBrightness);
    vec3 ambientColor  = endLightColor * (0.45 + 0.10 * vsBrightness);
#endif

#endif