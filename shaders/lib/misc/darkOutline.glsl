vec2 darkOutlineOffsets[12] = vec2[12](
                               vec2( 1.0,0.0),
                               vec2(-1.0,1.0),
                               vec2( 0.0,1.0),
                               vec2( 1.0,1.0),
                               vec2(-2.0,2.0),
                               vec2(-1.0,2.0),
                               vec2( 0.0,2.0),
                               vec2( 1.0,2.0),
                               vec2( 2.0,2.0),
                               vec2(-2.0,1.0),
                               vec2( 2.0,1.0),
                               vec2( 2.0,0.0)
);

void DoDarkOutline(inout vec3 color, inout float skyFade, float z0, float dither) {
    vec2 scale = vec2(1.0 / view);

    float outline = 1.0;
    float z = GetLinearDepth(z0) * far * 2.0;
    float minZ = 1.0, sampleZA = 0.0, sampleZB = 0.0;

    #if DARK_OUTLINE_THICKNESS == 1
        int sampleCount = 4;
    #elif DARK_OUTLINE_THICKNESS == 2
        int sampleCount = 12;
    #endif

    for (int i = 0; i < sampleCount; i++) {
        vec2 offset = scale * darkOutlineOffsets[i];
        sampleZA = texture2D(depthtex0, texCoord + offset).r;
        sampleZB = texture2D(depthtex0, texCoord - offset).r;
        float sampleZsum = GetLinearDepth(sampleZA) + GetLinearDepth(sampleZB);
        outline *= clamp(1.0 - (z - sampleZsum * far), 0.0, 1.0);
        minZ = min(minZ, min(sampleZA, sampleZB));
    }

    if (outline < 0.909091) {
        vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, minZ, 1.0) * 2.0 - 1.0);
        viewPos /= viewPos.w;
        float lViewPos = length(viewPos.xyz);
        vec3 playerPos = ViewToPlayer(viewPos.xyz);
        vec3 nViewPos = normalize(viewPos.xyz);
        float VdotU = dot(nViewPos, upVec);
        float VdotS = dot(nViewPos, sunVec);

        vec3 newColor = vec3(0.0);
        DoFog(newColor, skyFade, lViewPos, playerPos, VdotU, VdotS, dither);

        color = mix(color, newColor, 1.0 - outline * 1.1);
    }
}