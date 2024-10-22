noSmoothLighting = true;

color.rgb *= 1.0 + pow2(max(-signMidCoordPos.y, float(NdotU > 0.9) * 1.2));

#ifdef SNOWY_WORLD
    snowFactor = 0.0;
#endif