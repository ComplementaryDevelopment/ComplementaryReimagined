float GetEnderStarNoise(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
}

vec3 GetEnderStars(vec3 viewPos, float VdotU) {
    vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos * 1000.0, 1.0)).xyz);

    vec3 starCoord = 0.65 * wpos / (abs(wpos.y) + length(wpos.xz));
    vec2 starCoord2 = starCoord.xz * 0.5;
    if (VdotU < 0.0) starCoord2 += 100.0;
    float starFactor = 1024.0;
    starCoord2 = floor(starCoord2 * starFactor) / starFactor;

    float star = 1.0;
    star *= GetEnderStarNoise(starCoord2.xy);
    star *= GetEnderStarNoise(starCoord2.xy+0.1);
    star *= GetEnderStarNoise(starCoord2.xy+0.23);
    star = max(star - 0.7, 0.0);
    star *= star;

    vec3 enderStars = star * endSkyColor * 3000.0;

    float absVdotU = abs(VdotU);
    float VdotUM2 = pow2(1.0 - absVdotU);
    enderStars *= min(VdotUM2 + 0.015, 0.05) + 0.015;

    float VdotUM3 = smoothstep(0.0, 0.25, absVdotU);
    float endBeamHeight = END_BEAM_HEIGHT * 200.0;
    float beamFactor = END_BEAM_INTENSITY * max0(endBeamHeight - abs(END_BEAM_CENTER_ALT - cameraPosition.y)) / endBeamHeight;
    enderStars *= pow(VdotUM3, min1(beamFactor + 0.001) * min1(END_BEAM_HEIGHT));

    return enderStars * END_STAR_INTENSITY;
}