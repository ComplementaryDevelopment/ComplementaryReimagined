#ifdef VOXY_PATCH
    #undef CONNECTED_GLASS_EFFECT
    #undef GENERATED_NORMALS
    #undef CUSTOM_PBR
    #ifndef IPBR_COMPAT_MODE
        #define IPBR_COMPAT_MODE
    #endif
#endif

#ifdef IPBR
    #include "/lib/materials/materialHandling/translucentIPBR.glsl"

    #ifdef GENERATED_NORMALS
        if (!noGeneratedNormals) GenerateNormals(normalM, colorP.rgb * colorP.a * 1.5);
    #endif

    #if IPBR_EMISSIVE_MODE != 1 && !defined VOXY_PATCH
        emission = GetCustomEmissionForIPBR(color, emission);
    #endif
#else
    #ifdef CUSTOM_PBR
        float smoothnessD, materialMaskPh;
        GetCustomMaterials(color, normalM, lmCoordM, NdotU, shadowMult, smoothnessG, smoothnessD, highlightMult, emission, materialMaskPh, viewPos, lViewPos);
        reflectMult = smoothnessD;
    #endif

    if (mat >= 32000) {
        if (mat < 32004) { // Water
            #include "/lib/materials/specificMaterials/translucents/water.glsl"
        } else if (mat == 30020) { // Nether Portal
            #ifdef SPECIAL_PORTAL_EFFECTS
                #include "/lib/materials/specificMaterials/translucents/netherPortal.glsl"
            #endif
        }
    }

#endif