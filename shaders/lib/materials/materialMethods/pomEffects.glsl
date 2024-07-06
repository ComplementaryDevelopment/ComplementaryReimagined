#include "/lib/util/dither.glsl"

vec2 vTexCoord = signMidCoordPos * 0.5 + 0.5;

#include "/lib/util/dFdxdFdy.glsl"

vec4 ReadNormal(vec2 coord) {
    coord = fract(coord) * vTexCoordAM.pq + vTexCoordAM.st;
    return textureGrad(normals, coord, dcdx, dcdy);
}

vec2 GetParallaxCoord(float parallaxFade, float dither, inout vec2 newCoord, inout float texDepth, inout vec3 traceCoordDepth) {
    float invParallaxQuality = 1.0 / POM_QUALITY;
    vec4 normalMap = ReadNormal(vTexCoord.st);
    vec2 normalMapM = normalMap.xy * 2.0 - 1.0;
    float normalCheck = normalMapM.x + normalMapM.y;
    float minHeight = 1.0 - invParallaxQuality;

    if (viewVector.z >= 0.0 || normalMap.a >= minHeight || normalCheck <= -1.999) return vTexCoord.st;

    vec2 interval = viewVector.xy * 0.25 * (1.0 - parallaxFade) * POM_DEPTH / (-viewVector.z * POM_QUALITY);

    float i = 0.0;
    vec2 localCoord;
    #if defined GBUFFERS_TERRAIN || defined GBUFFERS_BLOCK
        if (texDepth <= 1.0 - i * invParallaxQuality) {
            localCoord = vTexCoord.st + i * interval;
            texDepth = ReadNormal(localCoord).a;
            i = dither;
        }
    #endif

    for (; i < POM_QUALITY && texDepth <= 1.0 - i * invParallaxQuality; i++) {
        localCoord = vTexCoord.st + i * interval;
        texDepth = ReadNormal(localCoord).a;
    }

    float pI = float(max(i - 1, 0));
    traceCoordDepth.xy -= pI * interval;
    traceCoordDepth.z -= pI * invParallaxQuality;

    localCoord = fract(vTexCoord.st + pI * interval);
    newCoord = localCoord * vTexCoordAM.pq + vTexCoordAM.st;
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