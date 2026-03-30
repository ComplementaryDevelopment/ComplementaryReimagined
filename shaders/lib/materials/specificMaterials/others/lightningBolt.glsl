color = vec4(0.5, 0.55, 0.7, 1.0);

#ifndef GBUFFERS_LIGHTNING
    color.rgb *= 2.0;
    lmCoordM = vec2(0.0);
    shadowMult = vec3(0.0);

    emission = 0.5;
#endif