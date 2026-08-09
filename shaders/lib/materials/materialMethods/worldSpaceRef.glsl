#extension GL_ARB_shader_image_load_store : enable

#include "/lib/voxelization/reflectionVoxelization.glsl"
#include "/lib/lighting/minimumLighting.glsl"

#if WORLD_SPACE_PLAYER_REF == 1
    #include "/lib/materials/materialMethods/playerRayTracer.glsl"
#endif

#if defined OVERWORLD || defined END
    #ifndef GBUFFERS_WATER 
        #include "/lib/lighting/shadowSampling.glsl"
        #if defined DO_PIXELATION_EFFECTS && defined PIXELATED_SHADOWS
            #include "/lib/misc/pixelation.glsl"
        #endif
    #endif

    #if SHADOW_SMOOTHING == 4 || SHADOW_QUALITY == 0
        const float offset = 0.00098;
    #elif SHADOW_SMOOTHING == 3
        const float offset = 0.00075;
    #elif SHADOW_SMOOTHING == 2
        const float offset = 0.0005;
    #elif SHADOW_SMOOTHING == 1
        const float offset = 0.0003;
    #endif
#endif

#if HELD_LIGHTING_MODE >= 1
    #include "/lib/lighting/heldLighting.glsl"
#endif

#ifdef CLOUD_SHADOWS
    #include "/lib/lighting/cloudShadows.glsl"
#endif

#ifdef LIGHT_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif
#ifdef MOON_PHASE_INF_LIGHT
    #include "/lib/colors/moonPhaseInfluence.glsl"
#endif

vec2 getLocalTexCoord(vec3 local, vec3 normal) {
    vec3 absNormal = abs(normal);
    return 1.0 - local.zy * absNormal.x - local.xz * absNormal.y - local.xy * absNormal.z;
}

float getVoxelSpaceAO(ivec3 voxelPos, ivec3 normal, vec2 localTexCoord) {
    ivec3 absNormal = abs(normal);
    ivec3 hrz = ivec3(0, 0, 1) * absNormal.x + ivec3(1, 0, 0) * absNormal.y + ivec3(1, 0, 0) * absNormal.z;
    ivec3 vrt = ivec3(0, 1, 0) * absNormal.x + ivec3(0, 0, 1) * absNormal.y + ivec3(0, 1, 0) * absNormal.z;

    vec2 dir = 1.0 - 2.0 * localTexCoord;

    ivec2 signDir = ivec2(sign(dir));
    ivec3 voxelHrz = voxelPos + normal + signDir.x * hrz;
    ivec3 voxelVrt = voxelPos + normal + signDir.y * vrt; 

    vec2 factor = pow2(dir);
    float occHrz = mix(1.0, float(texelFetch(wsr_sampler, voxelHrz, 0).r == 0u), factor.x);
    float occVrt = mix(1.0, float(texelFetch(wsr_sampler, voxelVrt, 0).r == 0u), factor.y);

    return 0.3 * (occHrz + occVrt) + 0.4;
}

vec4 getShadedReflection(ivec3 voxelPos, vec3 oldPlayerPos, vec3 playerPos, vec3 rayDir, vec3 normal, uint mat, float dither) {
    faceData faceData = getFaceData(voxelPos, normal);
    if (faceData.textureBounds.z < 1e-6) return vec4(-1.0);
     
    vec2 localTexCoord = getLocalTexCoord(fract(playerPos + cameraPositionBestFract), normal);
    
    vec2 textureSizeAtlas = textureSize(textureAtlas, 0);
    vec2 textureRadVec2 = faceData.textureBounds.z * vec2(1.0, textureSizeAtlas.x / textureSizeAtlas.y);
    vec2 textureCoord = faceData.textureBounds.xy + 2.0 * textureRadVec2 * localTexCoord;

    float virtualDist   = length(playerPos - oldPlayerPos) + length(oldPlayerPos);
    float textureFactor = length(textureRadVec2 * textureSizeAtlas) * 3.0;
    float lod = 0.5 * log2(virtualDist * textureFactor / gbufferProjection[0][0] / abs(dot(normal, rayDir)) / viewHeight / REFLECTION_RES);

    vec4 color = texture2DLod(textureAtlas, textureCoord, lod) * vec4(faceData.glColor, 1.0);

    #if MC_VERSION >= 12111 && IRIS_VERSION < 11005
        // stupid fake lods because custom texture lods broke with Iris in newer mc versions
        vec2 lodCoordSpan = localTexCoord / pow(2.0, int(1.5 + pow2(max0(lod)) + 0.0 * dither));

        vec2 lodCoord1 = faceData.textureBounds.xy + 2.0 * textureRadVec2 * (0.5 + lodCoordSpan);
        vec2 lodCoord2 = faceData.textureBounds.xy + 2.0 * textureRadVec2 * (0.25 + lodCoordSpan);
        vec2 lodCoord3 = faceData.textureBounds.xy + 2.0 * textureRadVec2 * lodCoordSpan;
        vec4 lodColor1 = texture2DLod(textureAtlas, lodCoord1, lod) * vec4(faceData.glColor, 1.0);
        vec4 lodColor2 = texture2DLod(textureAtlas, lodCoord2, lod) * vec4(faceData.glColor, 1.0);
        vec4 lodColor3 = texture2DLod(textureAtlas, lodCoord3, lod) * vec4(faceData.glColor, 1.0);

        float lodMix = clamp01(lod - 0.75 + 0.25 * dither);
        color = mix(color, 0.333333 * (lodColor1 + lodColor2 + lodColor3), lodMix);
        if (dot(color.rgb, vec3(0.333333)) - 0.5 < 0.49) color.a = mix(color.a, 1.0, lodMix);
        //
    #endif

    if (color.a < 0.0041) return vec4(-1.0); // Note that the cutout parts of leaves have a color.a of about 0.004

    bool noSmoothLighting = false, noDirectionalShading = false;
    int subsurfaceMode = 0;
    float emission = 0.0, NdotU = normal.y, NdotE = normal.x, snowMinNdotU = 0.0;
    vec2 lmCoordM = vec2(1.0);
    vec3 shadowMult = vec3(1.0), maRecolor = vec3(0.0);
    #ifdef IPBR
        float lViewPos = length(playerPos);
        vec4 glColor = vec4(faceData.glColor, 1.0);
        vec2 absMidCoordPos = vec2(textureRadVec2);
        vec2 midCoord = faceData.textureBounds.xy + 2.0 * textureRadVec2 * vec2(0.5);
        vec2 signMidCoordPos = localTexCoord * 2.0 - 1.0;
        bool noVanillaAO = false, centerShadowBias = false, noGeneratedNormals = false, doTileRandomisation = true;
        float smoothnessD = 0.0, materialMask = 0.0;
        float smoothnessG = 0.0, highlightMult = 1.0, noiseFactor = 1.0, snowFactor = 1.0, noPuddles = 0.0;
        vec2 lmCoord = faceData.lightmap;
        vec3 normalM = normal, geoNormal = normal;

        #define DURING_WORLDSPACE_REF
            #ifndef IPBR_COMPAT_MODE
                #define IPBR_COMPAT_MODE
            #endif
            #undef DISTANT_LIGHT_BOKEH
            #include "/lib/materials/materialHandling/terrainIPBR.glsl"
        #undef DURING_WORLDSPACE_REF
    #else
        if (mat == 10009) { // Leaves
            #include "/lib/materials/specificMaterials/terrain/leaves.glsl"
        }
    #endif

    float NdotL = dot(normal, mat3(gbufferModelViewInverse) * lightVec);
    #ifdef SIDE_SHADOWING
        float lightingNdotL = max0(NdotL + 0.4) * 0.714;

        #ifdef END
            lightingNdotL = sqrt3(lightingNdotL);
        #endif
    #else
        float lightingNdotL = max0(NdotL);
    #endif
    
    #ifndef NETHER
        vec3 shadow = shadowMult;
        if (lightingNdotL > 0.0001) {
            float shadowLength = shadowDistance * 0.9166667 - length(playerPos); //consistent08JJ622
            if (shadowLength > 0.000001) {
                float distanceBias = 0.12 + 0.0008 * pow(dot(playerPos, playerPos), 0.75);
                vec3 bias = normal * distanceBias * (2.0 - 0.95 * max0(NdotL));  
                int shadowSamples = 2;
                
                shadow = GetShadow(GetShadowPos(playerPos + bias), faceData.lightmap.y, offset, shadowSamples, false, playerPos);
            }
        }
        shadow *= dot(shadow, vec3(0.33333));
    #else
        vec3 shadow = vec3(1.0);
    #endif

    #ifdef CLOUD_SHADOWS
        shadow *= GetCloudShadow(playerPos);
    #endif

    faceData.lightmap = pow2(pow2(faceData.lightmap));
    float AO = getVoxelSpaceAO(voxelPos, ivec3(normal), localTexCoord);
    float directionalShading = noDirectionalShading ? 1.0 : (NdotU + 1.0) * 0.25 + 0.5;

    vec3 centerPlayerPos = floor(playerPos + cameraPosition + normal * 0.01) - cameraPosition + 0.5;
    vec3 playerPosM = mix(centerPlayerPos, playerPos, (AO - 0.8) / 0.2);
    vec3 voxelPosM = SceneToVoxel(playerPosM);
         voxelPosM = clamp01(voxelPosM / vec3(voxelVolumeSize));
    vec4 lightVolume = GetLightVolume(voxelPosM);
         lightVolume = max(lightVolume, vec4(0.000001));
    vec3 specialLighting = 0.8 * pow(GetLuminance(lightVolume.rgb), 0.25) * DoLuminanceCorrection(pow(lightVolume.rgb, vec3(0.3)));
    if (noSmoothLighting == true) specialLighting *= 0.6;

    vec3 minLighting = 0.8 * sqrt(GetMinimumLighting(faceData.lightmap.y));

    #if HELD_LIGHTING_MODE >= 1
        vec3 heldLighting = GetHeldLighting(playerPos, color.rgb, emission);
        specialLighting = sqrt(pow2(specialLighting) + sqrt(heldLighting));
    #endif

    #ifdef OVERWORLD
        float ambientMult = 0.9 * faceData.lightmap.y;
        float lightMult = (1.1 + 0.25 * subsurfaceMode) * lightingNdotL * shadowTime;
        lightMult *= 1.0 + abs(NdotE) * 0.25;
        specialLighting *= 1.0 - faceData.lightmap.y * sunFactor;
    #else
        float ambientMult = 1.0;
        float lightMult = 1.0 * lightingNdotL * shadowTime;
    #endif

    vec3 sceneLighting = ambientMult * ambientColor + lightMult * lightColor * shadow;
    #ifdef LIGHT_COLOR_MULTS
        lightColorMult = GetLightColorMult();
        sceneLighting *= lightColorMult;
    #endif
    #ifdef MOON_PHASE_INF_LIGHT
        sceneLighting *= moonPhaseInfluence;
    #endif

    vec3 lighting = sceneLighting + specialLighting * XLIGHT_I + minLighting;
    lighting = lighting * AO * directionalShading + emission * 0.8;

    vec3 fadeout = smoothstep(0.0, 32.0, 0.5 * sceneVoxelVolumeSize - abs(playerPos));
    float alphaFade = sqrt3(minOf(fadeout)) * 0.9 + 0.1;
    
    return vec4(color.rgb * lighting + maRecolor, alphaFade);
}

vec4 voxelRayTrace(vec3 playerPos, vec3 voxelPos, vec3 rayDir, float RVdotU, float RVdotS, float dither, out float traceLength) {
    vec3 stepAxis = vec3(0.0);
    vec3 stepDir = sign(rayDir);
    vec3 stepSizes = 1.0 / abs(rayDir);

    float dist1 = 0.0;
    vec3 voxelPosRT1 = voxelPos * 0.25;
    vec3 nextDist1 = (stepDir * 0.5 + 0.5 - fract(voxelPosRT1)) / rayDir;
    
    while (CheckInsideLodVoxelVolume(voxelPosRT1)) {
        if (texelFetch(wsr_lod_sampler, ivec3(voxelPosRT1), 0).r > 0u) {
            float dist0 = 0.0;
            vec3 voxelPosRT0 = playerToSceneVoxel(playerPos + 4.0 * dist1 * rayDir);
            vec3 nextDist0 = (stepDir * 0.5 + 0.5 - fract(voxelPosRT0)) / rayDir;

            vec3 lodVoxelMin = floor(voxelPosRT1) * 4.0;
            vec3 lodVoxelMax = lodVoxelMin + 4.0;

            float maxDist0 = minOf((mix(lodVoxelMin, lodVoxelMax, stepDir * 0.5 + 0.5) - voxelPosRT0) / rayDir);

            while (dist0 < maxDist0 && CheckInsideSceneVoxelVolume(voxelPosRT0)) {
                uint mat = texelFetch(wsr_sampler, ivec3(voxelPosRT0), 0).r;
                if (mat > 0u) {
                    traceLength = 4.0 * dist1 + dist0;

                    vec3 normal = -stepAxis * stepDir;
                    vec3 intersection = playerPos + traceLength * rayDir;

                    vec4 reflection = getShadedReflection(ivec3(voxelPosRT0), playerPos, intersection, rayDir, normal, mat, dither);
                    if (reflection.a > -0.5) {
                        vec3 fadeout = smoothstep(0.0, 32.0, 0.5 * sceneVoxelVolumeSize - abs(playerPos));
                        reflection *= sqrt3(minOf(fadeout)) * 0.9 + 0.1;

                        float skyFade = 0.0;
                        float reflectionPrevAlpha = reflection.a;

                        DoFog(reflection, skyFade, length(intersection), intersection, RVdotU, RVdotS, dither, true, length(playerPos));

                        reflection.a = reflectionPrevAlpha * (1.0 - skyFade);

                        return reflection;
                    }
                }

                dist0 = minOf(nextDist0);
                stepAxis = vec3(equal(nextDist0, vec3(dist0)));

                nextDist0 += stepAxis * stepSizes;
                voxelPosRT0 += stepAxis * stepDir;
            }      
        }

        dist1 = minOf(nextDist1);
        stepAxis = vec3(equal(nextDist1, vec3(dist1)));

        nextDist1 += stepAxis * stepSizes;
        voxelPosRT1 += stepAxis * stepDir;
    }

    traceLength = 999999.0;
    return vec4(0.0);
}

vec4 getWSR(vec3 playerPos, vec3 normalMR, vec3 nViewPosR, float RVdotU, float RVdotS, float z0, float dither, out float wsrTraceLength) {
    vec3 normalOffset = normalize(mat3(gbufferModelViewInverse) * normalMR);

    // Fix self-reflection and also align non-full blocks' trace start position to the grid
    float normalOffsetDist = 1.0 - fract(dot(playerPos + cameraPositionBestFract - normalOffset * 0.1, normalOffset));
    normalOffsetDist += 0.04; // Fixes remaining artifacts. 0.03 is enough but use slightly higher to make sure
    playerPos += normalOffsetDist * normalOffset;

    vec3 voxelPos = playerToSceneVoxel(playerPos);
    vec3 rayDir = mat3(gbufferModelViewInverse) * nViewPosR;

    if (CheckInsideSceneVoxelVolume(voxelPos)) {
        vec4 wsrResult = voxelRayTrace(playerPos, voxelPos, rayDir, RVdotU, RVdotS, dither, wsrTraceLength);

        #if WORLD_SPACE_PLAYER_REF == 1
            if (!is_invisible && z0 > 0.56) {
                vec3 albedo;
                vec3 normal;

                if (rayTracePlayer(playerPos - 0.01 * rayDir, rayDir, wsrTraceLength, albedo, normal)) {
                    vec2 lmCoord = eyeBrightness / 240.0;

                    #ifdef OVERWORLD
                        float ambientMult = 1.5 * lmCoord.y;
                        float lightMult = 0.2 * pow2(pow2(lmCoord.y));
                    #else
                        float ambientMult = 1.5;
                        float lightMult = 0.0;
                    #endif

                    vec3 voxelPosM = SceneToVoxel(vec3(0.0));
                        voxelPosM = clamp01(voxelPosM / vec3(voxelVolumeSize));
                    vec4 lightVolume = GetLightVolume(voxelPosM);
                        lightVolume = max(lightVolume, vec4(0.000001));
                    vec3 specialLighting = pow(GetLuminance(lightVolume.rgb), 0.25) * DoLuminanceCorrection(pow(lightVolume.rgb, vec3(0.25)));

                    #if HELD_LIGHTING_MODE >= 1
                        vec3 heldLighting = GetHeldLighting(playerPos, vec3(999999.0), 0.0);
                        specialLighting = sqrt(pow2(specialLighting) + sqrt(heldLighting));
                    #endif

                    vec3 minLighting = 0.8 * sqrt(GetMinimumLighting(lmCoord.y));

                    vec3 sceneLighting = ambientMult * ambientColor + lightMult * lightColor;
                    #ifdef LIGHT_COLOR_MULTS
                        lightColorMult = GetLightColorMult();
                        sceneLighting *= lightColorMult;
                    #endif
                    #ifdef MOON_PHASE_INF_LIGHT
                        sceneLighting *= moonPhaseInfluence;
                    #endif

                    vec3 lighting = sceneLighting + specialLighting * (1.0 - lmCoord.y * sunFactor) * XLIGHT_I + minLighting;

                    vec3 fadeout = smoothstep(0.0, 32.0, 0.5 * sceneVoxelVolumeSize - abs(playerPos));
                    float alphaFade = sqrt3(minOf(fadeout)) * 0.9 + 0.1;
                    
                    return vec4(albedo * lighting, alphaFade);
                }
            }
        #endif

        return wsrResult;
    }

    return vec4(0.0);
}