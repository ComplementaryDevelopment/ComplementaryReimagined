const float packSizeSW = 16.0;

void DoSnowyWorld(inout vec4 color, inout float smoothnessG, inout float highlightMult, inout float smoothnessD, inout float emission,
                  vec3 playerPos, vec2 lmCoord, float snowFactor, float snowMinNdotU, float NdotU, int subsurfaceMode) {
    float snowFactorM = snowFactor * 1000.0 * max(NdotU - 0.9, snowMinNdotU) * max0(lmCoord.y - 0.9) * (0.9 - clamp(lmCoord.x, 0.8, 0.9));
    if (snowFactorM <= 0.0001) return;

    vec3 worldPos = playerPos + cameraPosition;
    vec2 noiseCoord = floor(packSizeSW * worldPos.xz + 0.001) / packSizeSW;
         noiseCoord += floor(packSizeSW * worldPos.y + 0.001) / packSizeSW;
    float noiseTexture = dot(vec2(0.25, 0.75), texture2D(noisetex, noiseCoord * 0.45).rg);
    vec3 snowColor = mix(vec3(0.65, 0.8, 0.85), vec3(1.0, 1.0, 1.0), noiseTexture * 0.75 + 0.125);

    color.rgb = mix(color.rgb, snowColor + color.rgb * emission * 0.2, snowFactorM);
    smoothnessG = mix(smoothnessG, 0.25 + 0.25 * noiseTexture, snowFactorM);
    highlightMult = mix(highlightMult, 2.0 - subsurfaceMode * 0.666, snowFactorM);
    smoothnessD = mix(smoothnessD, 0.0, snowFactorM);
    emission *= 1.0 - snowFactorM * 0.85;
}