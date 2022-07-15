subsurfaceMode = 2;

#ifdef IPBR
    float factor = min1(pow2(color.g) * 2.0);
    smoothnessG = factor * 0.5;
    highlightMult = factor * 2.0;
#endif

#if SHADOW_QUALITY < 3
    shadowMult = vec3(sqrt1(max0(lmCoordM.y - 0.95) * 20.0));
#endif