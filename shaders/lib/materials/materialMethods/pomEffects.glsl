#include "/lib/util/dither.glsl"

vec2 vTexCoord = signMidCoordPos * 0.5 + 0.5;

#include "/lib/util/dFdxdFdy.glsl"

vec4 ReadNormal(vec2 coord) {
    coord = fract(coord) * vTexCoordAM.pq + vTexCoordAM.st;
    return textureGrad(normals, coord, dcdx, dcdy);
}

vec4 ReadNormalLocalNoWrap(vec2 localCoord) {
    vec2 tileSize = atlasSize * vTexCoordAM.pq;
    vec2 eps = 0.5 / tileSize;
    vec2 lc = clamp(localCoord, eps, 1.0 - eps);
    vec2 atlasCoord = lc * vTexCoordAM.pq + vTexCoordAM.st;
    return textureGrad(normals, atlasCoord, dcdx, dcdy);
}

#define ATLAS(_local_) (fract(_local_) * vTexCoordAM.pq + vTexCoordAM.st)

// Created a new function to mitigate the side effects in case the original one has any reference outside this scope
vec4 ReadNormalLocal(vec2 localCoord) {
    vec2 atlasCoord = ATLAS(localCoord);
    return textureGrad(normals, atlasCoord, dcdx, dcdy);
}

vec2 GetParallaxCoord(float parallaxFade, float dither,
                      inout vec2 newCoord, inout float texDepth, inout vec3 traceCoordDepth)
{
    float invQ = 1.0 / POM_QUALITY;
    float minHeight = 1.0 - invQ;

    vec4 nm = ReadNormal(vTexCoord.st);
    vec2 nmM = nm.xy * 2.0 - 1.0;
    float normalCheck = nmM.x + nmM.y;

    if (viewVector.z >= 0.0 || nm.a >= minHeight || normalCheck <= -1.999 || parallaxFade > 0.98)
        return vTexCoord.st;

    vec2 layerStep = viewVector.xy * (0.25 * (1.0 - parallaxFade) * POM_DEPTH) / (max(-viewVector.z, 1e-4) * POM_QUALITY);

    float i = 0.0;
    vec2  local0 = vTexCoord.st;
    vec2  eps = TileEpsilon();

    // Start height (use no-wrap read)
    float h = ReadNormalLocalNoWrap(local0).a;
    float iPrev = 0.0, hPrev = h;

    #if defined GBUFFERS_TERRAIN || defined GBUFFERS_BLOCK
    if (texDepth <= 1.0 - i * invQ) {
        i = dither;
        vec2 lc1 = local0 + i * layerStep;
        // stop POM if we left the tile already
        if (any(lessThan(lc1, eps)) || any(greaterThan(lc1, 1.0 - eps))) {
            newCoord = AtlasClamp(clamp(local0, 0.0, 1.0));
            texDepth = h;
            return clamp(local0, 0.0, 1.0);
        }
        h = texDepth = ReadNormalLocalNoWrap(lc1).a;
    }
    #endif

    float viewFlat = clamp(1.0 - abs(viewVector.z), 0.0, 1.0);
    float coarseStride = mix(1.0, 2.0, clamp(0.4 * parallaxFade + 0.4 * viewVector.z*viewVector.z, 0.0, 1.0));
    coarseStride = (viewFlat > 0.7) ? 1.0 : coarseStride;

    // March forward by stride until we cross the height threshold
    // But no wrap
    for (; i < POM_QUALITY && h <= (1.0 - i * invQ); i += coarseStride) {
        vec2 lc = local0 + i * layerStep;
        if (any(lessThan(lc, eps)) || any(greaterThan(lc, 1.0 - eps))) {
            // left tile -> clamp to edge, return last valid
            float pI = max(iPrev, 0.0);
            vec2 lcSafe = clamp(local0 + pI * layerStep, eps, 1.0 - eps);
            traceCoordDepth.xy -= pI * layerStep;
            traceCoordDepth.z  -= pI * invQ;
            newCoord = lcSafe * vTexCoordAM.pq + vTexCoordAM.st;
            texDepth = ReadNormalLocalNoWrap(lcSafe).a;
            return lcSafe;
        }
        hPrev = h; iPrev = i;
        h = ReadNormalLocalNoWrap(lc).a;
    }

    // If we ran out of layers without crossing, clamp to last valid layer and return
    if (i >= POM_QUALITY && h <= (1.0 - (POM_QUALITY - 1.0) * invQ)) {
        float pI = float(max(int(POM_QUALITY) - 1, 0));
        vec2 lcSafe = clamp(local0 + pI * layerStep, eps, 1.0 - eps);
        traceCoordDepth.xy -= pI * layerStep;
        traceCoordDepth.z  -= pI * invQ;
        newCoord = lcSafe * vTexCoordAM.pq + vTexCoordAM.st;
        texDepth = ReadNormalLocalNoWrap(lcSafe).a;
        return lcSafe;
    }

    // Refine with a short binary search in the [iPrev, i] bracket
    // no wrap again
    float lo = max(iPrev, 0.0);
    float hi = clamp(i, 0.0, POM_QUALITY);
    float hLo = hPrev;
    float hHi = h;

    for (int it = 0; it < 3; ++it) {
        float mid = 0.5 * (lo + hi);
        float thr = 1.0 - mid * invQ;
        vec2  lcMid = local0 + mid * layerStep;

        if (any(lessThan(lcMid, eps)) || any(greaterThan(lcMid, 1.0 - eps))) {
            hi = mid;
            continue;
        }

        float hMid = ReadNormalLocalNoWrap(lcMid).a;
        bool below = (hMid <= thr);
        lo = below ? mid : lo;
        hi = below ? hi  : mid;
        hLo = below ? hMid: hLo;
        hHi = below ? hHi : hMid;
    }

    float pI = max(lo, 0.0);
    traceCoordDepth.xy -= pI * layerStep;
    traceCoordDepth.z  -= pI * invQ;

    vec2 lcFinal = clamp(local0 + pI * layerStep, eps, 1.0 - eps);
    newCoord = lcFinal * vTexCoordAM.pq + vTexCoordAM.st;
    texDepth = ReadNormalLocalNoWrap(lcFinal).a;
    return lcFinal;
}


float GetParallaxShadow(float parallaxFade, float dither, float height, vec2 coord, vec3 lightVec, mat3 tbn) {
    // Skip shadowing when far or almost faded
    if (parallaxFade >= 0.98) return 1.0;

    vec3 parallaxdir = tbn * lightVec;
    if (abs(parallaxdir.z) < 1e-4) return 1.0;

    // scale to depth
    parallaxdir.xy *= POM_DEPTH;

    // Fewer steps as fade increases (scene-aware)
    int MAX_STEPS = (parallaxFade < 0.25) ? 4 : 2;

    float parallaxshadow = 1.0;
    vec2  baseLocal = coord;
    vec2  eps = TileEpsilon();

    for (int i = 0; i < MAX_STEPS && parallaxshadow >= 0.01; ++i) {
        float stepLC = 0.025 * (float(i) + dither);

        float currentHeight = height + parallaxdir.z * stepLC;

        vec2 lc = baseLocal + parallaxdir.xy * stepLC;

        // trying to prevent seam shadows
        if (any(lessThan(lc, eps)) || any(greaterThan(lc, 1.0 - eps))) {
            break;
        }

        float offsetHeight = ReadNormalLocalNoWrap(lc).a;

        // soften when the surface rises above the ray
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
