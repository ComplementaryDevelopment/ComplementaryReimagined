float CLOUD_AMOUNT = 10.5;
float CLOUD_THICKNESS = 0.5;
float stretchFactor = 2.5;
float coordFactor = 0.009375;

float CloudNoise(vec2 coord) {
    float wind = syncedTime * 0.007;
    float noise = texture2D(noisetex, coord*0.5    + vec2(wind * 0.25, 0)).r * 7.0;
          noise+= texture2D(noisetex, coord*0.25   + vec2(wind * 0.15, 0)).r * 12.0;
          noise+= texture2D(noisetex, coord*0.125  + vec2(wind * 0.05, 0)).r * 12.0;
          noise+= texture2D(noisetex, coord*0.0625 + vec2(wind * 0.05, 0)).r * 24.0;
    return noise * 0.34;
}

float CloudCoverage(float noise, float coverage, float VdotU, float VdotS) {
    float sunMoonFactor = pow2(pow2(abs(VdotS)));
    float noiseCoverage = pow2(coverage) + CLOUD_AMOUNT
                        * (1.0 + sunMoonFactor * 0.175) 
                        * (1.0 + VdotU * 0.365 * (1.0 - rainFactor * 2.7))
                        - 2.5;
    return max(noise - noiseCoverage, 0.0);
}

vec4 DrawCloud(vec3 viewPos, float dither, float VdotS, float VdotU) {
    float cloudGradient = 0.0;
    float gradientMix = dither * 0.1667;

    float cloudHeight = 15.0 * pow2(max(1.11 - 0.0015 * cameraPosition.y, 0.0));

    float scatter = max0(pow2(VdotS));
    float dayNightFogBlend = pow(1.0 - nightFactor, 4.0 - VdotS - 3.0 * sunVisibility2);
    vec3 cloudRainColor = mix(nightMiddleSkyColor, dayUpSkyColor * 3.5, sunFactor);
    vec3 cloudClearAmbient = mix(nightClearAmbientColor * 0.3, 0.9 * dayAmbientColor, dayNightFogBlend);
    vec3 cloudClearLight = mix(nightClearLightColor * (1.7 + scatter), (0.9 + 0.4 * noonFactor + scatter) * dayLightColor, pow2(dayNightFogBlend));

    vec3 cloudAmbientColor = mix(cloudClearAmbient, cloudRainColor * 0.3, rainFactor);
    vec3 cloudLightColor   = mix(cloudClearLight, cloudRainColor * (1.0 + scatter), rainFactor);

    vec4 clouds = vec4(0.0);
    if (VdotU > 0.025) {
        vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
        for(int i = 0; i < 5; i++) {
            vec2 planeCoord = wpos.xz * ((cloudHeight + (i + dither) * stretchFactor) / wpos.y) * 0.0085;
            vec2 coord = cameraPosition.xz * 0.00025 + planeCoord;
            
            float ang1 = (i + syncedTime * 0.025) * 2.391;
            float ang2 = ang1 + 2.391;
            coord += mix(vec2(cos(ang1), sin(ang1)), vec2(cos(ang2), sin(ang2)), dither * 0.25 + 0.75) * coordFactor;
            
            float coverage = float(i - 3.0 + dither) * 0.725;
            
            float noise = CloudNoise(coord);
                  noise = CloudCoverage(noise, coverage, VdotU, VdotS) * CLOUD_THICKNESS;
                  noise = noise / sqrt(noise * noise + 1.0);
            
            cloudGradient = mix(cloudGradient,
                                mix(gradientMix * gradientMix, 1.0 - noise, 0.25),
                                noise * (1.0 - clouds.a));
            
            clouds.a += max(noise - clouds.a, 0.0);
            gradientMix += 0.2;
        }

        clouds.rgb = cloudAmbientColor + cloudLightColor * cloudGradient;

        clouds.a *= pow2(pow2(1.0 - exp(- 10.0 * VdotU)));
    }

    return clouds;
}