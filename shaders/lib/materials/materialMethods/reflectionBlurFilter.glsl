vec4 sampleBlurFilteredReflection(vec4 centerCol, vec3 nViewPos, float dither, float z0) {
    vec4 texture4 = texture2D(colortex4, ToBufferUV(texCoord));

    const float spatialFactor = 2.5; // higher = smoother in space
    const float spatialFactorM = 2.0 * spatialFactor * spatialFactor;

    vec4 sum = vec4(0.0);
    float weightSum = 0.0;
    vec2 texelSize = (3.0 + 6.0 * dither) / view; // 1 pixel range doesn't seem to be enough to smooth things out

    #ifdef SMOOTHNESS_AFFECTED_REF_BLUR
        vec3 texture6 = texelFetch(colortex6, texelCoord, 0).rgb;
        float smoothnessD = texture6.r;
        texelSize *= 1.0 - 0.75 * pow2(pow2(pow2(smoothnessD)));
    #endif

    #ifdef REFLECTION_BLUR_DEPTH_CHECK
        float linearZ0 = GetLinearDepth(z0);

        vec3 normalM = mat3(gbufferModelView) * texture4.rgb;
        float fresnel = clamp(1.0 + dot(normalM, nViewPos), 0.0, 1.0);
        float blurDepthCheckThreshold = (2.0 + pow2(pow2(fresnel)) * 35.0) / far;
    #endif

    int k = 2;
    for (int dy = -k; dy <= k; dy++) {
        for (int dx = -k; dx <= k; dx++) {
            vec2 offset = vec2(float(dx), float(dy)) * texelSize;
            vec2 sampleCoord = ToBufferUV(texCoord + offset);
            vec4 sampleCol = texture2D(colortex7, sampleCoord);

            // Skip step if normals are too different
            vec4 texture1Sample = texture2D(colortex1, sampleCoord);
            if (length(texture4.rgb - texture1Sample.rgb) > 0.1 + 0.075 * dither) continue;

            // Skip if depth is too different (costs performance for a tiny fix)
            #ifdef REFLECTION_BLUR_DEPTH_CHECK
                if (abs(GetLinearDepth(texture2D(depthtex0, ToBufferUV(texCoord + offset)).r) - linearZ0) > blurDepthCheckThreshold) continue;
            #endif

            // Spatial weight (gaussian)
            float spatialDist2 = float(dx*dx + dy*dy);
            float weight = exp(-spatialDist2 / spatialFactorM);

            sum  += sampleCol * weight;
            weightSum += weight;
        }
    }

    return sum / weightSum;
}
