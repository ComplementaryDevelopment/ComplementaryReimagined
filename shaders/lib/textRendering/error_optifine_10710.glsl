color.rgb = mix(color.rgb, vec3(0.0), 0.65);

beginTextM(8, vec2(6, 10));
    text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
    printString((_I, _m, _p, _o, _r, _t, _a, _n, _t, _space, _E, _r, _r, _o, _r));
endText(color.rgb);

beginTextM(4, vec2(15, 36));
    printLine();
    text.fgCol = vec4(vec3(1.0), 1.0);
    printString((_Y, _o, _u, _space, _n, _e, _e, _d, _space, _t, _o, _space, _u, _s, _e, _space, _t, _h, _e, _space, _quote, _A, _n, _g, _e, _l, _i, _c, _a, _quote));
    printLine();
    printString((_m, _o, _d, _space, _i, _n, _s, _t, _e, _a, _d, _space, _o, _f, _space, _O, _p, _t, _i, _f, _i, _n, _e, _dot));
    printLine();
endText(color.rgb);

beginTextM(2, vec2(30, 123));
    printLine();
    text.fgCol = vec4(vec3(0.65), 1.0);
    printString((_C, _o, _m, _p, _l, _e, _m, _e, _n, _t, _a, _r, _y, _space, _d, _o, _e, _s, _space, _n, _o, _t, _space,_w, _o, _r, _k, _space, _p, _r, _o, _p, _e, _r, _l, _y, _space, _w, _i, _t, _h, _space, _O, _p, _t, _i, _f, _i, _n, _e));
    printLine();
    printString((_o, _n, _space, _M, _i, _n, _e, _c, _r, _a, _f, _t, _space, _1, _dot, _7, _dot, _1, _0, _dot));
    printLine();
    printLine();
    printString((_A, _n, _g, _e, _l, _i, _c, _a, _space, _m, _o, _d, _space, _b, _r, _i, _n, _g, _s, _space, _m, _o, _d, _e, _r, _n, _space, _I, _r, _i, _s, _space, _f, _u, _n, _c, _t, _i, _o, _n, _a, _l, _i, _t, _y));
    printLine();
    printString((_t, _o, _space, _1, _dot, _7, _dot, _1, _0, _comma, _space, _i, _n, _c, _l, _u, _d, _i, _n, _g, _space, _s, _u, _p, _p, _o, _r, _t, _space, _f, _o, _r, _space, _C, _o, _m, _p, _l, _e, _m, _e, _n, _t, _a, _r, _y, _space, _S, _h, _a, _d, _e, _r, _s, _dot));
    printLine();
endText(color.rgb);
