#ifndef INCLUDE_CUSTOM_EMISSION
#define INCLUDE_CUSTOM_EMISSION

float GetCustomEmission(vec4 specularMap, vec2 texCoordM) {
    #if CUSTOM_EMISSION_INTENSITY > 0
        #if RP_MODE == 2 || RP_MODE == 1 && IPBR_EMISSIVE_MODE == 2 // seuspbr
            float emission = specularMap.b;
        #elif RP_MODE == 3 || RP_MODE == 1 && IPBR_EMISSIVE_MODE == 3 // labPBR
            float emission = specularMap.a < 1.0 ? specularMap.a : 0.0;

            vec4 specularMapL0 = texture2DLod(specular, texCoordM, 0);
            float emissionL0 = specularMapL0.a < 1.0 ? specularMapL0.a : 0.0;
            emission = min(emission, emissionL0); // Fixes issues caused by mipmaps
        #endif
        
        return emission * 0.03 * CUSTOM_EMISSION_INTENSITY;
    #else
        return 0.0;
    #endif
}

#ifdef IPBR
    float GetCustomEmissionForIPBR(inout vec4 color, float emission) {
        vec4 specularMapCheck = texture2DLod(specular, texCoord, 1000.0);
        if (specularMapCheck.a == 0.0) return emission;

        color = texture2D(tex, texCoord);

        vec4 specularMap = texture2D(specular, texCoord);
        float customEmission = GetCustomEmission(specularMap, texCoord);
        return customEmission;
    }
#endif

#endif //INCLUDE_CUSTOM_EMISSION