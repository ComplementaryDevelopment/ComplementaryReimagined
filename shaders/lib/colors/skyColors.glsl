#ifndef INCLUDE_SKY_COLORS
#define INCLUDE_SKY_COLORS

#ifdef OVERWORLD
    vec3 skyColorSqrt = sqrt(skyColor);

    vec3 noonUpSkyColor     = pow(skyColor, vec3(1.32)) * 0.8;
    vec3 noonMiddleSkyColor = skyColorSqrt * 1.2;
    vec3 noonDownSkyColor   = noonUpSkyColor;

    vec3 sunsetUpSkyColor     = pow(skyColor, vec3(1.12)) * vec3(0.75, 0.57, 0.57);
    vec3 sunsetMiddleSkyColor = skyColorSqrt * 1.1;
    vec3 sunsetDownSkyColor   = vec3(0.92, 0.56, 0.44);

    vec3 dayUpSkyColor     = mix(noonUpSkyColor, sunsetUpSkyColor, invNoonFactor)         * mix(vec3(1.1), vec3(0.7, 0.75, 1.0) * 0.6, rainFactor);
    vec3 dayMiddleSkyColor = mix(noonMiddleSkyColor, sunsetMiddleSkyColor, invNoonFactor) * mix(vec3(1.0), vec3(0.6, 0.65, 0.8) * 0.6, rainFactor);
    vec3 dayDownSkyColor   = mix(noonDownSkyColor, sunsetDownSkyColor * 0.5, invNoonFactor);

    vec3 nightColFactor      = mix(vec3(0.07, 0.14, 0.24), vec3(0.04, 0.06, 0.12) * 0.6, rainFactor);
    vec3 nightUpSkyColor     = pow(nightColFactor + skyColor, vec3(0.90)) * 0.4;
    vec3 nightMiddleSkyColor = pow(nightUpSkyColor, vec3(0.75)) * 1.3;
    vec3 nightDownSkyColor   = nightUpSkyColor * 1.3;
#elif defined NETHER
    vec3 netherSkyColor = pow(fogColor, vec3(0.6, 0.75, 0.75));
#endif

#endif