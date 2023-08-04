noSmoothLighting = true; noDirectionalShading = true;
lmCoordM = vec2(1.0, 0.0);

float blockRes = absMidCoordPos.x * atlasSize.x;
vec2 signMidCoordPosM = abs((floor((signMidCoordPos + 1.0) * blockRes) + 0.5) / blockRes - 1.0);
float value = 1.0 - max(signMidCoordPosM.x, signMidCoordPosM.y);
emission = 0.3 + value + pow(dot(color.rgb, color.rgb) * 0.33, frogPow);
emission *= 1.7;

color.rgb = pow2(color.rgb);