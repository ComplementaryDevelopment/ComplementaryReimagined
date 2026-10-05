const float handDepthThreshold = 0.56; // Hand depth ranges from 0.44 to 0.56

vec3 SampleFilteredCurrent(vec2 sourcePosition) {
    sourcePosition = clamp(sourcePosition, vec2(0.5), scaledViewSizeF - 0.5);
    return TAAEncode(SampleTemporal(colortex0, sourcePosition, scaledViewSizeF));
}

vec2 GetTAAUHistoryCoord(ivec2 sourceTexel, float opaqueDepth, vec4 viewPosition, out bool isLodChunk) {
    isLodChunk = false;
    #if defined DISTANT_HORIZONS || defined VOXY
        if (opaqueDepth == 1.0) {
            #ifdef VOXY
                float lodDepth = texelFetch(vxDepthTexOpaque, sourceTexel, 0).r;
            #else
                float lodDepth = texelFetch(dhDepthTex1, sourceTexel, 0).r;
            #endif
            isLodChunk = lodDepth < 1.0;
            if (isLodChunk) {
                #ifdef VOXY
                    return Reprojection(vec3(texCoord, lodDepth), vxProjInv, vxProjPrev);
                #else
                    return Reprojection(vec3(texCoord, lodDepth), dhProjectionInverse, dhPreviousProjection);
                #endif
            }
        }
    #endif

    return opaqueDepth > handDepthThreshold ? Reprojection(viewPosition) : texCoord;
}

#ifdef CLOUDS_REIMAGINED
    bool IsValidTAAUCloudDepth(float cloudDepth, ivec2 sourceTexel) {
        // Cloud depth can exceed 1.0. Exactly 1.0 means no cloud.
        // The top-right pixel may contain light-shaft data instead.
        return cloudDepth > 0.0 && cloudDepth != 1.0
            && sourceTexel != scaledViewSize - 1;
    }

    float FindTAAUCloudDepth(vec2 sourcePosition, ivec2 sourceTexel) {
        float cloudDepth = texelFetch(colortex5, sourceTexel, 0).a;
        if (cloudDepth != 1.0) return cloudDepth;

        // Fall back to the other texels in the bilinear footprint.
        ivec2 sampleBase = ivec2(floor(sourcePosition - 0.5));
        for (int y = 0; y < 2; y++) {
            for (int x = 0; x < 2; x++) {
                ivec2 sampleTexel = clamp(sampleBase + ivec2(x, y), ivec2(0), scaledViewSize - 1);
                if (sampleTexel == sourceTexel) continue;

                float sampleDepth = texelFetch(colortex5, sampleTexel, 0).a;
                if (IsValidTAAUCloudDepth(sampleDepth, sampleTexel)) {
                    cloudDepth = cloudDepth == 1.0 ? sampleDepth : min(cloudDepth, sampleDepth);
                }
            }
        }
        return cloudDepth;
    }
#endif

// Camera reprojection cannot account for entity movement.
bool IsTAAUEntity(int materialMask) {
    return (materialMask >= 100 && materialMask <= 199) // Entity Reflection Handling (see common.glsl for details)
        || materialMask == 254; // No SSAO, No TAA, Reduce Reflection
}

vec4 DoTAAU() {
    vec2 jitter = TAAJitter(vec2(0.0), 1.0) * scaledViewSizeF * 0.5;
    vec2 sourcePosition = texCoord * scaledViewSizeF + jitter;
    ivec2 sourceTexel = clamp(ivec2(sourcePosition), ivec2(0), scaledViewSize - 1);

    vec3 currentColor = TAAEncode(texelFetch(colortex0, sourceTexel, 0).rgb);
    vec2 centerOffset = vec2(sourceTexel) + 0.5 - sourcePosition;
    vec2 texelCenterOffset = centerOffset / renderScaleV;

    float opaqueDepth = texelFetch(depthtex1, sourceTexel, 0).r;
    float sceneDepth = texelFetch(depthtex0, sourceTexel, 0).r;
    int materialMask = int(texelFetch(colortex6, sourceTexel, 0).g * 255.1);

    vec4 viewPosition = gbufferProjectionInverse * (vec4(texCoord, opaqueDepth, 1.0) * 2.0 - 1.0);
    viewPosition /= viewPosition.w;

    // Pad hand and entity silhouettes so jitter does not flicker at their edges.
    float nearestDepth = sceneDepth;
    bool isEntity = IsTAAUEntity(materialMask);
    for (int i = 4; i < 8; i++) {
        ivec2 neighbourTexel = clamp(sourceTexel + neighbourhoodOffsets[i], ivec2(0), scaledViewSize - 1);
        nearestDepth = min(nearestDepth, texelFetch(depthtex0, neighbourTexel, 0).r);
        int neighbourMaterialMask = int(texelFetch(colortex6, neighbourTexel, 0).g * 255.1);
        isEntity = isEntity || IsTAAUEntity(neighbourMaterialMask);
    }

    #ifdef ENTITY_TAA_NOISY_CLOUD_FIX
        float cloudLinearDepth = texture2D(colortex5, ToBufferUV(texCoord)).a;
        float viewDistance = length(viewPosition);
        if (pow2(cloudLinearDepth) * renderDistance < min(viewDistance, renderDistance)) {
            // Ignore entities hidden behind the cloud volume.
            materialMask = 0;
            isEntity = false;
        }
    #endif

    bool isHand = nearestDepth < handDepthThreshold;
    isEntity = isEntity && !isHand;
    bool isMoving = isHand || isEntity;
    float currentSampleWeight = exp((isHand ? -3.125 : -2.5) * dot(texelCenterOffset, texelCenterOffset));

    bool isLodChunk = false;
    vec2 historyCoord = texCoord;
    if (!isHand) historyCoord = GetTAAUHistoryCoord(sourceTexel, opaqueDepth, viewPosition, isLodChunk);

    #ifdef CLOUDS_REIMAGINED
        // Use cloud depth to reproject sky pixels that contain clouds.
        if (!isMoving && sceneDepth == 1.0 && opaqueDepth == 1.0 && !isLodChunk) {
            float cloudDepth = FindTAAUCloudDepth(sourcePosition, sourceTexel);
            if (IsValidTAAUCloudDepth(cloudDepth, sourceTexel)) {
                float cloudDistance = cloudDepth * cloudDepth * renderDistance;
                historyCoord = Reprojection(vec4(normalize(viewPosition.xyz) * cloudDistance, 1.0));
            }
        }
    #endif

    vec3 historyColor = SampleHistory(historyCoord);

    if (historyColor == vec3(0.0) || any(isnan(historyColor)) || any(isinf(historyColor))) {
        // History is missing on the first frame and can become invalid after camera transitions.
        return vec4(SampleFilteredCurrent(sourcePosition), isHand ? 0.0 : 1.0);
    }

    // History alpha recovers from 0 to 1 over four frames after a hand or entity leaves the pixel.
    // Entity pixels use 2 + confidence to keep the two states separate.
    ivec2 historyTexel = clamp(ivec2(historyCoord * view), ivec2(0), ivec2(view) - 1);
    float previousHistoryAlpha = texelFetch(colortex2, historyTexel, 0).a;
    float previousConfidence = clamp(previousHistoryAlpha - 2.0, 0.0, 1.0);
    if (previousHistoryAlpha >= 2.0) previousHistoryAlpha = 0.0;

    float distanceBlendFactor = isMoving ? 0.0 : previousHistoryAlpha;
    float historyAlpha = isMoving ? 0.0 : min(previousHistoryAlpha + 0.25, 1.0);
    isMoving = isMoving || previousHistoryAlpha < 1.0;

    float edge = 0.0;
    vec3 colorMin = currentColor;
    vec3 colorMax = currentColor;
    vec3 colorSum = vec3(0.0);
    vec3 colorSquaredSum = vec3(0.0);
    float colorWeight = 0.0;
    vec3 handFill = vec3(0.0);

    // Build colour bounds for world history and variance for moving pixels.
    ivec2 maxSourceTexel = scaledViewSize - 1;
    for (int i = 0; i < 9; i++) {
        ivec2 offset = i < 8 ? neighbourhoodOffsets[i] : ivec2(0);
        ivec2 neighbourTexel = clamp(sourceTexel + offset, ivec2(0), maxSourceTexel);
        vec3 neighbourColor = i < 8 ? SampleNeighbourhood(neighbourTexel, sceneDepth, opaqueDepth,
                                                         edge, colorMin, colorMax) : currentColor;
        if (isMoving) {
            vec2 sampleOffset = centerOffset + vec2(offset);
            float weight = isHand ? exp(-dot(sampleOffset, sampleOffset) / (2.0 * 0.75 * 0.75)) : 1.0;
            vec3 neighbourYCoCg = RGBToYCoCg(neighbourColor);
            colorSum += weight * neighbourYCoCg;
            colorSquaredSum += weight * neighbourYCoCg * neighbourYCoCg;
            colorWeight += weight;
            if (isHand) {
                // Keep a bilinear fallback for rejected hand history.
                vec2 tent = max(1.0 - abs(sampleOffset), 0.0);
                handFill += tent.x * tent.y * neighbourColor;
            }
        }
    }

    vec3 worldHistoryColor = ClipAABB(historyColor, colorMin, colorMax);
    if (isEntity) {
        // At a silhouette the nearest surface is the entity, not the background behind it.
        vec4 entityViewPosition = gbufferProjectionInverse * (vec4(texCoord, nearestDepth, 1.0) * 2.0 - 1.0);
        float entityDistance = length(entityViewPosition.xyz / entityViewPosition.w);
        float entityDistanceFactor = 1.0 - exp2(-0.05 * max(entityDistance - 8.0, 0.0));

        // Matching history builds confidence over half a second.
        // A mismatch halves it because edge jitter can move a stationary entity outside the local range.
        float worldClipDistance = length(historyColor - worldHistoryColor) / (length(colorMax - colorMin) + 0.01);
        float historyConfidence = worldClipDistance < 0.1 ? min(previousConfidence + 2.0 * frameTime, 1.0)
                                                          : previousConfidence * 0.5;
        distanceBlendFactor = max(entityDistanceFactor, historyConfidence);
        historyAlpha = 2.0 + historyConfidence;
    }
    if (!isHand) historyColor = worldHistoryColor;

    float clipDistance = 0.0;
    if (isMoving) {
        // Variance clipping limits trails from moving and recently uncovered pixels.
        vec3 mean = colorSum / colorWeight;
        vec3 sigma = sqrt(max(colorSquaredSum / colorWeight - mean * mean, 0.0));
        vec3 historyYCoCg = RGBToYCoCg(historyColor);
        vec3 clippedHistory = ClipAABB(historyYCoCg, mean - sigma, mean + sigma);
        clipDistance = length(clippedHistory - historyYCoCg) / (length(sigma) + (isHand ? 0.004 : 0.01));
        historyColor = YCoCgToRGB(clippedHistory);
    }

    float historyWeight = GetHistoryWeight(historyCoord, opaqueDepth, materialMask, edge, isLodChunk);

    if (historyWeight == 0.0) {
        historyAlpha = isHand ? 0.0 : (isEntity ? 2.0 : 1.0);
        return vec4(clamp(SampleFilteredCurrent(sourcePosition), 0.0, 1.0), historyAlpha);
    }

    vec3 resolvedColor = mix(worldHistoryColor, currentColor, (1.0 - historyWeight) * currentSampleWeight);
    if (isMoving && distanceBlendFactor < 1.0) {
        historyWeight = isHand ? (2.0 / 3.0) / (1.0 + clipDistance * clipDistance)
                               : min(historyWeight, 0.75) * exp(-4.0 * clipDistance);

        // Preserve the Gaussian centre weight while filling rejected history from the current frame.
        float sampleBlend = isHand ? currentSampleWeight / (3.0 * (1.0 - historyWeight)) : currentSampleWeight;
        vec3 filteredCurrent = mix(isHand ? handFill : SampleFilteredCurrent(sourcePosition), currentColor, sampleBlend);
        vec3 movingColor = mix(historyColor, filteredCurrent, 1.0 - historyWeight);

        // Distant or stable entities keep more world history to reduce shimmer.
        resolvedColor = mix(movingColor, resolvedColor, distanceBlendFactor);
    }

    return vec4(clamp(resolvedColor, 0.0, 1.0), historyAlpha);
}
