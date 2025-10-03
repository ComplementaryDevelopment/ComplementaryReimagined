color.rgb = mix(color.rgb, vec3(0.0), 0.65);

beginTextM(8, vec2(6, 10));
    text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
    printString((_I, _m, _p, _o, _r, _t, _a, _n, _t, _space, _E, _r, _r, _o, _r));
endText(color.rgb);

beginTextM(4, vec2(15, 36));
    printLine();
    text.fgCol = vec4(vec3(1.0), 1.0);
    printString((
        _quote, _W, _o, _r, _l, _d, _space, _S, _p, _a, _c, _e, _space, _R, _e, _f, _l, _e, _c, _t, _i, _o, _n, _s, _quote,
        _space, _f, _e, _a, _t, _u, _r, _e
    ));
    printLine();
    printString((
        _r, _e, _q, _u, _i, _r, _e, _s, _space, _t, _h, _e, _space, _quote, _A, _d, _v, _a, _n, _c, _e, _d, _space,
        _C, _o, _l, _o, _r, _space, _T, _r, _a, _c, _i, _n, _g, _quote
    ));
    printLine();
    printString((
        _s, _e, _t, _t, _i, _n, _g, _space, _t, _o, _space, _b, _e, _space, _e, _n, _a, _b, _l, _e, _d, _dot, _space,
        _P, _l, _e, _a, _s, _e, _space, _e, _i, _t, _h, _e, _r
    ));
    printLine();
    printString((
        _e, _n, _a, _b, _l, _e, _space, _quote, _A, _d, _v, _a, _n, _c, _e, _d, _space, _C, _o, _l, _o, _r,
        _space, _T, _r, _a, _c, _i, _n, _g, _quote, _space, _o, _r
    ));
    printLine();
    printString((
        _d, _i, _s, _a, _b, _l, _e, _space, _quote, _W, _o, _r, _l, _d, _space, _S, _p, _a, _c, _e, _space,
        _R, _e, _f, _l, _e, _c, _t, _i, _o, _n, _s, _quote, _dot
    ));
endText(color.rgb);