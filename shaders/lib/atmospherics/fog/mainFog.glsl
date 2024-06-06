#ifdef ATM_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif
#ifdef MOON_PHASE_INF_ATMOSPHERE
    #include "/lib/colors/moonPhaseInfluence.glsl"
#endif

#ifdef BORDER_FOG
    #ifdef OVERWORLD
        #include "/lib/atmospherics/sky.glsl"
    #elif defined NETHER
        #include "/lib/colors/skyColors.glsl"
    #endif

    void DoBorderFog(inout vec3 color, inout float skyFade, float lPos, float VdotU, float VdotS, float dither) {
        #ifdef OVERWORLD
            float fog = lPos / renderDistance;
            fog = pow2(pow2(fog));
            #ifndef DISTANT_HORIZONS
                fog = pow2(pow2(fog));
            #endif
            fog = 1.0 - exp(-3.0 * fog);
        #endif
        #ifdef NETHER
            float farM = min(renderDistance, NETHER_VIEW_LIMIT); // consistency9023HFUE85JG
            float fog = lPos / farM;
            fog = fog * 0.3 + 0.7 * pow(fog, 256.0 / max(farM, 256.0));
        #endif
        #ifdef END
            float fog = lPos / renderDistance;
            fog = pow2(pow2(fog));
            fog = 1.0 - exp(-3.0 * fog);
        #endif

        #ifdef DREAM_TWEAKED_BORDERFOG
            fog *= fog * 0.5;
        #endif

        if (fog > 0.0) {
            fog = clamp(fog, 0.0, 1.0);

            #ifdef OVERWORLD
                vec3 fogColorM = GetSky(VdotU, VdotS, dither, true, false);
            #elif defined NETHER
                vec3 fogColorM = netherColor;
            #else
                vec3 fogColorM = endSkyColor;
            #endif

            #ifdef ATM_COLOR_MULTS
                fogColorM *= atmColorMult;
            #endif
            #ifdef MOON_PHASE_INF_ATMOSPHERE
                fogColorM *= moonPhaseInfluence;
            #endif

            color = mix(color, fogColorM, fog);

            #ifndef GBUFFERS_WATER
                skyFade = fog;
            #else
                skyFade = fog * (1.0 - isEyeInWater);
            #endif
        }
    }
#endif

#ifdef CAVE_FOG
    #include "/lib/atmospherics/fog/caveFactor.glsl"

    void DoCaveFog(inout vec3 color, float lViewPos) {
        float fog = GetCaveFactor() * (0.9 - 0.9 * exp(- lViewPos * 0.015));

        color = mix(color, caveFogColor, fog);
    }
#endif

#ifdef ATMOSPHERIC_FOG
    #include "/lib/colors/lightAndAmbientColors.glsl"
    #include "/lib/colors/skyColors.glsl"

    // SRATA: Atm. fog starts reducing above this altitude
    // CRFTM: Atm. fog continues reducing for this meters
    #ifdef OVERWORLD
        #define atmFogSRATA ATM_FOG_ALTITUDE + 0.1
        #ifndef DISTANT_HORIZONS
            float atmFogCRFTM = 60.0;
        #else
            float atmFogCRFTM = 90.0;
        #endif

        vec3 GetAtmFogColor(float altitudeFactorRaw, float VdotS) {
            float nightFogMult = 2.5 - 0.625 * max(pow2(pow2(altitudeFactorRaw)), rainFactor);
            float dayNightFogBlend = pow(invNightFactor, 4.0 - VdotS - 2.5 * sunVisibility2);
            return mix(
                nightUpSkyColor * (nightFogMult - dayNightFogBlend * nightFogMult),
                dayDownSkyColor * (0.9 + 0.2 * noonFactor),
                dayNightFogBlend
            );
        }
    #else
        float atmFogSRATA = 55.1;
        float atmFogCRFTM = 30.0;
    #endif

    float GetAtmFogAltitudeFactor(float altitude) {
        float altitudeFactor = pow2(1.0 - clamp(altitude - atmFogSRATA, 0.0, atmFogCRFTM) / atmFogCRFTM);
        #ifndef LIGHTSHAFTS_ACTIVE
            altitudeFactor = mix(altitudeFactor, 1.0, rainFactor * 0.2);
        #endif
        return altitudeFactor;
    }

    void DoAtmosphericFog(inout vec3 color, vec3 playerPos, float lViewPos, float VdotS) {
        #ifndef DISTANT_HORIZONS
            float renDisFactor = min1(192.0 / renderDistance);

            #if ATM_FOG_DISTANCE != 100
                #define ATM_FOG_DISTANCE_M 100.0 / ATM_FOG_DISTANCE;
                renDisFactor *= ATM_FOG_DISTANCE_M;
            #endif

            float fog = 1.0 - exp(-pow(lViewPos * (0.001 - 0.0007 * rainFactor), 2.0 - rainFactor2) * lViewPos * renDisFactor);
        #else
            float fog = pow2(1.0 - exp(-max0(lViewPos - 40.0) * (0.7 + 0.7 * rainFactor) / ATM_FOG_DISTANCE));
        #endif
        
        fog *= ATM_FOG_MULT - 0.1 - 0.15 * invRainFactor;

        float altitudeFactorRaw = GetAtmFogAltitudeFactor(playerPos.y + cameraPosition.y);
        
        #ifndef DISTANT_HORIZONS
            float altitudeFactor = altitudeFactorRaw * 0.9 + 0.1;
        #else
            float altitudeFactor = altitudeFactorRaw * 0.8 + 0.2;
        #endif

        #ifdef OVERWORLD
            altitudeFactor *= 1.0 - 0.75 * GetAtmFogAltitudeFactor(cameraPosition.y) * invRainFactor;

            #if defined SPECIAL_BIOME_WEATHER || RAIN_STYLE == 2
                #if RAIN_STYLE == 2
                    float factor = 1.0;
                #else
                    float factor = max(inSnowy, inDry);
                #endif

                float fogFactor = 4.0;
                #ifdef SPECIAL_BIOME_WEATHER
                    fogFactor += 2.0 * inDry;
                #endif

                float fogIntense = pow2(1.0 - exp(-lViewPos * fogFactor / ATM_FOG_DISTANCE));
                fog = mix(fog, fogIntense / altitudeFactor, 0.8 * rainFactor * factor);
            #endif

            #ifdef CAVE_FOG
                fog *= 0.2 + 0.8 * sqrt2(eyeBrightnessM);
                fog *= 1.0 - GetCaveFactor();
            #else
                fog *= eyeBrightnessM;
            #endif
        #else
            fog *= 0.5;
        #endif

        fog *= altitudeFactor;

        if (fog > 0.0) {
            fog = clamp(fog, 0.0, 1.0);

            #ifdef OVERWORLD
                vec3 fogColorM = GetAtmFogColor(altitudeFactorRaw, VdotS);
            #else
                vec3 fogColorM = endSkyColor * 1.5;
            #endif

            #ifdef ATM_COLOR_MULTS
                fogColorM *= atmColorMult;
            #endif
            #ifdef MOON_PHASE_INF_ATMOSPHERE
                fogColorM *= moonPhaseInfluence;
            #endif

            color = mix(color, fogColorM, fog);
        }
    }
#endif

#include "/lib/atmospherics/fog/waterFog.glsl"

void DoWaterFog(inout vec3 color, float lViewPos) {
    float fog = GetWaterFog(lViewPos);

    color = mix(color, waterFogColor, fog);
}

void DoLavaFog(inout vec3 color, float lViewPos) {
    float fog = (lViewPos * 3.0 - gl_Fog.start) * gl_Fog.scale;

    #ifdef LESS_LAVA_FOG
        fog = sqrt(fog) * 0.4;
    #endif

    fog = 1.0 - exp(-fog);

    fog = clamp(fog, 0.0, 1.0);
    color = mix(color, fogColor * 5.0, fog);
}

void DoPowderSnowFog(inout vec3 color, float lViewPos) {
    float fog = lViewPos;

    #ifdef LESS_LAVA_FOG
        fog = sqrt(fog) * 0.4;
    #endif

    fog *= fog;
    fog = 1.0 - exp(-fog);

    fog = clamp(fog, 0.0, 1.0);
    color = mix(color, fogColor, fog);
}

void DoBlindnessFog(inout vec3 color, float lViewPos) {
    float fog = lViewPos * 0.3 * blindness;
    fog *= fog;
    fog = 1.0 - exp(-fog);

    fog = clamp(fog, 0.0, 1.0);
    color = mix(color, vec3(0.0), fog);
}

void DoDarknessFog(inout vec3 color, float lViewPos) {
    float fog = lViewPos * 0.075 * darknessFactor;
    fog *= fog;
    fog *= fog;
    color *= exp(-fog);
}

void DoFog(inout vec3 color, inout float skyFade, float lViewPos, vec3 playerPos, float VdotU, float VdotS, float dither) {
    #ifdef CAVE_FOG
        DoCaveFog(color, lViewPos);
    #endif
    #ifdef ATMOSPHERIC_FOG
        DoAtmosphericFog(color, playerPos, lViewPos, VdotS);
    #endif
    #ifdef BORDER_FOG
        DoBorderFog(color, skyFade, max(length(playerPos.xz), abs(playerPos.y)), VdotU, VdotS, dither);
    #endif

    if (isEyeInWater == 1) DoWaterFog(color, lViewPos);
    else if (isEyeInWater == 2) DoLavaFog(color, lViewPos);
    else if (isEyeInWater == 3) DoPowderSnowFog(color, lViewPos);

    if (blindness > 0.00001) DoBlindnessFog(color, lViewPos);
    if (darknessFactor > 0.00001) DoDarknessFog(color, lViewPos);
}