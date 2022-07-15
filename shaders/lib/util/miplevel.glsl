vec2 midCoordPos = absMidCoordPos * signMidCoordPos;

vec2 dcdx = dFdx(texCoord.xy);
vec2 dcdy = dFdy(texCoord.xy);
vec2 mipx = dcdx / absMidCoordPos * 8.0;
vec2 mipy = dcdy / absMidCoordPos * 8.0;

float mipDelta = max(dot(mipx, mipx), dot(mipy, mipy));
float miplevel = max(0.5 * log2(mipDelta), 0.0);