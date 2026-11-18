#ifndef INCLUDE_CLOUD_COLORS
    #define INCLUDE_CLOUD_COLORS
    vec3 cloudRainColor = mix(nightMiddleSkyColor, dayMiddleSkyColor * 0.875 + 0.375 * dayUpSkyColor, sunFactor);

    vec3 cloudAmbientColor = mix(ambientColor * (sunVisibility2 * (0.55 + vec3(0.2, 0.1, 0.0) * noonFactor) + 0.35), cloudRainColor * 0.5, rainFactor);

    vec3 cloudLightColor   = mix(
        lightColor * (
            1.3
            #ifdef CLOUDS_UNBOUND
                + vec3(0.1, -0.1, -0.3) * noonFactor
            #endif
        ),
        cloudRainColor * 0.45,
        noonFactor * rainFactor
    );
#endif
