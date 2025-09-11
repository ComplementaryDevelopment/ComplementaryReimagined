subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true;

#ifdef GBUFFERS_TERRAIN
    DoFoliageColorTweaks(color.rgb, shadowMult, snowMinNdotU, viewPos, nViewPos, lViewPos, dither);

    #ifdef COATED_TEXTURES
        doTileRandomisation = false;
    #endif
#endif

if (color.r > 0.7 && color.r > color.g * 1.2 && color.g > color.b * 2.0) { // Emissive Part
    lmCoordM.x = 0.5;
    emission = 5.0 * color.g;
    color.rgb *= color.rgb;
}