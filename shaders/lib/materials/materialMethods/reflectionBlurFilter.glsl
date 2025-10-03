vec4 sampleBlurFilteredReflection(vec4 centerCol, float dither, float z0) {
    vec4 texture4 = texture2D(colortex4, texCoord);
    vec3 texture6 = texelFetch(colortex6, texelCoord, 0).rgb;
    float smoothnessD = texture6.r;
    //float linearZ0 = GetLinearDepth(z0);

    const float spatialFactor = 2.5; // higher = smoother in space
    const float spatialFactorM = 2.0 * spatialFactor * spatialFactor;

    vec4 sum = vec4(0.0);
    float wsum = 0.0;
    vec2 texelSize = (3.0 + 6.0 * dither) / view; // 1 pixel range doesn't seem to be enough to smooth things out
    texelSize *= 1.0 - 0.75 * pow2(pow2(pow2(smoothnessD)));

    int k = 2;
    for (int dy = -k; dy <= k; dy++) {
        for (int dx = -k; dx <= k; dx++) {
            vec2 offset = vec2(float(dx), float(dy)) * texelSize;
            vec2 sampleCoord = texCoord + offset;
            vec4 sampleCol = texture2D(colortex7, sampleCoord);

            // Skip step if normals are too different
            vec4 texture1Sample = texture2D(colortex1, sampleCoord);
            if (length(texture4.rgb - texture1Sample.rgb) > 0.1) continue;

            // Skip if depth is too different (costs performance for a tiny fix)
            #ifdef REFLECTION_BLUR_DEPTH_CHECK
                if (abs(GetLinearDepth(texture2D(depthtex0, sampleCoord).r) - linearZ0) * far > 2.0) continue;
            #endif

            // Spatial weight (gaussian)
            float spatialDist2 = float(dx*dx + dy*dy);
            float w_s = exp(-spatialDist2 / spatialFactorM);

            float w = w_s;

            sum  += sampleCol * w;
            wsum += w_s;
        }
    }
    
    return sum / wsum;
}
