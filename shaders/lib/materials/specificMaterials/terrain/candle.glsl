noSmoothLighting = true;

color.rgb *= 1.0 + 0.7 * pow2(max(-signMidCoordPos.y + 0.6, float(NdotU > 0.9) * 1.6));

#ifdef SNOWY_WORLD
    snowFactor = 0.0;
#endif