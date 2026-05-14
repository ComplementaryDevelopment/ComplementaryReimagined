#ifdef VOXY_PATCH
    #undef GENERATED_NORMALS
    #undef COATED_TEXTURES
    #undef CUSTOM_PBR
    #ifndef IPBR_COMPAT_MODE
        #define IPBR_COMPAT_MODE
    #endif
#endif

#ifdef IPBR
    vec3 maRecolor = vec3(0.0);
    #include "/lib/materials/materialHandling/terrainIPBR.glsl"

    #ifdef GENERATED_NORMALS
        if (!noGeneratedNormals) GenerateNormals(normalM, colorP);
    #endif

    #ifdef COATED_TEXTURES
        CoatTextures(color.rgb, noiseFactor, playerPos, doTileRandomisation);
    #endif

    #if IPBR_EMISSIVE_MODE != 1 && !defined VOXY_PATCH
        emission = GetCustomEmissionForIPBR(color, emission);
    #endif
#else
    #ifdef CUSTOM_PBR
        GetCustomMaterials(color, normalM, lmCoordM, NdotU, shadowMult, smoothnessG, smoothnessD, highlightMult, emission, materialMask, viewPos, lViewPos);
    #endif

    if (mat == 10001) { // No directional shading
        noDirectionalShading = true;
    } else if (mat == 10005) { // Grounded Waving Foliage
        subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true;
        #if defined GBUFFERS_TERRAIN || defined VOXY_PATCH
            DoFoliageColorTweaks(color.rgb, shadowMult, snowMinNdotU, viewPos, nViewPos, lViewPos, dither);
        #endif
    } else if (mat == 10009) { // Leaves
        #include "/lib/materials/specificMaterials/terrain/leaves.glsl"
    } else if (mat == 10013) { // Vine
        subsurfaceMode = 3, centerShadowBias = true; noSmoothLighting = true;
    } else if (mat == 10017) { // Non-waving Foliage
        subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true;
    } else if (mat == 10021) { // Upper Waving Foliage
        subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true;
        #if defined GBUFFERS_TERRAIN || defined VOXY_PATCH
            DoFoliageColorTweaks(color.rgb, shadowMult, snowMinNdotU, viewPos, nViewPos, lViewPos, dither);
        #endif
    } else if (mat == 10028) { // Modded Light Sources
        noSmoothLighting = true; noDirectionalShading = true;
        emission = GetLuminance(color.rgb) * 2.5;
    }

    #ifdef SNOWY_WORLD
    else if (mat == 10132) { // Grass Block:Normal
        if (glColor.b < 0.999) { // Grass Block:Normal:Grass Part
            snowMinNdotU = min(pow2(pow2(color.g)) * 1.9, 0.1);
            color.rgb = color.rgb * 0.5 + 0.5 * (color.rgb / glColor.rgb);
        }
    }
    #endif

    else if (lmCoord.x > 0.99999) lmCoordM.x = 0.95;
#endif