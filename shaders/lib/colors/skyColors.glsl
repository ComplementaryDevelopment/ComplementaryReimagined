#ifndef INCLUDE_SKY_COLORS
#define INCLUDE_SKY_COLORS

#ifdef OVERWORLD
    float invNoonFactor2 = invNoonFactor * invNoonFactor;
    vec3 skyColorSqrt = sqrt(skyColor);
    
    vec3 noonUpSkyColor     = pow(skyColor, vec3(1.45)) * 0.85;
    vec3 noonMiddleSkyColor = skyColorSqrt * 1.15 + noonUpSkyColor * 0.6;
    vec3 noonDownSkyColor   = noonUpSkyColor;

    vec3 sunsetUpSkyColor     = skyColor * vec3(0.75, 0.6, 0.6) * 0.98;
    vec3 sunsetMiddleSkyColor = skyColor * vec3(1.1, 1.2, 1.3);
    vec3 sunsetDownSkyColor   = vec3(1.45, 0.86, 0.5);

    vec3 dayUpSkyColor     = mix(noonUpSkyColor, sunsetUpSkyColor, invNoonFactor2)         
                           * mix(vec3(1.1), vec3(0.7, 0.75, 0.9) * 0.4, rainFactor);
    vec3 dayMiddleSkyColor = mix(noonMiddleSkyColor, sunsetMiddleSkyColor, invNoonFactor2)
                           * mix(vec3(1.0), vec3(0.6, 0.65, 0.7) * 0.4, rainFactor);
    vec3 dayDownSkyColor   = mix(noonDownSkyColor, sunsetDownSkyColor * 0.5, invNoonFactor2);

    vec3 rainNC = vec3(0.012, 0.018, 0.036);
    vec3 nightColFactor      = mix(vec3(0.07, 0.14, 0.24) + skyColor, rainNC + 20.0 * rainNC * skyColor, rainFactor);
    vec3 nightUpSkyColor     = pow(nightColFactor, vec3(0.90)) * 0.4;
    vec3 nightMiddleSkyColor = sqrt(nightUpSkyColor) * 0.7;
    vec3 nightDownSkyColor   = nightUpSkyColor * 1.3;
#elif defined NETHER
    vec3 netherSkyColor = pow(fogColor, vec3(0.6, 0.75, 0.75));
#endif

#endif