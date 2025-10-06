vec3 cloudRainColor = mix(nightMiddleSkyColor, dayMiddleSkyColor, sunFactor);
vec3 cloudAmbientColor = mix(ambientColor * (sunVisibility2 * (0.55 + 0.17 * noonFactor) + 0.35), cloudRainColor * 0.5, rainFactor);
vec3 cloudLightColor   = mix(
    lightColor * 1.3,
    cloudRainColor * 0.45,
    noonFactor * rainFactor
);