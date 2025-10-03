noSmoothLighting = true; noDirectionalShading = true;
lmCoordM = vec2(1.0, 0.0);

#ifndef IPBR_COMPAT_MODE
    #ifndef DURING_WORLDSPACE_REF
        float blockRes = absMidCoordPos.x * atlasSize.x;
        vec2 signMidCoordPosM = abs((floor((signMidCoordPos + 1.0) * blockRes) + 0.5) / blockRes - 1.0);
    #else
        vec2 signMidCoordPosM = signMidCoordPos;
    #endif
    float value = 1.0 - max(signMidCoordPosM.x, signMidCoordPosM.y);
#else
    float value = 0.3;
#endif
emission = 0.3 + value + pow(dot(color.rgb, color.rgb) * 0.33, frogPow);
emission *= 1.7;

#ifdef DISTANT_LIGHT_BOKEH
    DoDistantLightBokehMaterial(emission, 2.0, lViewPos);
#endif

color.rgb = pow2(color.rgb);