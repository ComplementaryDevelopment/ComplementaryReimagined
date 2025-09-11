#ifdef POM
    #include "/lib/materials/materialMethods/pomEffects.glsl"
#endif

#include "/lib/materials/materialMethods/customEmission.glsl"

void GetCustomMaterials(inout vec4 color, inout vec3 normalM, inout vec2 lmCoordM, inout float NdotU, inout vec3 shadowMult, inout float smoothnessG, inout float smoothnessD, inout float highlightMult, inout float emission, inout float materialMask, vec3 viewPos, float lViewPos) {
    vec2 texCoordM = texCoord;

    #ifdef POM
        float parallaxFade, parallaxTexDepth;
        vec2 parallaxLocalCoord;
        vec3 parallaxTraceCoordDepth;
        vec4 normalMap;
        bool skipPom = false;

        if (!skipPom) {
            texCoordM = vTexCoord.xy * vTexCoordAM.zw + vTexCoordAM.xy;

            parallaxFade = pow2(lViewPos / POM_DISTANCE);
            #ifdef GBUFFERS_ENTITIES
                if (entityId == 50008) parallaxFade = 1.1; // Item Frame, Glow Item Frame
            #endif
            #ifdef GBUFFERS_BLOCK
                if (blockEntityId == 5004) parallaxFade = 1.1; // Signs
            #endif
            #ifdef GBUFFERS_HAND
                if (heldItemId == 40004 || heldItemId2 == 40004) parallaxFade = 1.1; // Filled Map
            #endif

            parallaxTraceCoordDepth = vec3(texCoordM, 1.0);
            parallaxLocalCoord = vTexCoord.st;

            normalMap = ReadNormal(vTexCoord.st);
            parallaxFade += pow(normalMap.a, 64.0);

            if (parallaxFade < 1.0) {
                float dither = Bayer64(gl_FragCoord.xy);
                #ifdef TAA
                    dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
                #endif

                parallaxLocalCoord = GetParallaxCoord(parallaxFade, dither, texCoordM, parallaxTexDepth, parallaxTraceCoordDepth);

                normalMap = textureGrad(normals, texCoordM, dcdx, dcdy);
                color = textureGrad(tex, texCoordM, dcdx, dcdy);
                #if !defined GBUFFERS_ENTITIES && !defined GBUFFERS_BLOCK
                    color.rgb *= glColor.rgb;
                #else
                    color *= glColor;
                #endif

                shadowMult *= GetParallaxShadow(parallaxFade, dither, normalMap.a, parallaxLocalCoord, lightVec, tbnMatrix);
            }
        }
    #endif

    // Normal Map
    #if NORMAL_MAP_STRENGTH != 0
        #ifdef POM
            else normalMap = texture2D(normals, texCoordM);
        #else
            vec4 normalMap = texture2D(normals, texCoordM);
        #endif

        normalM = normalMap.xyz;
        normalM += vec3(0.5, 0.5, 0.0);
        normalM = pow(normalM, vec3(NORMAL_MAP_STRENGTH * 0.007)); // 70% strength by default
        normalM -= vec3(0.5, 0.5, 0.0);
        normalM = normalM * 2.0 - 1.0;

        #if RP_MODE == 3 // labPBR
            if (normalM.x + normalM.y > -1.999) {
                if (length(normalM.xy) > 1.0) normalM.xy = normalize(normalM.xy);
                normalM.z = sqrt(1.0 - dot(normalM.xy, normalM.xy));
                normalM.xyz = normalize(clamp(normalM.xyz, vec3(-1.0), vec3(1.0)));
            } else normalM = vec3(0.0, 0.0, 1.0);
        #endif

        #if defined POM && POM_QUALITY >= 128 && POM_LIGHTING_MODE == 2
            if (!skipPom) {
                float slopeThreshold = max(1.0 / POM_QUALITY, 1.0/255.0);
                if (parallaxTexDepth - parallaxTraceCoordDepth.z > slopeThreshold) {
                    vec3 slopeNormal = GetParallaxSlopeNormal(parallaxLocalCoord, parallaxTraceCoordDepth.z, viewVector);
                    normalM = mix(normalM, slopeNormal, 0.5 * pow2(max0(1.0 - parallaxFade * 2.0)));
                }
            }
        #endif

        normalM = clamp(normalize(normalM * tbnMatrix), vec3(-1.0), vec3(1.0));

        NdotU = dot(normalM, upVec);
        NdotUmax0 = max0(NdotU);
    #endif

    #if DIRECTIONAL_BLOCKLIGHT > 0
        mat3 lightmapTBN = mat3(normalize(dFdx(viewPos)), normalize(dFdy(viewPos)), vec3(0.0));
        lightmapTBN[2] = cross(lightmapTBN[0], lightmapTBN[1]);

        float lmCoordXDir = lmCoordM.x;
        vec2 deriv = vec2(dFdx(lmCoordXDir), dFdy(lmCoordXDir)) * 256.0;
        vec3 dir = normalize(vec3(deriv.x * lightmapTBN[0] +
                                0.0005  * lightmapTBN[2] +
                                deriv.y * lightmapTBN[1]));

        float pwr = clamp(dot(normalM, dir), -1.0, 1.0);
        float absPwr = abs(pwr);
        if (absPwr > 0.0) pwr = pow(absPwr, 9.0 / DIRECTIONAL_BLOCKLIGHT) * sign(pwr) * lmCoordXDir;
        if (length(deriv) > 0.001) lmCoordXDir = pow(max(lmCoordXDir, 0.00001), 1.0 - pwr);

        lmCoordM.x = mix(lmCoordM.x, lmCoordXDir, 0.01 * max0(100.0 - pow2(lViewPos)));
    #endif

    // Specular Map
    vec4 specularMap = texture2D(specular, texCoordM);

    float smoothnessM = pow2(specularMap.r);
    smoothnessG = smoothnessM;
    smoothnessD = smoothnessM;
    highlightMult = 1.0 + 2.5 * specularMap.r;

    #if RP_MODE == 3 // labPBR
        highlightMult *= 0.5 + 0.5 * specularMap.g;
    #endif

    emission = GetCustomEmission(specularMap, texCoordM);

    #ifndef GBUFFERS_WATER
        #if defined GBUFFERS_ENTITIES || defined GBUFFERS_HAND
            if (
                materialMask > OSIEBCA * 240.1
                && specularMap.g < 0.01
            ) return;
        #endif

        #if RP_MODE == 2 // seuspbr
            materialMask = specularMap.g * OSIEBCA * 240.0;

            color.rgb *= 1.0 - 0.25 * specularMap.g;
        #elif RP_MODE == 3 // labPBR
            if (specularMap.g < OSIEBCA * 229.1) {
                materialMask = specularMap.g * OSIEBCA * 214.0;
            } else {
                materialMask = specularMap.g - OSIEBCA * 15.0;

                color.rgb *= 0.75;
            }
        #endif
    #endif
}