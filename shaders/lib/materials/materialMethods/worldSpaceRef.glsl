#extension GL_ARB_shader_image_load_store : enable

#include "/lib/voxelization/reflectionVoxelization.glsl"

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

#ifdef CLOUD_SHADOWS
    #include "/lib/lighting/cloudShadows.glsl"
#endif

#ifdef LIGHT_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif
#ifdef MOON_PHASE_INF_LIGHT
    #include "/lib/colors/moonPhaseInfluence.glsl"
#endif

vec2 getLocalTexCoord(vec3 local, vec3 normal, float dither) {
    vec3 absNormal = abs(normal);
    local = 1.0 - local;
    vec2 texCoord = local.zy * absNormal.x + local.xz * absNormal.y + local.xy * absNormal.z;
    vec4 dFdUVxy = vec4(dFdx(texCoord), dFdy(texCoord));
    float mipLevel = 5.0 * max(dot(dFdUVxy.xy, dFdUVxy.xy), dot(dFdUVxy.zw, dFdUVxy.zw));
    vec2 localTexCoord = texCoord + mipLevel * (vec2(dither, fract(dither + goldenRatio)) * 2.0 - 1.0);
    return clamp(localTexCoord, 0.01, 0.99);
}

float getVoxelSpaceAO(vec3 playerPos, ivec3 normal, vec2 localTexCoord) {
    ivec3 voxelPos = ivec3(playerToSceneVoxel(playerPos + normal * 0.5));
    ivec3 absNormal = ivec3(abs(normal));
    ivec3 right = ivec3(0, 0, 1) * absNormal.x + ivec3(1, 0, 0) * absNormal.y + ivec3(1, 0, 0) * absNormal.z;
    ivec3 up = ivec3(0, 1, 0) * absNormal.x + ivec3(0, 0, 1) * absNormal.y + ivec3(0, 1, 0) * absNormal.z;

    vec2 centerFactorPos = sqrt1(2.0 * clamp01(0.5 - localTexCoord));
    vec2 centerFactorNeg = sqrt1(2.0 * clamp01(localTexCoord - 0.5));
    ivec3 voxel0 = voxelPos + right;
    ivec3 voxel1 = voxelPos - right;
    ivec3 voxel2 = voxelPos + up;
    ivec3 voxel3 = voxelPos - up;

    float occlusion0 = mix(0.0, min1(texelFetch(wsr_sampler, voxel0, 0).r), centerFactorPos.x);
    float occlusion1 = mix(0.0, min1(texelFetch(wsr_sampler, voxel1, 0).r), centerFactorNeg.x);
    float occlusion2 = mix(0.0, min1(texelFetch(wsr_sampler, voxel2, 0).r), centerFactorPos.y);
    float occlusion3 = mix(0.0, min1(texelFetch(wsr_sampler, voxel3, 0).r), centerFactorNeg.y);

    return 1.0 - (occlusion0 + occlusion1 + occlusion2 + occlusion3) * 0.25;
}

vec4 getShadedReflection(faceData faceData, int mat, vec3 voxelPos, vec3 playerPos, vec3 normal, float dither) {
    vec2 localTexCoord = getLocalTexCoord(fract(playerPos + cameraPositionBestFract), normal, dither);
    vec2 textureSizeAtlas = textureSize(textureAtlas, 0);
    float atlasRatio = atlasSize.x / atlasSize.y;
    vec2 textureRadVec2 = faceData.textureBounds.z * vec2(1.0, textureSizeAtlas.x / textureSizeAtlas.y);
    vec2 textureCoord = faceData.textureBounds.xy + 2.0 * textureRadVec2 * localTexCoord;
    vec4 color = texture2D(textureAtlas, textureCoord) * vec4(faceData.glColor, 1.0);

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

                #if SHADOW_QUALITY == 0
                    int shadowSamples = 0; // We don't use SampleTAAFilteredShadow on Shadow Quality 0
                #elif SHADOW_QUALITY == 1
                    int shadowSamples = 1;
                #else
                    int shadowSamples = 2;
                #endif
                shadow = GetShadow(GetShadowPos(playerPos + bias), 1.0, offset, shadowSamples, false);
            }
        }
        #ifdef CLOUD_SHADOWS
            //shadow *= GetCloudShadow(playerPos); // there are some issues with this rn
        #endif
    #else
        vec3 shadow = vec3(1.0);
    #endif

    faceData.lightmap = pow2(pow2(faceData.lightmap));
    float AO = max(0.8, getVoxelSpaceAO(playerPos, ivec3(normal), localTexCoord));
    float directionalShading = noDirectionalShading ? 1.0 : (NdotU + 1.0) * 0.25 + 0.5;
    #ifdef OVERWORLD
        float ambientMult = 0.9 * faceData.lightmap.y;
        float lightMult = (1.1 + 0.25 * subsurfaceMode) * lightingNdotL * shadowTime;
        lightMult *= 1.0 + abs(NdotE) * 0.25;
    #else
        float ambientMult = 1.0;
        float lightMult = 1.0 * lightingNdotL * shadowTime;
    #endif

    vec3 centerPlayerPos = floor(playerPos + cameraPosition + normal * 0.01) - cameraPosition + 0.5;
    vec3 playerPosM = mix(centerPlayerPos, playerPos, (AO - 0.8) / 0.2);
    vec3 voxelPosM = SceneToVoxel(playerPosM);
         voxelPosM = clamp01(voxelPosM / vec3(voxelVolumeSize));
    vec4 lightVolume = GetLightVolume(voxelPosM);
         lightVolume = max(lightVolume, vec4(0.000001));
    vec3 specialLighting = pow(GetLuminance(lightVolume.rgb), 0.25) * pow2(lmCoordM.x) * DoLuminanceCorrection(pow(lightVolume.rgb, vec3(0.25)));
    if (noSmoothLighting == true) specialLighting *= 0.6;

    vec3 sceneLighting = ambientMult * ambientColor + lightMult * lightColor * shadow;
    #ifdef LIGHT_COLOR_MULTS
        lightColorMult = GetLightColorMult();
        sceneLighting *= lightColorMult;
    #endif
    #ifdef MOON_PHASE_INF_LIGHT
        sceneLighting *= moonPhaseInfluence;
    #endif

    vec3 lighting = sceneLighting + specialLighting * (1.0 - faceData.lightmap.y * sunFactor) * XLIGHT_I;
    lighting = lighting * AO * directionalShading + emission;

    vec3 fadeout = smoothstep(0.0, 32.0, 0.5 * sceneVoxelVolumeSize - abs(playerPos));
    fadeout = sqrt3(fadeout) * 0.9 + 0.1;
    float alphaFade = min(fadeout.x, min(fadeout.y, fadeout.z));
    
    return vec4(color.rgb * lighting + maRecolor, alphaFade);
}

vec3 wsrHitPos = vec3(-100000);

vec4 traceHighLOD(vec3 rayDir, vec3 stepDir, vec3 stepSizes, vec3 oldPlayerPos, vec3 newPlayerPos, vec3 voxelPos, float RVdotU, float RVdotS, float dither,
                  vec3 voxelPosStart, uint matStart) {
    vec3 nextDist = (stepDir * 0.5 + 0.5 - fract(voxelPos)) / rayDir;
    float closestDist = 0.0;

    const float maxSteps = 14;
    for (int i = 0; i < maxSteps; i++) {
        closestDist = min(nextDist.x, min(nextDist.y, nextDist.z));
        vec3 stepAxis = vec3(lessThanEqual(nextDist, vec3(closestDist)));
        voxelPos += stepAxis * stepDir;
        nextDist += stepAxis * stepSizes;

        if (!CheckInsideSceneVoxelVolume(voxelPos)) return vec4(0.0);

        uint mat = texelFetch(wsr_sampler, ivec3(voxelPos), 0).r;
        if (mat != 0u) {
            vec3 normal = -stepAxis * stepDir;
            faceData faceData = getFaceData(ivec3(voxelPos), normal);
            if (faceData.textureBounds.z > 1e-6) {
                vec3 intersection = newPlayerPos + rayDir * closestDist;
                vec4 reflection = getShadedReflection(faceData, int(mat), voxelPos, intersection, normal, dither);
                if (reflection.a < -0.5) continue;

                wsrHitPos = intersection;

                vec3 fadeout = smoothstep(0.0, 32.0, 0.5 * sceneVoxelVolumeSize - abs(oldPlayerPos));
                fadeout = sqrt3(fadeout) * 0.9 + 0.1;
                reflection *= min(fadeout.x, min(fadeout.y, fadeout.z));

                float skyFade = 0.0;
                float reflectionPrevAlpha = reflection.a;

                DoFog(reflection, skyFade, length(intersection), intersection, RVdotU, RVdotS, dither);

                return vec4(reflection.rgb, reflectionPrevAlpha * (1.0 - skyFade));
            }
        }
    }

    return vec4(-1.0);
}

vec4 traceLowLOD(vec3 rayDir ,vec3 stepDir, vec3 stepSizes, vec3 playerPos, vec3 voxelPos, float RVdotU, float RVdotS, float dither,
                 vec3 voxelPosStart, uint matStart) {
    float lodScale = 4.0;
    vec3 lodVoxelPos = voxelPos / lodScale;

    vec3 nextDist = (stepDir * 0.5 + 0.5 - fract(lodVoxelPos)) / rayDir;
    float closestDistPrevious = 0.0;
    float closestDist = 0.0;

    float maxSteps = length(vec3(sceneVoxelVolumeSize)) / lodScale;
    for (int i = 0; i < maxSteps; i++) {
        if (any(greaterThan(lodVoxelPos, vec3(sceneVoxelVolumeSize) / lodScale - 1.0)) || any(lessThan(lodVoxelPos, vec3(0.0))))
            return vec4(0.0);

        uint lodMat = texelFetch(wsr_sampler_lod, ivec3(lodVoxelPos), 0).r;
        if (lodMat == 1u) {
            vec3 newPlayerPos = playerPos + rayDir * closestDistPrevious * lodScale;
            vec3 newVoxelPos = playerToSceneVoxel(newPlayerPos);
            vec4 try = traceHighLOD(rayDir, stepDir, stepSizes, playerPos, newPlayerPos, newVoxelPos, RVdotU, RVdotS, dither,
                                    voxelPosStart, matStart);
            if (try.a > -0.5) return try;
        }

        closestDistPrevious = closestDist;
        closestDist = min(nextDist.x, min(nextDist.y, nextDist.z));
        vec3 stepAxis = vec3(lessThanEqual(nextDist, vec3(closestDist)));
        lodVoxelPos += stepAxis * stepDir;
        nextDist += stepAxis * stepSizes;
    }

    return vec4(0.0);
}

vec4 getWSR(vec3 playerPos, vec3 normalMR, vec3 nViewPosR, float RVdotU, float RVdotS, float dither) {
    vec3 normalOffset = normalize(mat3(gbufferModelViewInverse) * normalMR);
    playerPos += normalOffset * 0.003;
    vec3 voxelPos = playerToSceneVoxel(playerPos);

    // Fixes slabs, stairs, dirt paths, and farmlands reflecting themselves
    if (z0 == z1) {
        vec3 playerPosFractAdded = playerPos + cameraPositionBestFract + 256.0;
        vec3 normalOffsetM = normalOffset * (0.04 - 0.01 * dither);
        ivec3 voxelPosCheck1 = ivec3(playerPosFractAdded - normalOffsetM);
        ivec3 voxelPosCheck2 = ivec3(playerPosFractAdded + normalOffsetM);
        if (voxelPosCheck1 == voxelPosCheck2) playerPos += normalOffset * 0.5;
    }
    
    // Alternative fix that doesn't work on stairs
    // float voxelPosYFract = fract(voxelPos.y);
    // if (abs(voxelPosYFract - 0.5) < 0.46)
    // playerPos = playerPos + normalOffset * (normalOffset.y > 0.0 ? 1.0 - voxelPosYFract : voxelPosYFract);

    if (CheckInsideSceneVoxelVolume(voxelPos)) {
        vec3 voxelPosStart = voxelPos;
        uint matStart = texelFetch(wsr_sampler, ivec3(voxelPosStart), 0).r;

        vec3 rayDir = normalize(mat3(gbufferModelViewInverse) * nViewPosR);
        vec3 stepDir = sign(rayDir);
        vec3 stepSizes = 1.0 / abs(rayDir);
        return traceLowLOD(rayDir, stepDir, stepSizes, playerPos, voxelPos, RVdotU, RVdotS, dither,
                           voxelPosStart, matStart);
    }

    return vec4(0.0);
}