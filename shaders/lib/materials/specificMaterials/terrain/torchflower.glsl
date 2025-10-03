subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true;

#ifdef GBUFFERS_TERRAIN
    DoFoliageColorTweaks(color.rgb, shadowMult, snowMinNdotU, viewPos, nViewPos, lViewPos, dither);

    #ifdef COATED_TEXTURES
        doTileRandomisation = false;
    #endif
#endif

#if defined GBUFFERS_TERRAIN && !defined IPBR_COMPAT_MODE
    emission = (1.0 - abs(signMidCoordPos.x)) * max0(0.7 - abs(signMidCoordPos.y + 0.7));
    emission = pow1_5(emission) * 2.5;
#else
    if (color.r + color.g > color.b + 1.1) emission = 0.8;
    else if (color.r > color.g + color.b) emission = 0.2;
#endif