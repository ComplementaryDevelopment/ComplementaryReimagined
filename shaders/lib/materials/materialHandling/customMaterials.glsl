void GetCustomMaterials(inout vec3 normalM, inout float NdotU, inout float smoothnessG, inout float smoothnessD, inout float highlightMult, inout float emission, inout float materialMask) {
    // Normal Map
    #if NORMAL_MAP_STRENGTH != 0
        vec4 normalMap = texture2D(normals, texCoord);

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
        
        normalM = clamp(normalize(normalM * tbnMatrix), vec3(-1.0), vec3(1.0));

        NdotU = dot(normalM, upVec);
    #endif

    // Specular Map
    vec4 specularMap = texture2D(specular, texCoord);

    float smoothnessM = pow2(specularMap.r);
    smoothnessG = smoothnessM;
    smoothnessD = smoothnessM;
    highlightMult = 1.0 + 2.5 * specularMap.r;
    
    #if RP_MODE == 3 // labPBR
        highlightMult *= 0.5 + 0.5 * specularMap.g;
    #endif

    #if CUSTOM_EMISSION_INTENSITY > 0
        #if RP_MODE == 2 // SEUSPBR
            emission = specularMap.b;
        #elif RP_MODE == 3 // labPBR
            emission = specularMap.a < 1.0 ? specularMap.a : 0.0;
        #endif
        emission *= 0.03 * CUSTOM_EMISSION_INTENSITY;
    #endif

    #ifndef GBUFFERS_WATER
        #ifndef GBUFFERS_TERRAIN
            if (materialMask < OSIEBCA * 240.1)
        #endif
        {
            #if RP_MODE == 2 // SEUSPBR
                materialMask = specularMap.g * OSIEBCA * 240.0;
            #elif RP_MODE == 3 // labPBR
                if (specularMap.g < OSIEBCA * 229.1) {
                    materialMask = specularMap.g * OSIEBCA * 214.0;
                } else {
                    materialMask = specularMap.g - OSIEBCA * 15.0;
                }
            #endif
        }
    #endif
}