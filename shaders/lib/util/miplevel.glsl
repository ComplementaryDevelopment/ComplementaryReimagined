vec2 midCoordPos = absMidCoordPos * signMidCoordPos;

#include "/lib/util/dFdxdFdy.glsl"

vec2 mipx = dcdx / absMidCoordPos * 8.0;
vec2 mipy = dcdy / absMidCoordPos * 8.0;

float mipDelta = max(dot(mipx, mipx), dot(mipy, mipy));
float miplevel = max(0.5 * log2(mipDelta), 0.0);

#if !defined GBUFFERS_ENTITIES && !defined GBUFFERS_HAND
    vec2 atlasSizeM = atlasSize;
#else
    vec2 atlasSizeM = atlasSize.x + atlasSize.y > 0.5 ? atlasSize : textureSize(tex, 0);
#endif