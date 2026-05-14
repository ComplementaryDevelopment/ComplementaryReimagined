subsurfaceMode = 2;

#if defined GBUFFERS_TERRAIN || defined VOXY_PATCH
    materialMask = OSIEBCA * 253.0; // Reduced Edge TAA (Leaves)

    #ifdef COATED_TEXTURES
        doTileRandomisation = false;
    #endif
#endif

#ifdef IPBR
    float factor = min1(pow2(color.g - 0.15 * (color.r + color.b)) * 2.5);
    smoothnessG = factor * 0.4;
    highlightMult = factor * 4.0 + 2.0;
    #ifdef GBUFFERS_TERRAIN
        float fresnel = clamp(1.0 + dot(normalM, normalize(viewPos)), 0.0, 1.0);
        highlightMult *= 1.0 - pow2(pow2(fresnel));
    #else
        highlightMult *= 0.5;
    #endif
#endif

#ifdef SNOWY_WORLD
    snowMinNdotU = min(pow2(pow2(color.g)), 0.1);
    color.rgb = color.rgb * 0.5 + 0.5 * (color.rgb / glColor.rgb);
#endif

#if defined LEAF_SHADOW_OPTIMISATION && defined OVERWORLD
    shadowMult = vec3(sqrt1(max0(max(lmCoordM.y, min1(lmCoordM.x * 2.0)) - 0.95) * 20.0));
#endif