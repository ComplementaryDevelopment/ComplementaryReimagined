#ifndef IPBR_COMPAT_MODE
    float minAlpha = min(color.a, texture2DLod(tex, texCoord, 0).a);
#else
    float minAlpha = color.a;
#endif

if (minAlpha > 0.001) {
    smoothnessG = 1.0;
    highlightMult = 3.5;
    reflectMult = 0.5;

    translucentMultCalculated = true;
    translucentMult = vec4(0.0, 0.0, 0.0, 1.0);
}

else {
    #ifdef FANCY_GLASS
        smoothnessG = 0.5;
        highlightMult = 2.5;
        reflectMult = 1.0;
        color.rgb = vec3(0.75, 0.8, 0.85);

        //translucentMultCalculated = true;
        //translucentMult.a = 0.0;

        color.a = max(color.a, GLASS_OPACITY);

        DoTranslucentTweaks(color, fresnelM, reflectMult, lViewPos);

        #ifdef RAIN_PUDDLES
            float dither = texture2DLod(noisetex, gl_FragCoord.xy / 128.0, 0.0).b;
            #ifdef TAA
                dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
            #endif

            if (dither > eyeBrightnessM2 * 1.1 - 0.05) discard;
        #endif
    #else
        discard;
    #endif
}
