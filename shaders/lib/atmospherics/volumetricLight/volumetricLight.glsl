vec4 DistortShadow(vec4 shadowpos, float distortFactor) {
    shadowpos.xy *= 1.0 / distortFactor;
    shadowpos.z = shadowpos.z * 0.2;
    shadowpos = shadowpos * 0.5 + 0.5;

    return shadowpos;
}

vec4 GetVolumetricLight(inout float vlFactor, vec3 translucentMult, float lViewPos0, float lViewPos1, vec3 nViewPos, float VdotL, float VdotU, float z0, float z1, float z1lod, float dither) {
// ============================== Step 1: Prepare Factors ============================== //
    float vlMult = 1.0 - maxBlindnessDarkness;

    #ifdef OVERWORLD
        vec3 vlColor = lightColor;
        vec3 vlColorReducer = vec3(1.0);
        float vlSceneIntensity = isEyeInWater != 1 ? vlFactor : 1.0;

        #ifdef SPECIAL_BIOME_WEATHER
            vlSceneIntensity = mix(vlSceneIntensity, 1.0, inDry * rainFactor);
            vlColor *= 1.0 + 0.6 * inDry * rainFactor;
        #endif

        if (sunVisibility < 0.5) {
            vlSceneIntensity = 0.0;
            
            float vlMultNightModifier = (0.3 + 0.4 * rainFactor2 + 0.5 * max0(far - lViewPos1) / far);
            #ifdef SPECIAL_PALE_GARDEN_LIGHTSHAFTS
                vlMultNightModifier = mix(vlMultNightModifier, 1.0, inPaleGarden);
            #endif
            vlMult *= vlMultNightModifier;

            vlColor = normalize(pow(vlColor, vec3(1.0 - max0(1.0 - 1.5 * nightFactor) + rainFactor)));
            vlColor *= 0.0766 + 0.0766 * vsBrightness;
        } else {
            vlColorReducer = 1.0 / sqrt(vlColor);
        }

        #ifdef SPECIAL_PALE_GARDEN_LIGHTSHAFTS
            vlSceneIntensity = mix(vlSceneIntensity, 1.0, inPaleGarden);
            vlMult *= 1.0 + (3.0 * inPaleGarden) * (1.0 - sunVisibility);
        #endif

        float rainyNight = (1.0 - sunVisibility) * rainFactor;
        float VdotLM = max((VdotL + 1.0) / 2.0, 0.0);
        float VdotUmax0 = max(VdotU, 0.0);
        float VdotUM = mix(pow2(1.0 - VdotUmax0), 1.0, 0.5 * vlSceneIntensity);
              VdotUM = smoothstep1(VdotUM);
              VdotUM = pow(VdotUM, min(lViewPos1 / far, 1.0) * (3.0 - 2.0 * vlSceneIntensity));

        float vlTime = min(abs(SdotU) - 0.05, 0.15) / 0.15;
        vlMult *= mix(VdotUM * VdotLM, 1.0, 0.4 * rainyNight) * vlTime;

        vlMult *= mix(invNoonFactor2 * 0.875 + 0.125, 1.0, max(vlSceneIntensity, rainFactor2));
        vlMult *= 1.4 - 0.4 * rainFactor;
    #elif defined END
        vec3 vlColorReducer = vec3(1.0);
    #endif

    if (vlMult < 0.0001) return vec4(0.0);
// ============================== End of Step 1 ============================== //

// ============================== Step 2: Prepare Tracing Variables  ============================== //
    vec4 volumetricLight = vec4(0.0);

    #if SHADOW_QUALITY > -1 && !defined IS_IRIS
        // Optifine for some reason doesn't provide correct shadowMapResolution if Shadow Quality isn't 1x
        vec2 shadowMapResolutionM = textureSize(shadowtex0, 0);
    #else
        vec2 shadowMapResolutionM = vec2(shadowMapResolution);
    #endif

    bool sky = z1 == 1.0;
    #if defined VOXY || defined DISTANT_HORIZONS
        sky = sky && z1lod == 1.0;
    #endif
    
    #if LIGHTSHAFT_QUALI_DEFINE == 0 || LIGHTSHAFT_QUALI_DEFINE == 1 // OFF - Function still active in the End dimension || Low
        int nearSamples = 6;
    #elif LIGHTSHAFT_QUALI_DEFINE == 2 // Medium (Default)
        int nearSamples = 10;
    #elif LIGHTSHAFT_QUALI_DEFINE == 3 // High (Default on Ultra profile)
        int nearSamples = 15;
    #elif LIGHTSHAFT_QUALI_DEFINE == 4 // Very High
        int nearSamples = 30;
    #endif

    // Balance Defining Variables
    #ifdef OVERWORLD
        int farSamples = 1;
        float fogCurve = 0.9; // 1.0 = linear fog
        float fogCurveIntense = 0.5;
        float sampleDistribution = 2.0; // sample distribution power (higher values push near samples closer to camera)
        float sampleDistributionFar = 2.5;

        float maxDistance = far * 0.98; // The distance where the fog is 1.0 and we stop tracing
        float qualityThreshold = min(far, shadowDistance) * 0.98; // Only use farSamples from this point on to hit our maxDistance. Set higher than maxDistance to disable far samples
        
        #if defined VOXY || defined DISTANT_HORIZONS
            maxDistance = renderDistance * 0.5; // Covers lod chunks

            fogCurve = 0.7;
            fogCurveIntense *= 1.0 - 0.5 * rainFactor;
        #endif

        maxDistance = max(maxDistance, 128.0);

        // Tweaks for intense situations
        if (isEyeInWater == 1) {
            maxDistance = mix(maxDistance, 128.0, isEyeInWater == 1);
            #if WATER_FOG_MULT != 100
                #define WATER_FOG_MULT_M WATER_FOG_MULT * 0.01;
                maxDistance /= WATER_FOG_MULT_M;
            #endif
        }
        qualityThreshold = mix(qualityThreshold, 100.0, vlSceneIntensity);
        fogCurve = mix(fogCurve, fogCurveIntense, max(vlSceneIntensity, rainFactor));
        nearSamples = int(mix(float(nearSamples), 1.5 * nearSamples, vlSceneIntensity));
        sampleDistribution = mix(sampleDistribution, 1.5, vlSceneIntensity);
    #elif defined END
        int farSamples = nearSamples;
        float fogCurve = 0.55;
        float sampleDistribution = 1.3;
        float sampleDistributionFar = 2.5;
        
        nearSamples *= 3;

        #if !defined VOXY && !defined DISTANT_HORIZONS
            float maxDistance = 1536; // 96 chunks
            float beamScale = 1.0;
        #else
            float maxDistance = max(1536.0, renderDistance * 0.5);
            float beamScale = 1536.0 / maxDistance;
        #endif

        float qualityThreshold = min(far, shadowDistance) * 0.98;
    #endif

    #ifdef COMPOSITE // Reflections
        nearSamples /= 2;
        farSamples /= 2;
    #endif

    vec3 nViewPosInSceneSpace = normalize(mat3(gbufferModelViewInverse) * nViewPos);
    vec3 rayDirection = nViewPosInSceneSpace;
    float rayEnd = !sky ? min(lViewPos1, maxDistance) : maxDistance; 
    float lastDistance = 0.0;

    #if defined END && !defined VOXY && !defined DISTANT_HORIZONS
        float fog = lViewPos0 / far;
        fog = pow2(pow2(fog));
        fog = 1.0 - exp(-3.0 * fog);

        rayEnd = mix(rayEnd, maxDistance, fog);
        lViewPos0 = mix(lViewPos0, maxDistance, fog);
    #endif

    #ifdef LIGHTSHAFT_SMOKE
        float smokePower = pow2(1.0 - rayEnd / maxDistance);
    #endif

    float activeThreshold = min(qualityThreshold, maxDistance);
    int totalSamples = (rayEnd <= qualityThreshold) ? nearSamples : (nearSamples + farSamples);
// ============================== End of Step 2 ============================== //

// ============================== Step 3: Execute Volumetric Tracing ============================== //
    for (int i = 0; i <= totalSamples; i++) {
        float nextDistance;
        vec3 scenePos;
        vec3 localDensity = vec3(1.0);

        if (i <= nearSamples) { // Actual light shaft sampling near-field section
            float t = (float(i) + dither) / float(nearSamples);
            nextDistance = pow(t, sampleDistribution) * activeThreshold;
            scenePos = rayDirection * nextDistance;

            if (nextDistance >= rayEnd) break;

            // Shadow Sampling
            localDensity = vec3(1.0);
            #if SHADOW_QUALITY > -1 && defined  COMPOSITE1
                vec3 shadowPos = GetShadowPos(scenePos);
                if (length(shadowPos.xy * 2.0 - 1.0) < 1.0) {
                    // 28A3DK6 We need to use texelFetch here or a lot of Nvidia GPUs can't get a valid value
                    float shadowSample = texelFetch(shadowtex0, ivec2(shadowPos.xy * shadowMapResolutionM), 0).x;
                          shadowSample = clamp((shadowSample - shadowPos.z) * 65536.0, 0.0, 1.0);

                    localDensity = vec3(shadowSample);

                    #if SHADOW_QUALITY >= 1
                        if (shadowSample == 0.0) {
                            float translucentShadowSample = shadow2D(shadowtex1, shadowPos.xyz).z;
                            if (translucentShadowSample == 1.0) {
                                vec3 shadowColorSample = texture2D(shadowcolor1, shadowPos.xy).rgb * 4.0;
                                localDensity = pow2(shadowColorSample) * vlColorReducer;
                            }
                        } else {
                            #ifdef OVERWORLD
                                // For water-tinting the water surface when observed from below the surface
                                if (translucentMult != vec3(1.0) && nextDistance > lViewPos0) {
                                    vec3 tinter = vec3(1.0);
                                    if (isEyeInWater == 1) {
                                        vec3 translucentMultM = translucentMult * 2.8;
                                        tinter = pow(translucentMultM, vec3(sunVisibility * 3.0 * clamp01(scenePos.y * 0.03)));
                                    } else {
                                        tinter = 0.1 + 0.9 * pow2(pow2(translucentMult * 1.7));
                                    }
                                    localDensity *= mix(vec3(1.0), tinter, clamp01(oceanAltitude - cameraPosition.y));
                                }
                            #endif

                            if (isEyeInWater == 1 && translucentMult == vec3(1.0)) localDensity = vec3(0.0);
                        }
                    #endif
                }
            #endif
        }
        
        else { // Far field low sample section
            float t = (float(i - nearSamples) + dither) / float(farSamples);
            nextDistance = mix(activeThreshold, maxDistance, pow(t, sampleDistributionFar));
            scenePos = rayDirection * nextDistance;

            if (nextDistance >= rayEnd) {
                nextDistance = rayEnd;
                #ifdef END
                    break;
                #endif
            }

            #ifdef OVERWORLD
                localDensity = vec3(eyeBrightnessM);
            #elif defined END
                localDensity = vec3(1.0);
            #endif
        }

        #ifdef LIGHTSHAFT_SMOKE
            vec3 smokePos = 0.0015 * (scenePos + cameraPosition);
            vec3 smokeWind = frameTimeCounter * vec3(0.0, 0.001, -0.002);
            float smoke = 0.65 * Noise3D(smokePos + smokeWind)
                        + 0.25 * Noise3D((smokePos - smokeWind) * 3.0)
                        + 0.10 * Noise3D((smokePos + smokeWind) * 9.0);
            smoke = smoothstep1(smoothstep1(smoothstep1(smoke)));
            localDensity *= pow(smoke, smokePower);
        #endif

        // For fog density to not move regardless of how we distribute the samples
        float currentWeight = smoothstep1(pow(lastDistance / maxDistance, fogCurve));
        float nextWeight    = smoothstep1(pow(nextDistance / maxDistance, fogCurve));
        float sliceWeight   = nextWeight - currentWeight;

        vec4 stepResult = vec4(localDensity * sliceWeight, sliceWeight);
        
        // Result Coloring
        if (nextDistance > lViewPos0) stepResult.rgb *= translucentMult;
        #ifdef END
            vec3 beamPos = scenePos;
            stepResult.rgb *= DrawEnderBeams(beamPos, nViewPos, beamScale);
        #endif
        
        volumetricLight += stepResult;

        lastDistance = nextDistance;
    }
// ============================== End of Step 3 ============================== //

// ============================== Step 4: Calculate factor of Scene Aware Light Shafts ============================== //
    #if defined OVERWORLD && LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 && defined COMPOSITE1
        if (viewWidth + viewHeight - gl_FragCoord.x - gl_FragCoord.y < 1.5) {
            if (frameCounter % int(0.06666 / frameTimeSmooth + 0.5) == 0) { // Change speed is not too different above 10 fps
                int salsX = 5;
                int salsY = 5;
                float heightThreshold = 6.0;

                vec2 viewM = 1.0 / vec2(salsX, salsY);
                float salsSampleSum = 0.0;
                int salsSampleCount = 0;
                for (float i = 0.25; i < salsX; i++) {
                    for (float h = 0.45; h < salsY; h++) {
                        vec2 coord = 0.3 + 0.4 * viewM * vec2(i, h);
                        ivec2 icoord = ivec2(coord * shadowMapResolutionM);
                        float salsSample = texelFetch(shadowtex0, icoord, 0).x; // read 28A3DK6
                        if (salsSample < 0.55) {
                            float sampledHeight = texture2D(shadowcolor1, coord).a;
                            if (sampledHeight > 0.0) {
                                sampledHeight = max0(sampledHeight - 0.25) / 0.05; // consistencyMEJHRI7DG
                                salsSampleSum += sampledHeight;
                                salsSampleCount++;
                            }
                        }
                    }
                }

                float salsCheck = salsSampleSum / salsSampleCount;
                int reduceAmount = 2;

                int skyCheck = 0;
                for (float i = 0.1; i < 1.0; i += 0.2) {
                    skyCheck += int(texelFetch(depthtex0, ivec2(view.x * i, view.y * 0.9), 0).x == 1.0);
                }
                if (skyCheck >= 4) {
                    salsCheck = 0.0;
                    reduceAmount = 3;
                }

                if (salsCheck > heightThreshold) {
                    vlFactor = min(vlFactor + OSIEBCA, 1.0);
                } else {
                    vlFactor = max(vlFactor - OSIEBCA * reduceAmount, 0.0);
                }
            }
        } else vlFactor = 0.0;
    #endif
// ============================== End of Step 4 ============================== //

// ============================== Step 5: Final Tweaks ============================== //
    #ifdef OVERWORLD
        vlColor = pow(vlColor, vec3(0.5 + (0.5 + LIGHTSHAFT_SUNSET_SATURATION * sunVisibility) * invNoonFactor * invRainFactor + 0.3 * rainFactor));
        vlColor *= 1.0 - (0.3 + 0.3 * noonFactor) * rainFactor - 0.5 * rainyNight + sunVisibility * pow2(invNoonFactor) * invRainFactor;

        #if LIGHTSHAFT_DAY_I != 100 || LIGHTSHAFT_NIGHT_I != 100 || LIGHTSHAFT_RAIN_I != 100
            #define LIGHTSHAFT_DAY_IM LIGHTSHAFT_DAY_I * 0.01
            #define LIGHTSHAFT_NIGHT_IM LIGHTSHAFT_NIGHT_I * 0.01
            #define LIGHTSHAFT_RAIN_IM LIGHTSHAFT_RAIN_I * 0.01

            if (isEyeInWater == 0) {
                #if LIGHTSHAFT_DAY_I != 100 || LIGHTSHAFT_NIGHT_I != 100
                    vlMult *= mix(LIGHTSHAFT_NIGHT_IM, LIGHTSHAFT_DAY_IM, sunVisibility);
                #endif
                #if LIGHTSHAFT_RAIN_I != 100
                    vlMult *= mix(1.0, LIGHTSHAFT_RAIN_IM, rainFactor);
                #endif
            }
        #endif

        volumetricLight.rgb *= vlColor;
    #elif defined END
        
    #endif

    volumetricLight.rgb *= vlMult;

    volumetricLight = max(volumetricLight, vec4(0.0)); // Fixes rare nans
// ============================== End of Step 5 ============================== //

    return volumetricLight;
}