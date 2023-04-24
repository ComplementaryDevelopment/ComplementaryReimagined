#if MC_VERSION >= 11300
    vec3 glColorM = glColor.rgb;
    glColorM.g = max(glColorM.g, 0.35);
    glColorM = sqrt1(glColorM) * vec3(1.0, 0.85, 0.8);

    #if WATER_STYLE < 3
        vec3 colorPM = pow2(colorP.rgb);
        color.rgb = colorPM * glColorM;
    #else
        vec3 colorPM = vec3(0.25);
        color.rgb = 0.375 * glColorM;
    #endif
#else
    #if WATER_STYLE < 3
        color.rgb = mix(color.rgb, vec3(GetLuminance(color.rgb)), 0.88);
        color.rgb = pow2(color.rgb) * vec3(2.3, 3.5, 3.1) * 0.9;
    #else
        color.rgb = vec3(0.13, 0.2, 0.27);
    #endif
#endif

#define PHYSICS_OCEAN_INJECTION
#if defined GENERATED_NORMALS && (WATER_STYLE >= 2 || defined PHYSICS_OCEAN)
    noGeneratedNormals = true;
#endif

#ifdef GBUFFERS_WATER
    lmCoordM.y = min(lmCoord.y * 1.07, 1.0); // Iris/Sodium skylight inconsistency workaround

    reflectMult = 1.0;

	#if WATER_QUALITY >= 3
		materialMask = OSIEBCA * 241.0; // Water
	#endif

    #if WATER_QUALITY >= 2 || WATER_STYLE >= 2
        vec2 wind = vec2(frameTimeCounter * 0.018, 0.0);
        vec3 worldPos = playerPos + cameraPosition;
        vec2 waterPos = worldPos.xz * 16.0;
        #if WATER_STYLE < 3
             waterPos = floor(waterPos);
        #endif
        waterPos = 0.002 * (waterPos + worldPos.y * 32.0);
    #endif

    #if WATER_STYLE >= 2 || RAIN_PUDDLES >= 1 && WATER_STYLE == 1
        #if WATER_STYLE >= 2
            vec3 normalMap = vec3(0.0, 0.0, 1.0);
            vec2 waterPosM = waterPos;

            #if WATER_STYLE < 3
                normalMap.xy += texture2D(noisetex, waterPosM + wind * 0.5).rg - 0.5;
                waterPosM *= 0.5;
                normalMap.xy -= texture2D(noisetex, waterPosM - wind).rg - 0.5;
                waterPosM *= 0.5;
                normalMap.xy -= texture2D(noisetex, waterPosM + wind).rg - 0.5;
                normalMap.xy *= WATER_BUMPINESS * 0.8;
            #else
                waterPosM *= 0.35;
                vec2 parallaxMult = 0.0005 * viewVector.xy / lViewPos;
                float normalOffset = 0.002;

                for (int i = 0; i < 4; i++) {
                    float height = 0.5 - GetWaterHeightMap(waterPosM, nViewPos, wind);
                    waterPosM += parallaxMult * pow2(height);
                }

                float h1 = GetWaterHeightMap(waterPosM + vec2( normalOffset, 0.0), nViewPos, wind);
                float h2 = GetWaterHeightMap(waterPosM + vec2(-normalOffset, 0.0), nViewPos, wind);
                float h3 = GetWaterHeightMap(waterPosM + vec2(0.0,  normalOffset), nViewPos, wind);
                float h4 = GetWaterHeightMap(waterPosM + vec2(0.0, -normalOffset), nViewPos, wind);

                normalMap.xy = vec2(h1 - h2, h3 - h4) * WATER_BUMPINESS;
            #endif

            normalMap.xy *= 0.03 * lmCoordM.y + 0.01;
            vec3 minNormal = mix(normal, vec3(-1.0), pow2(1.0 - fresnel));
        #else
            float pNormalMult = 0.02 * rainFactor * isRainy * pow2(lmCoordM.y);

            if (pNormalMult > 0.0005) {       
                vec2 puddlePos = floor((playerPos.xz + cameraPosition.xz) * 16.0) * 0.00625;

                vec2 puddleWind = vec2(frameTimeCounter) * 0.015;
                vec2 pNormalCoord1 = puddlePos + vec2(puddleWind.x, puddleWind.y);
                vec2 pNormalCoord2 = puddlePos + vec2(puddleWind.x * -1.5, puddleWind.y * -1.0);
                vec3 pNormalNoise1 = texture2D(noisetex, pNormalCoord1).rgb;
                vec3 pNormalNoise2 = texture2D(noisetex, pNormalCoord2).rgb;
                
                vec3 normalMap = vec3((pNormalNoise1.xy + pNormalNoise2.xy - vec2(1.0)) * pNormalMult, 1.0);
                vec3 minNormal = vec3(-1.0);

        #endif

            normalM = clamp(normalize(normalMap * tbnMatrix), minNormal, vec3(1.0));

        #if WATER_STYLE == 1
            }
        #endif

        #if WATER_STYLE >= 3
            fresnel = clamp(1.0 + dot(normalM, nViewPos), 0.0, 1.0);
        #endif
    #endif

    float fresnel2 = pow2(fresnel);
    float fresnel4 = pow2(fresnel2);

    #if WATER_QUALITY >= 2
        // Noise Coloring
        float noise = texture2D(noisetex, (waterPos + wind) * 0.25).g;
              noise = noise - 0.5;
              noise *= 0.25;
        color.rgb = pow(color.rgb, vec3(1.0 + noise));
        
        if (isEyeInWater != 1) {
            float depthT = texelFetch(depthtex1, texelCoord, 0).r;
            vec3 screenPosT = vec3(screenCoord, depthT);
            #ifdef TAA
                vec3 viewPosT = ScreenToView(vec3(TAAJitter(screenPosT.xy, -0.5), screenPosT.z));
            #else
                vec3 viewPosT = ScreenToView(screenPosT);
            #endif
            float lViewPosT = length(viewPosT);
            float lViewPosDif = lViewPos - lViewPosT;
            
            #if WATER_STYLE < 3
                color.a = sqrt1(color.a);
            #else
                color.a = 0.98;
            #endif

            float waterFog = max0(1.0 - exp(lViewPosDif * 0.075));
            color.a *= 0.25 + 0.75 * waterFog;
        
            // Water Foam
            if (NdotU > 0.99) {
                vec3 matrixM = vec3(
                    gbufferModelViewInverse[0].y,
                    gbufferModelViewInverse[1].y,
                    gbufferModelViewInverse[2].y
                );
                float playerPosTY = dot(matrixM, viewPosT) + gbufferModelViewInverse[3].y;
                float yPosDif = playerPosTY - playerPos.y;

                #if WATER_STYLE < 3 && MC_VERSION >= 11300
                    float dotColorPM = dot(colorPM, colorPM);
                    float foamThreshold = min(pow2(dotColorPM) * 1.6, 1.2);
                #else
                    float foamThreshold = pow2(texture2D(noisetex, waterPos * 4.0 + wind * 0.5).g) * 1.2;
                #endif
                float foam = pow2(clamp((foamThreshold + yPosDif) / foamThreshold, 0.0, 1.0));
                #ifndef END
                    foam *= 0.4 + 0.25 * lmCoord.y;
                #else
                    foam *= 0.6;
                #endif
                foam *= clamp((fract(worldPos.y) - 0.7) * 10.0, 0.0, 1.0);

                color = mix(color, vec4(0.9, 0.95, 1.05, 1.0), foam);
                reflectMult = 1.0 - foam;
            }
        } else {
            noDirectionalShading = true;

            reflectMult = 0.5;
            //shadowMult = vec3(2.0);
            //color.a *= 0.5;

            #if MC_VERSION < 11300 && WATER_STYLE >= 3
                color.a = 0.7;
            #endif
        }
    #else
        shadowMult = vec3(0.0); 
    #endif

    // Final Tweaks
    reflectMult *= 0.5 + 0.5 * NdotUmax0;

    #if WATER_STYLE >= 3
        color.rgb *= 1.0 + pow2(fresnel);
    #endif
    
    #if MC_VERSION >= 11300
        // Blending 
        translucentMultCalculated = true;
        translucentMult.rgb = normalize(sqrt2(glColor.rgb));
        translucentMult.g *= 0.88;
        
        color.a = mix(color.a, 1.0, fresnel4);
    #endif

    // Highlight
    #if WATER_STYLE < 3
        smoothnessG = 0.5;
        highlightMult = min(pow2(pow2(dot(colorP.rgb, colorP.rgb) * 0.4)), 0.5) * (16.0 - 15.0 * fresnel2) * (sunVisibility > 0.5 ? 1.0 : 0.5);
    #else
        smoothnessG = 0.5;
        highlightMult = 0.4 - 0.375 * fresnel2;
    #endif
#endif