#if TAA_SMOOTHING_M == 2
    const float temporalBlendMinimum = 0.3;
    const float temporalBlendVariable = 0.3;
    const float temporalBlendConstant = 0.6;

    const float regularEdge = 10.0;
    const float extraEdgeMult = 2.0;

    const float farEdgeDist = 128.0;
#elif TAA_SMOOTHING_M == 3
    const float temporalBlendMinimum = 0.35;
    const float temporalBlendVariable = 0.2;
    const float temporalBlendConstant = 0.7;

    const float regularEdge = 6.0;
    const float extraEdgeMult = 3.0;

    const float farEdgeDist = 112.0;
#elif TAA_SMOOTHING_M == 4
    const float temporalBlendMinimum = 0.5;
    const float temporalBlendVariable = 0.15;
    const float temporalBlendConstant = 0.75;

    const float regularEdge = 4.0;
    const float extraEdgeMult = 3.5;

    const float farEdgeDist = 96.0;
#endif

const float temporalEncodeScale = 1.45 * TM_EXPOSURE;

vec3 TAAEncode(vec3 c) {
    c = max(c * temporalEncodeScale, 0.0);
    return sqrt(c / (1.0 + c));
}

vec3 TAADecode(vec3 c) {
    c *= c;
    return c / (max(1.0 - c, 1e-3) * temporalEncodeScale);
}

vec3 RGBToYCoCg(vec3 c) {
    return vec3(0.25 * c.r + 0.5 * c.g + 0.25 * c.b, 0.5 * c.r - 0.5 * c.b, -0.25 * c.r + 0.5 * c.g - 0.25 * c.b);
}

vec3 YCoCgToRGB(vec3 c) {
    return vec3(c.x + c.y - c.z, c.x + c.z, c.x - c.y - c.z);
}

// Position and size are in pixels, but the texture stays full size
vec3 SampleTemporalColor(sampler2D colorTexture, vec2 position, vec2 size) {
    position = clamp(position, vec2(0.5), size - 0.5);
    return texture2DLod(colorTexture, position / view, 0).rgb;
}

vec3 SampleTemporal(sampler2D colorTexture, vec2 position, vec2 size) {
    #if TAA_MOVEMENT_IMPROVEMENT_FILTER == 1
        //Catmull-Rom sampling from Filmic SMAA presentation
        vec2 centerPosition = floor(position - 0.5) + 0.5;
        vec2 f = position - centerPosition;
        vec2 f2 = f * f;
        vec2 f3 = f * f2;

        float c = 0.7;
        vec2 w0 =        -c  * f3 +  2.0 * c         * f2 - c * f;
        vec2 w1 =  (2.0 - c) * f3 - (3.0 - c)        * f2         + 1.0;
        vec2 w2 = -(2.0 - c) * f3 + (3.0 -  2.0 * c) * f2 + c * f;
        vec2 w3 =         c  * f3 -                c * f2;

        vec2 w12 = w1 + w2;
        vec2 tc12 = centerPosition + w2 / w12;
        vec2 tc0 = centerPosition - 1.0;
        vec2 tc3 = centerPosition + 2.0;
        vec3 top = SampleTemporalColor(colorTexture, vec2(tc12.x, tc0.y), size);
        vec3 left = SampleTemporalColor(colorTexture, vec2(tc0.x, tc12.y), size);
        vec3 center = SampleTemporalColor(colorTexture, tc12, size);
        vec3 right = SampleTemporalColor(colorTexture, vec2(tc3.x, tc12.y), size);
        vec3 bottom = SampleTemporalColor(colorTexture, vec2(tc12.x, tc3.y), size);
        vec4 color = vec4(top, 1.0)    * (w12.x * w0.y ) +
                     vec4(left, 1.0)   * (w0.x  * w12.y) +
                     vec4(center, 1.0) * (w12.x * w12.y) +
                     vec4(right, 1.0)  * (w3.x  * w12.y) +
                     vec4(bottom, 1.0) * (w12.x * w3.y );
        return color.rgb / color.a;
    #else
        return SampleTemporalColor(colorTexture, position, size);
    #endif
}

vec3 SampleHistory(vec2 uv) {
    vec2 position = uv * view;
    vec3 color = SampleTemporal(colortex2, position, view);
    #if defined TAAU && TAA_MOVEMENT_IMPROVEMENT_FILTER == 1
        // Catmull-Rom can overshoot, so keep it inside the surrounding 2x2 texels
        // This also stops it getting sharper every frame
        ivec2 base = ivec2(floor(position - 0.5));
        vec3 localMin = vec3(1e20), localMax = vec3(-1e20);
        for (int y = 0; y < 2; y++) {
            for (int x = 0; x < 2; x++) {
                ivec2 coord = clamp(base + ivec2(x, y), ivec2(0), ivec2(view) - 1);
                vec3 h = texelFetch(colortex2, coord, 0).rgb;
                localMin = min(localMin, h); localMax = max(localMax, h);
            }
        }
        return clamp(color, localMin, localMax);
    #else
        return color;
    #endif
}

// Previous frame reprojection from Chocapic13
vec2 Reprojection(vec4 viewPos, mat4 previousProjection) {
    vec4 pos = gbufferModelViewInverse * viewPos;
    vec4 previousPosition = pos + vec4(cameraPosition - previousCameraPosition, 0.0);
    previousPosition = gbufferPreviousModelView * previousPosition;
    previousPosition = previousProjection * previousPosition;
    return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
}

vec2 Reprojection(vec4 viewPos) {
    return Reprojection(viewPos, gbufferPreviousProjection);
}

vec2 Reprojection(vec3 pos, mat4 projectionInverse, mat4 previousProjection) {
    vec4 viewPos = projectionInverse * vec4(pos * 2.0 - 1.0, 1.0);
    return Reprojection(viewPos / viewPos.w, previousProjection);
}

vec3 ClipAABB(vec3 color, vec3 boxMin, vec3 boxMax) {
    vec3 center = 0.5 * (boxMax + boxMin);
    vec3 extent = 0.5 * (boxMax - boxMin) + 0.00000001;
    vec3 offset = color - center;
    vec3 ratio = abs(offset / extent);
    float scale = max(ratio.x, max(ratio.y, ratio.z));
    return scale > 1.0 ? center + offset / scale : color;
}

ivec2 neighbourhoodOffsets[8] = ivec2[8](
    ivec2( 1, 1),
    ivec2( 1,-1),
    ivec2(-1, 1),
    ivec2(-1,-1),
    ivec2( 1, 0),
    ivec2( 0, 1),
    ivec2(-1, 0),
    ivec2( 0,-1)
);

float GetLinearDepth(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 SampleNeighbourhood(ivec2 coord, float z0, float z1, inout float edge, inout vec3 colorMin, inout vec3 colorMax) {
    float z0CheckLinear = GetLinearDepth(texelFetch(depthtex0, coord, 0).r);
    float z1CheckLinear = GetLinearDepth(texelFetch(depthtex1, coord, 0).r);
    float z0Linear = GetLinearDepth(z0);
    float z1Linear = GetLinearDepth(z1);
    if (max(abs(z0CheckLinear - z0Linear), abs(z1CheckLinear - z1Linear)) > 0.09) {
        edge = regularEdge;

        float approxClosestDist = min(z0CheckLinear, z0Linear) * far;
        if (approxClosestDist < farEdgeDist)
            if (int(texelFetch(colortex6, coord, 0).g * 255.1) == 253) // Reduced Edge TAA (Leaves)
                edge *= extraEdgeMult;
    }

    vec3 color = TAAEncode(texelFetch(colortex0, coord, 0).rgb);
    colorMin = min(colorMin, color);
    colorMax = max(colorMax, color);
    return color;
}

float GetHistoryWeight(vec2 previousCoord, float z1, int materialMask, float edge, bool lodChunk) {
    float blendMinimum = temporalBlendMinimum;
    float blendVariable = temporalBlendVariable;
    float blendConstant = temporalBlendConstant;

    if (materialMask == 253) // Reduced Edge TAA (Leaves)
        edge *= extraEdgeMult;

    #if defined DISTANT_HORIZONS || defined VOXY
        if (lodChunk) {
            blendMinimum = 0.75;
            blendVariable = 0.05;
            blendConstant = 0.85;
            edge = 0.0;
        }
    #endif

    vec2 velocity = (texCoord - previousCoord.xy) * view;
    float historyWeight = float(previousCoord.x > 0.0 && previousCoord.x < 1.0 &&
                                previousCoord.y > 0.0 && previousCoord.y < 1.0);
    float velocityFactor = dot(velocity, velocity) * 10.0;

    #ifdef END
        if (z1 == 1.0)
        #if defined DISTANT_HORIZONS || defined VOXY
            if (!lodChunk)
        #endif
        {
            blendVariable *= 0.0;
            #if LIGHTSHAFT_QUALI_DEFINE == 2 // Medium (Default)
                edge = max(edge, regularEdge * 0.5);
            #elif LIGHTSHAFT_QUALI_DEFINE == 3 // High
                edge = max(edge, regularEdge * 0.75);
            #elif LIGHTSHAFT_QUALI_DEFINE == 4 // Very High
                edge = max(edge, regularEdge);
            #endif
        }
    #endif

    historyWeight *= max(exp(-velocityFactor) * blendVariable + blendConstant - min(length(cameraPosition - previousCameraPosition), 0.05) * edge, blendMinimum);
    return historyWeight;
}
