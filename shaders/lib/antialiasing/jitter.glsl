// Jitter offset from Chocapic13
vec2 jitterOffsets[8] = vec2[8](
    vec2( 0.125,-0.375),
    vec2(-0.125, 0.375),
    vec2( 0.625, 0.125),
    vec2( 0.375,-0.625),
    vec2(-0.625, 0.625),
    vec2(-0.875,-0.125),
    vec2( 0.375,-0.875),
    vec2( 0.875, 0.875)
);

vec2 TAAJitter(vec2 coord, float w) {
    #if TAA_JITTER_M > 0
        vec2 offset = jitterOffsets[int(framemod8)] * (w / scaledViewSizeF);
        #if TAA_JITTER_M == 1
            offset *= 0.125;
        #elif TAA_JITTER_M == 2
            offset *= 0.33;
        #endif
        return coord + offset;
    #else
        return coord;
    #endif
}
