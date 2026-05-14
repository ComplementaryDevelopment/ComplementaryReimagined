void DoTranslucentTweaks(inout vec4 color, inout float fresnelM, inout float reflectMult, float lViewPos) {
    #ifdef MORE_REFLECTIVE_DISTANT_GLASS
        float tweakDistance = 192.0;

        float factor = smoothstep(0.0, tweakDistance, lViewPos);

        color.a = mix(color.a, 1.0, factor * 0.75);
        fresnelM = mix(fresnelM, 1.0, factor * 0.25);
        reflectMult = mix(reflectMult, reflectMult / color.a, factor);
    #endif
}