#ifdef ATM_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif

#ifdef BORDER_FOG
    #ifdef OVERWORLD
        #include "/lib/atmospherics/sky.glsl"
    #elif defined NETHER
        #include "/lib/colors/skyColors.glsl"
    #endif

    void DoBorderFog(inout vec3 color, inout float skyFade, float lPlayerPosXZ, float VdotU, float VdotS, float dither) {
        #if defined OVERWORLD || defined END
            float fog = lPlayerPosXZ / far;
            fog *= fog;
            fog *= fog;
            fog *= fog;
            fog *= fog;
            fog = 1.0 - exp(-3.0 * fog);
        #endif
        #ifdef NETHER
            float farM = min(far, 256.0); // consistency9023HFUE85JG
            float fog = lPlayerPosXZ / farM;
            fog = pow(fog, 2.0 - farM / 256.0);
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
        float atmFogCRFTM = 60.0;
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
        float renDisFactor = min1(192.0 / far);

        #if ATM_FOG_DISTANCE != 100
            #define ATM_FOG_DISTANCE_M 100.0 / ATM_FOG_DISTANCE;
            renDisFactor *= ATM_FOG_DISTANCE_M;
        #endif

        float fog = 1.0 - exp(-pow(lViewPos * (0.001 - 0.0007 * rainFactor), 2.0 - rainFactor2) * lViewPos * renDisFactor);
              fog *= ATM_FOG_MULT - 0.1 - 0.15 * invRainFactor;
        
        float altitudeFactorP = GetAtmFogAltitudeFactor(playerPos.y + cameraPosition.y);
        float altitudeFactor = altitudeFactorP;

        #ifdef OVERWORLD
            altitudeFactor *= 1.0 - 0.75 * GetAtmFogAltitudeFactor(cameraPosition.y) * invRainFactor;

            #ifdef CAVE_FOG
                fog *= 0.2 + 0.8 * sqrt2(eyeBrightnessM);
                fog *= 1.0 - GetCaveFactor();
            #else
                fog *= eyeBrightnessM;
            #endif
        #endif

        fog *= altitudeFactor * 0.9 + 0.1;

        if (fog > 0.0) {
            fog = clamp(fog, 0.0, 1.0);

            #ifdef OVERWORLD
                float nightFogMult = 2.5 - 0.625 * pow2(pow2(altitudeFactorP));
                float dayNightFogBlend = pow(invNightFactor, 4.0 - VdotS - 2.5 * sunVisibility2);
                vec3 fogColorM = mix(
                    nightUpSkyColor * (nightFogMult - dayNightFogBlend * nightFogMult),
                    dayDownSkyColor * (0.9 + 0.2 * noonFactor),
                    dayNightFogBlend
                );
            #else
                vec3 fogColorM = endSkyColor;
            #endif

            #ifdef ATM_COLOR_MULTS
                fogColorM *= atmColorMult;
            #endif

	        #if DISTANT_HORIZONS_BLENDING == 1
                // Distant horizons blending
                vec3 localPos = (gbufferModelViewInverse * vec4(lViewPos)).xyz;
                localPos.y = 0;
                float fragDistance = length(localPos);
                fog = mix(fog, 0.0, smoothstep(0.0 * far, far, fragDistance));
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
    #if defined BORDER_FOG && DISTANT_HORIZONS_BLENDING == 0
        DoBorderFog(color, skyFade, length(playerPos.xz), VdotU, VdotS, dither);
    #endif

    if (isEyeInWater == 1) DoWaterFog(color, lViewPos);
    else if (isEyeInWater == 2) DoLavaFog(color, lViewPos);
    else if (isEyeInWater == 3) DoPowderSnowFog(color, lViewPos);
    
    if (blindness > 0.00001) DoBlindnessFog(color, lViewPos);
    if (darknessFactor > 0.00001) DoDarknessFog(color, lViewPos);
}
