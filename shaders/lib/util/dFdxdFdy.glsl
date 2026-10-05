#ifndef INCLUDE_DFDX_DFDY
    #define INCLUDE_DFDX_DFDY

    vec2 dcdx = dFdx(texCoord.xy) * RENDER_SCALE_M;
    vec2 dcdy = dFdy(texCoord.xy) * RENDER_SCALE_M;
#endif
