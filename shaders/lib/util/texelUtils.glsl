#ifdef FRAGMENT_SHADER
    // Thanks to Nestorboy

    // Computes axis-aligned screen space offset to texel center.
    // https://forum.unity.com/threads/the-quest-for-efficient-per-texel-lighting.529948/#post-7536023
    vec2 ComputeTexelOffset(vec2 texCoords, vec4 texelSize) {
        // 1. Calculate how much the texture UV coords need to shift to be at the center of the nearest texel.
        vec2 uvCenter = (floor(texCoords * texelSize.zw) + 0.5) * texelSize.xy;
        vec2 dUV = uvCenter - texCoords;

        // 2. Calculate how much the texture coords vary over fragment space.
        //     This essentially defines a 2x2 matrix that gets texture space (UV) deltas from fragment space (ST) deltas.
        vec2 dUVdS = dFdx(texCoords);
        vec2 dUVdT = dFdy(texCoords);

        if (abs(dUVdS) + abs(dUVdT) == 0.0) return vec2(0.0);

        // 3. Invert the texture delta from fragment delta matrix. Where the magic happens.
        mat2x2 dSTdUV = mat2x2(dUVdT[1], -dUVdT[0], -dUVdS[1], dUVdS[0]) * (1.0 / (dUVdS[0] * dUVdT[1] - dUVdT[0] * dUVdS[1]));

        // 4. Convert the texture delta to fragment delta.
        vec2 dST = dUV * dSTdUV;
        return dST;
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