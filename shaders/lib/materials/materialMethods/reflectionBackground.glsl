#if defined END && defined COMPOSITE
    #include "/lib/atmospherics/volumetricLight/enderBeams.glsl"
    #include "/lib/atmospherics/volumetricLight/volumetricLight.glsl"
#endif

void AddBackgroundReflection(inout vec4 reflection, vec3 color, vec3 playerPos, vec3 normalM, vec3 normalMR, vec3 nViewPos, vec3 nViewPosR,
                             vec3 shadowMult, float RVdotU, float RVdotS, float z0, float dither, float skyLightFactor, float smoothness, float highlightMult) {
    #ifdef OVERWORLD
        #if defined COMPOSITE || WATER_REFLECT_QUALITY >= 2
            vec3 skyReflection = GetSky(RVdotU, RVdotS, dither, isEyeInWater == 0, true);
        #else
            vec3 skyReflection = GetLowQualitySky(RVdotU, RVdotS, dither, isEyeInWater == 0, true);
        #endif

        #ifdef ATM_COLOR_MULTS
            skyReflection *= atmColorMult;
        #endif
        #ifdef MOON_PHASE_INF_ATMOSPHERE
            skyReflection *= moonPhaseInfluence;
        #endif

        #ifdef COMPOSITE
            skyReflection *= skyLightFactor;
        #else
            float specularHighlight = GGX(normalM, nViewPos, lightVec, max(dot(normalM, lightVec), 0.0), smoothness);
            skyReflection += specularHighlight * highlightColor * shadowMult * highlightMult * invRainFactor;
            
            #if WATER_REFLECT_QUALITY >= 1
                #ifdef SKY_EFFECT_REFLECTION
                    float cloudLinearDepth = 1.0;
                    float skyFade = 1.0;
                    vec3 auroraBorealis = vec3(0.0);
                    vec3 nightNebula = vec3(0.0);

                    #if AURORA_STYLE > 0
                        auroraBorealis = GetAuroraBorealis(nViewPosR, RVdotU, dither);
                        skyReflection += auroraBorealis;
                    #endif
                    #if NIGHT_NEBULAE == 1
                        nightNebula += GetNightNebula(nViewPosR, RVdotU, RVdotS);
                        skyReflection += nightNebula;
                    #endif
                    
                    vec2 starCoord = GetStarCoord(nViewPosR, 0.5);
                    skyReflection += GetStars(starCoord, RVdotU, RVdotS);

                    #ifdef VL_CLOUDS_ACTIVE
                        vec3 worldNormalMR = normalize(mat3(gbufferModelViewInverse) * normalMR);
                        vec3 cameraPosOffset = 2.0 * worldNormalMR * dot(playerPos, worldNormalMR);
                        vec3 RPlayerPos = normalize(mat3(gbufferModelViewInverse) * nViewPosR);
                        float RlViewPos = 100000.0;

                        vec4 clouds = GetClouds(cloudLinearDepth, skyFade, cameraPosOffset, RPlayerPos,
                                                RlViewPos, RVdotS, RVdotU, dither, auroraBorealis, nightNebula);

                        skyReflection = mix(skyReflection, clouds.rgb, clouds.a);
                    #endif
                #endif

                skyReflection = mix(color * 0.5, skyReflection, skyLightFactor);
            #else
                skyReflection = mix(color, skyReflection, skyLightFactor * 0.5);
            #endif
        #endif
    #elif defined END
        #ifdef COMPOSITE
            float vlFactorM = 0.0;
            vec3 translucentMult = vec3(1.0);
            float lViewPos = 100000.0;
            float lViewPos1 = 100000.0;
            
            vec4 volumetricEffect = GetVolumetricLight(vlFactorM, translucentMult, lViewPos, lViewPos1, nViewPosR, RVdotS, RVdotU, z0, z0, z0, dither);

            volumetricEffect.rgb = pow(volumetricEffect.rgb, vec3(1.0 / 2.2));
            vec3 skyReflection = volumetricEffect.rgb * 1.25 * skyLightFactor;
        #else
            vec3 skyReflection = endSkyColor * shadowMult;
        #endif

        #ifdef ATM_COLOR_MULTS
            skyReflection *= atmColorMult;
        #endif
    #else
        vec3 skyReflection = vec3(0.0);
    #endif

    #if WORLD_SPACE_REFLECTIONS_INTERNAL > 0 && defined COMPOSITE && (BLOCK_REFLECT_QUALITY >= 2 || WATER_REFLECT_QUALITY >= 2)
        float traceLength = far;
        vec4 wsrReflection = getWSR(playerPos, normalMR, nViewPosR, RVdotU, RVdotS, z0, dither, traceLength);
        refDist = min(refDist, traceLength);

        reflection = mix(wsrReflection, vec4(reflection.rgb, 1.0), reflection.a);
    #endif

    reflection.rgb = mix(skyReflection, reflection.rgb, reflection.a);
}