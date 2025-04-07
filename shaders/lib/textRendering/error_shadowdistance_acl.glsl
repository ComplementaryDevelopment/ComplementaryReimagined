color.rgb = mix(color.rgb, vec3(0.0), 0.65);

beginTextM(8, vec2(6, 10));
    text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
    printString((_I, _m, _p, _o, _r, _t, _a, _n, _t, _space, _E, _r, _r, _o, _r));
endText(color.rgb);

beginTextM(4, vec2(15, 36));
    printLine();
    text.fgCol = vec4(vec3(1.0), 1.0);
    printString((
        _T, _h, _e, _space, _quote, _A, _d, _v, _a, _n, _c, _e, _d, _space, _C, _o, _l, _o, _r, _e, _d, _space,
        _L, _i, _g, _h, _t, _i, _n, _g, _quote
    ));
    printLine();
    printString((
        _s, _e, _t, _t, _i, _n, _g, _space, _m, _u, _s, _t, _space, _n, _o, _t, _space, _b, _e, _space,
        _s, _e, _t, _space, _h, _i, _g, _h, _e, _r, _space, _t, _h, _a, _n
    ));
    printLine();
    printString((
        _t, _h, _e, _space, _quote, _S, _h, _a, _d, _o, _w, _space, _D, _i, _s, _t, _a, _n, _c, _e, _quote, _space,
        _s, _e, _t, _t, _i, _n, _g, _dot
    ));
    printLine();
    printLine();
    printString((
        _G, _o, _space, _t, _o, _space, _E, _S, _C, _space, _gt, _space, _O, _p, _t, _i, _o, _n, _s, _space, _gt, _space,
        _S, _h, _a, _d, _e, _r, _space, _S, _e, _t, _t, _i, _n, _g, _s
    ));
    printLine();
    printString((
        _gt, _space, _P, _e, _r, _f, _o, _r, _m, _a, _n, _c, _e, _space, _gt, _space,
        _a, _n, _d, _space, _e, _i, _t, _h, _e, _r, _space, _i, _n, _c, _r, _e, _a, _s, _e
    ));
    printLine();
    printString((
        _t, _h, _e, _space, _S, _h, _a, _d, _o, _w, _space, _D, _i, _s, _t, _a, _n, _c, _e, _space,
        _s, _e, _t, _t, _i, _n, _g, _space, _o, _r, _space, _r, _e, _d, _u, _c, _e
    ));
    printLine();
    printString((
        _t, _h, _e, _space, _A, _d, _v, _a, _n, _c, _e, _d, _space, _C, _o, _l, _o, _r, _e, _d, _space,
        _L, _i, _g, _h, _t, _i, _n, _g, _space, _s, _e, _t, _t, _i, _n, _g
    ));
endText(color.rgb);