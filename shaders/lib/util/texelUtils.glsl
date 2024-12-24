#define USE_TEXEL_OFFSET

#if PIXEL_SCALE == 0
    #define PIXEL_TEXEL_SCALE 2.0
#elif PIXEL_SCALE == 2
    #define PIXEL_TEXEL_SCALE 0.5
#elif PIXEL_SCALE == 3
    #define PIXEL_TEXEL_SCALE 0.25
#elif PIXEL_SCALE == 4
    #define PIXEL_TEXEL_SCALE 0.125
#elif PIXEL_SCALE == 5
    #define PIXEL_TEXEL_SCALE 0.0625
#else // 1 or out of range
    #define PIXEL_TEXEL_SCALE 1.0
#endif

#ifdef FRAGMENT_SHADER
    // Thanks to Nestorboy

    // Computes axis-aligned screen space offset to texel center.
    // https://forum.unity.com/threads/the-quest-for-efficient-per-texel-lighting.529948/#post-7536023
    vec2 ComputeTexelOffset(vec2 uv, vec4 texelSize) {
        // 1. Calculate how much the texture UV coords need to shift to be at the center of the nearest texel.
        vec2 uvCenter = (floor(uv * texelSize.zw) + 0.5) * texelSize.xy;
        vec2 dUV = uvCenter - uv;

        // 2. Calculate how much the texture coords vary over fragment space.
        //     This essentially defines a 2x2 matrix that gets texture space (UV) deltas from fragment space (ST) deltas.
        vec2 dUVdS = dFdx(uv);
        vec2 dUVdT = dFdy(uv);

        if (abs(dUVdS) + abs(dUVdT) == 0.0) return vec2(0.0);

        // 3. Invert the texture delta from fragment delta matrix. Where the magic happens.
        mat2x2 dSTdUV = mat2x2(dUVdT[1], -dUVdT[0], -dUVdS[1], dUVdS[0]) * (1.0 / (dUVdS[0] * dUVdT[1] - dUVdT[0] * dUVdS[1]));

        // 4. Convert the texture delta to fragment delta.
        vec2 dST = dUV * dSTdUV;
        return dST;
    }

    vec2 ComputeTexelOffset(sampler2D tex, vec2 uv) {
        vec2 texSize = textureSize(tex, 0) * PIXEL_TEXEL_SCALE;
        vec4 texelSize = vec4(1.0 / texSize.xy, texSize.xy);

        return ComputeTexelOffset(uv, texelSize);
    }

    vec4 TexelSnap(vec4 value, vec2 texelOffset) {
        if (texelOffset == 0.0) return value;
        vec4 dx = dFdx(value);
        vec4 dy = dFdy(value);

        vec4 valueOffset = dx * texelOffset.x + dy * texelOffset.y;
        valueOffset = clamp(valueOffset, -1.0, 1.0);

        return value + valueOffset;
    }

    vec3 TexelSnap(vec3 value, vec2 texelOffset) {
        if (texelOffset == 0.0) return value;
        vec3 dx = dFdx(value);
        vec3 dy = dFdy(value);

        vec3 valueOffset = dx * texelOffset.x + dy * texelOffset.y;
        valueOffset = clamp(valueOffset, -1.0, 1.0);

        return value + valueOffset;
    }

    vec2 TexelSnap(vec2 value, vec2 texelOffset) {
        if (texelOffset == 0.0) return value;
        vec2 dx = dFdx(value);
        vec2 dy = dFdy(value);

        vec2 valueOffset = dx * texelOffset.x + dy * texelOffset.y;
        valueOffset = clamp(valueOffset, -1.0, 1.0);

        return value + valueOffset;
    }

    float TexelSnap(float value, vec2 texelOffset) {
        if (texelOffset == 0.0) return value;
        float dx = dFdx(value);
        float dy = dFdy(value);

        float valueOffset = dx * texelOffset.x + dy * texelOffset.y;
        valueOffset = clamp(valueOffset, -1.0, 1.0);

        return value + valueOffset;
    }

    vec4 TexelSnap(vec4 value, vec2 texCoords, vec4 texelSize) {
        vec2 xyOffset = ComputeTexelOffset(texCoords, texelSize);
        return TexelSnap(value, xyOffset);
    }

    vec3 TexelSnap(vec3 value, vec2 texCoords, vec4 texelSize) {
        vec2 xyOffset = ComputeTexelOffset(texCoords, texelSize);
        return TexelSnap(value, xyOffset);
    }

    vec2 TexelSnap(vec2 value, vec2 texCoords, vec4 texelSize) {
        vec2 xyOffset = ComputeTexelOffset(texCoords, texelSize);
        return TexelSnap(value, xyOffset);
    }

    float TexelSnap(float value, vec2 texCoords, vec4 texelSize) {
        vec2 xyOffset = ComputeTexelOffset(texCoords, texelSize);
        return TexelSnap(value, xyOffset);
    }
#endif