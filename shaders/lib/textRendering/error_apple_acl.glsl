beginTextM(8, vec2(6, 10));
    text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
    printString((_I, _m, _p, _o, _r, _t, _a, _n, _t, _space, _E, _r, _r, _o, _r));
endText(color.rgb);

beginTextM(4, vec2(15, 36));
    printLine();
    text.fgCol = vec4(vec3(1.0), 1.0);
    printString((
        _C, _o, _l, _o, _r, _e, _d, _space, _L, _i, _g, _h, _t, _i, _n, _g, _space, _i, _s, _space,
        _n, _o, _t, _space
    ));
    printLine();
    printString((
        _s, _u, _p, _p, _o, _r, _t, _e, _d, _space, _o, _n, _space, _A, _p, _p, _l, _e, _dot
    ));
endText(color.rgb);

beginTextM(2, vec2(30, 125));
    printLine();
    text.fgCol = vec4(vec3(0.65), 1.0);
    printString((
        _A, _p, _p, _l, _e, _space,
        _d, _o, _e, _s, _space, _n, _o, _t, _space, _h, _a, _v, _e, _space, _t, _h, _e, _space,
        _f, _u, _n, _c, _t, _i, _o, _n, _a, _l, _i, _t, _y, _space, _t, _h, _a, _t, _space,
        _C, _o, _m, _p, _l, _e, _m, _e, _n, _t, _a, _r, _y, _space
    ));
    printLine();
    printString((
        _u, _s, _e, _s, _space, _t, _o, _space, _p, _r, _o, _v, _i, _d, _e, _space, _y, _o, _u, _space,
        _a, _space, _f, _u, _l, _l, _y, _space, _f, _l, _e, _d, _g, _e, _d, _space,
        _c, _o, _l, _o, _r, _e, _d, _space, _l, _i, _g, _h, _t, _i, _n, _g, _space,
        _e, _x, _p, _e, _r, _i, _e, _n, _c, _e, _dot
    ));
    printLine();
    printLine();
    printString((
        _D, _i, _s, _a, _b, _l, _e, _space, _i, _t, _space, _u, _n, _d, _e, _r, _colon, _space
    ));
    printLine();
    printString((
        _S, _h, _a, _d, _e, _r, _space, _S, _e, _t, _t, _i, _n, _g, _s,
        _space, _gt, _space, _P, _e, _r, _f, _o, _r, _m, _a, _n, _c, _e, _space, _gt, _space,
        _A, _d, _v, _a, _n, _c, _e, _d, _space, _C, _o, _l, _o, _r, _e, _d, _space, _L, _i, _g, _h, _t, _i, _n, _g
    ));
endText(color.rgb);