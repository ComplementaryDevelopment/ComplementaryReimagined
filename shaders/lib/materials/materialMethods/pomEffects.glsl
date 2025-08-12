#include "/lib/util/dither.glsl"

vec2 vTexCoord = signMidCoordPos * 0.5 + 0.5;

#include "/lib/util/dFdxdFdy.glsl"

vec4 ReadNormal(vec2 coord) {
    coord = fract(coord) * vTexCoordAM.pq + vTexCoordAM.st;
    return textureGrad(normals, coord, dcdx, dcdy);
}

#define ATLAS(_local_) (fract(_local_) * vTexCoordAM.pq + vTexCoordAM.st)

// Created a new function to mitigate the side effects in case the original one has any reference outside this scope
vec4 ReadNormalLocal(vec2 localCoord) {
    vec2 atlasCoord = ATLAS(localCoord);
    return textureGrad(normals, atlasCoord, dcdx, dcdy);
}

vec2 GetParallaxCoord(float parallaxFade, float dither, inout vec2 newCoord, inout float texDepth, inout vec3 traceCoordDepth) {
    float invParallaxQuality = 1.0 / POM_QUALITY;
    float minHeight = 1.0 - invParallaxQuality;

    vec4 normalMap = ReadNormal(vTexCoord.st);
    vec2 normalMapM = normalMap.xy * 2.0 - 1.0;
    float normalCheck = normalMapM.x + normalMapM.y;

    // Early-outs: grazing view, flat height, extreme normal
    if (viewVector.z >= 0.0 || normalMap.a >= minHeight || normalCheck <= -1.999) return vTexCoord.st;
    // Layer step in tangent plane (scaled by depth & fade)
    vec2 layerStep = viewVector.xy * (0.25 * (1.0 - parallaxFade) * POM_DEPTH) / (-viewVector.z * POM_QUALITY);

    float i = 0.0;

    vec2 baseLC = vTexCoord.st;
    float h = texDepth; // if a caller-provided history exists; otherwise first sample overwrites

    // Ensure texDepth matches current start layer
    {
        vec2 lc0 = baseLC + i * layerStep;
        h = ReadNormalLocal(lc0).a;
    }

    #if defined GBUFFERS_TERRAIN || defined GBUFFERS_BLOCK
        if (texDepth <= 1.0 - i * invParallaxQuality) {
            i = dither;
            vec2 lc1 = baseLC + i * layerStep;
            h = texDepth = ReadNormalLocal(lc1).a;
        }
    #endif

    // Calculate stride based on |z|
    float viewFlat = clamp(1.0 - abs(viewVector.z), 0.0, 1.0);
    float coarseStride = mix(1.0, 2.0, clamp(0.4 * parallaxFade + 0.4 * viewVector.z*viewVector.z, 0.0, 1.0));
    coarseStride = (viewFlat > 0.7) ? 1.0 : coarseStride;

    // March forward by stride until we cross the height threshold
    float iPrev = i;
    float hPrev = h;
    for (; i < POM_QUALITY && h <= (1.0 - i * invParallaxQuality); i += coarseStride) {
        vec2 lc = baseLC + i * layerStep;
        hPrev = h;
        iPrev = i;
        h = ReadNormalLocal(lc).a;
    }

    // If we ran out of layers without crossing, clamp to last valid layer and return
    if (i >= POM_QUALITY && h <= (1.0 - (POM_QUALITY - 1.0) * invParallaxQuality)) {
        i = POM_QUALITY;
        float pI = float(max(int(i) - 1, 0));
        traceCoordDepth.xy -= pI * layerStep;
        traceCoordDepth.z  -= pI * invParallaxQuality;
        vec2 localCoord = fract(baseLC + pI * layerStep);
        newCoord = ATLAS(localCoord);
        texDepth = ReadNormalLocal(baseLC + pI * layerStep).a;
        return localCoord;
    }

    // Refine with a short binary search in the [iPrev, i] bracket
    float lo = max(iPrev, 0.0);
    float hi = clamp(i, 0.0, POM_QUALITY);
    float hLo = hPrev;
    float hHi = h;

    for (int it = 0; it < 3; ++it) {
        float mid = 0.5 * (lo + hi);
        float threshold = 1.0 - mid * invParallaxQuality;
        vec2  lcMid = baseLC + mid * layerStep;
        float hMid  = ReadNormalLocal(lcMid).a;

        bool below = (hMid <= threshold);
        lo = below ? mid : lo;
        hi = below ? hi  : mid;
        hLo = below ? hMid: hLo;
        hHi = below ? hHi : hMid;
    }

    // Pick the layer just before the crossing
    float pI = max(lo, 0.0);

    // Accumulate trace offsets (xy: coord, z: layer depth)
    traceCoordDepth.xy -= pI * layerStep;
    traceCoordDepth.z  -= pI * invParallaxQuality;

    vec2 localCoord = fract(baseLC + pI * layerStep);
    newCoord = ATLAS(localCoord);
    texDepth = ReadNormalLocal(baseLC + pI * layerStep).a;

    return localCoord;
}

float GetParallaxShadow(float parallaxFade, float dither, float height, vec2 coord, vec3 lightVec, mat3 tbn) {
    float parallaxshadow = 1.0;

    vec3 parallaxdir = tbn * lightVec;
    parallaxdir.xy *= 1.0 * POM_DEPTH; // Angle

    for (int i = 0; i < 4 && parallaxshadow >= 0.01; i++) {
        float stepLC = 0.025 * (i + dither);

        float currentHeight = height + parallaxdir.z * stepLC;

        vec2 parallaxCoord = fract(coord + parallaxdir.xy * stepLC) * vTexCoordAM.pq + vTexCoordAM.st;
        float offsetHeight = textureGrad(normals, parallaxCoord, dcdx, dcdy).a;

        parallaxshadow *= clamp(1.0 - (offsetHeight - currentHeight) * 4.0, 0.0, 1.0);
    }

    return mix(parallaxshadow, 1.0, parallaxFade);
}

// Big thanks to null511 for slope normals
vec3 GetParallaxSlopeNormal(vec2 texCoord, float traceDepth, vec3 viewDir) {
    vec2 atlasPixelSize = 1.0 / atlasSize;
    float atlasAspect = atlasSize.x / atlasSize.y;
    vec2 atlasCoord = fract(texCoord) * vTexCoordAM.pq + vTexCoordAM.st;

    vec2 tileSize = atlasSize * vTexCoordAM.pq;
    vec2 tilePixelSize = 1.0 / tileSize;

    vec2 tex_snapped = floor(atlasCoord * atlasSize) * atlasPixelSize;
    vec2 tex_offset = atlasCoord - (tex_snapped + 0.5 * atlasPixelSize);

    vec2 stepSign = sign(tex_offset);
    vec2 viewSign = sign(viewDir.xy);

    bool dir = abs(tex_offset.x * atlasAspect) < abs(tex_offset.y);
    vec2 tex_x, tex_y;

    if (dir) {
        tex_x = texCoord - vec2(tilePixelSize.x * viewSign.x, 0.0);
        tex_y = texCoord + vec2(0.0, stepSign.y * tilePixelSize.y);
    }
    else {
        tex_x = texCoord + vec2(tilePixelSize.x * stepSign.x, 0.0);
        tex_y = texCoord - vec2(0.0, viewSign.y * tilePixelSize.y);
    }

    float height_x = ReadNormal(tex_x).a;
    float height_y = ReadNormal(tex_y).a;

    if (dir) {
        if (!(traceDepth > height_y && viewSign.y != stepSign.y)) {
            if (traceDepth > height_x) return vec3(-viewSign.x, 0.0, 0.0);

            if (abs(viewDir.y) > abs(viewDir.x))
                return vec3(0.0, -viewSign.y, 0.0);
            else
                return vec3(-viewSign.x, 0.0, 0.0);
        }

        return vec3(0.0, -viewSign.y, 0.0);
    }
    else {
        if (!(traceDepth > height_x && viewSign.x != stepSign.x)) {
            if (traceDepth > height_y) return vec3(0.0, -viewSign.y, 0.0);

            if (abs(viewDir.y) > abs(viewDir.x))
                return vec3(0.0, -viewSign.y, 0.0);
            else
                return vec3(-viewSign.x, 0.0, 0.0);
        }

        return vec3(-viewSign.x, 0.0, 0.0);
    }
}
