subsurfaceMode = 2;
materialMask = OSIEBCA * 253.0; // Reduced Edge TAA

#ifdef IPBR
    float factor = min1(pow2(color.g) * 2.0);
    smoothnessG = factor * 0.5;
    highlightMult = factor * 2.0;
#endif

#ifdef SNOWY_WORLD
    snowMinNdotU = min(pow2(pow2(color.g)), 0.1);
    color.rgb = color.rgb * 0.5 + 0.5 * (color.rgb / glColor.rgb);
#endif

#if SHADOW_QUALITY > 0 && SHADOW_QUALITY < 3
    shadowMult = vec3(sqrt1(max0(max(lmCoordM.y, min1(lmCoordM.x * 2.0)) - 0.95) * 20.0));
#endif