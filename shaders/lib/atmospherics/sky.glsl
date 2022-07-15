#ifndef INCLUDE_SKY
#define INCLUDE_SKY

#include "/lib/colors/lightAndAmbientColors.glsl"
#include "/lib/colors/skyColors.glsl"

#ifdef CAVE_FOG
    #include "/lib/atmospherics/fog/caveFactor.glsl"
#endif

vec3 GetSky(float VdotU, float VdotS, float dither, bool doGlare, bool doGround) {
    // Prepare variables
    float nightFactorM = sqrt3(nightFactor) * 0.4;
    float VdotSM1 = pow2(max(VdotS, 0.0));
    float VdotSM2 = pow2(VdotSM1);
    float VdotSM3 = pow2(pow2(max(-VdotS, 0.0)));
    float VdotSML = sunVisibility > 0.5 ? VdotS : -VdotS;

    float VdotUmax0 = max(VdotU, 0.0);

    // Prepare colors
    vec3 upColor = mix(nightUpSkyColor * (1.0 + nightFactorM * VdotSM3 * 1.5), dayUpSkyColor, sunFactor);
    vec3 middleColor = mix(nightMiddleSkyColor, dayMiddleSkyColor * (1.0 + VdotSM2 * 0.3), sunFactor);
    vec3 downColor = mix(nightDownSkyColor, dayDownSkyColor, sunFactor);

    // Rain Tweaks 1
    downColor = mix(upColor, downColor, invRainFactor);

    // Mix the colors
        // Set sky gradient
        float VdotUM1 = pow2(1.0 - VdotUmax0);
              VdotUM1 = pow(VdotUM1, (1.0 - VdotUM1 * 0.5) * (1.0 - VdotSM2 * 0.4));
              VdotUM1 = mix(VdotUM1, 1.0, rainFactor2 * 0.2);
        vec3 finalSky = mix(upColor, middleColor, VdotUM1);

        // Add sunset color
        float VdotUM2 = pow2(1.0 - abs(VdotU));
              VdotUM2 = VdotUM2 * VdotUM2 * (3.0 - 2.0 * VdotUM2);
              VdotUM2 *= (0.7 - nightFactorM + VdotSM1 * (0.3 + nightFactorM)) * invNoonFactor * sunFactor;
        finalSky = mix(finalSky, sunsetDownSkyColor * (1.0 + VdotSM1 * 0.3), VdotUM2 * invRainFactor);

        // Add sky ground with fake light scattering
        float VdotUM3 = min(max(-VdotU + 0.1, 0.0) / 0.35, 1.0);
              VdotUM3 = smoothstep1(VdotUM3);
        vec3 scatteredGroundMixer = vec3(VdotUM3 * VdotUM3, sqrt1(VdotUM3), sqrt3(VdotUM3));
             scatteredGroundMixer = mix(vec3(VdotUM3), scatteredGroundMixer, 0.75);
             scatteredGroundMixer *= 0.42 * invRainFactor;
        finalSky = mix(finalSky, downColor, scatteredGroundMixer);
    //

    // Sky Ground
    if (doGround)
        finalSky *= smoothstep1(pow2(1.0 + min(VdotU, 0.0)));

    // Apply Underwater Fog
    if (isEyeInWater == 1)
        finalSky = mix(finalSky, waterFogColor, 1.0 - pow2(VdotUmax0));

    // Sun/Moon Glare
    if (doGlare) {
        if (0.0 < VdotSML) {
            float VdotSM4 = pow2(pow2(VdotS));
            if (VdotS < 0.0) VdotSM4 *= VdotSM4;
            float visfactor = 0.075;

            float glare = visfactor / (1.0 - (1.0 - visfactor) * VdotSM4) - visfactor;

            glare *= 0.5 - sunVisibility * invNoonFactor * 0.45;
            glare *= invRainFactor;

            if (isEyeInWater == 1) glare *= 10.0;

            finalSky += glare * shadowTime * sqrt(lightColor * 1.4);
        }
    }

    #ifdef CAVE_FOG
        // Apply Cave Fog
        finalSky = mix(finalSky, caveFogColor, GetCaveFactor());
    #endif

    // Dither to fix banding
    finalSky += (dither - 0.5) / 128.0;

    return finalSky;
}

#endif