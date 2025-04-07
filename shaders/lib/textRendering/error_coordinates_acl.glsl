color.rgb = mix(color.rgb, vec3(0.0), 0.65);

beginTextM(8, vec2(6, 10));
    text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
    printString((_I, _m, _p, _o, _r, _t, _a, _n, _t, _space, _E, _r, _r, _o, _r));
endText(color.rgb);

beginTextM(4, vec2(15, 36));
    printLine();
    text.fgCol = vec4(vec3(1.0), 1.0);
    printString((
        _C, _o, _l, _o, _r, _e, _d, _space, _L, _i, _g, _h, _t, _i, _n, _g, _space, _w, _i, _l, _l, 
        _space, _n, _o, _t, _space, _w, _o, _r, _k
    ));
    printLine();
    printString((
        _p, _r, _o, _p, _e, _r, _l, _y, _space, _a, _t, _space, _h, _i, _g, _h,
        _space, _w, _o, _r, _l, _d, _space, _c, _o, _o, _r, _d, _i, _n, _a, _t, _e, _s, _dot
    ));
    printLine();
    printLine();
    printString((
        _D, _i, _s, _a, _b, _l, _e, _space, _i, _t, _space, _u, _n, _d, _e, _r, _colon, _space
    ));
    printLine();
    printString((
        _E, _S, _C, _space, _gt, _space, _O, _p, _t, _i, _o, _n, _s, _space, _gt, _space,
        _S, _h, _a, _d, _e, _r, _space, _S, _e, _t, _t, _i, _n, _g, _s,
        _space, _gt
    ));
    printLine();
    printString((
        _P, _e, _r, _f, _o, _r, _m, _a, _n, _c, _e, _space, _gt, _space,
        _A, _d, _v, _a, _n, _c, _e, _d, _space, _C, _o, _l, _o, _r, _e, _d, _space, _L, _i, _g, _h, _t, _i, _n, _g
    ));
endText(color.rgb);