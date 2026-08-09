color.rgb = mix(color.rgb, vec3(0.0), 0.65);

beginTextM(8, vec2(6, 10));
    text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
    printString((_I, _m, _p, _o, _r, _t, _a, _n, _t, _space, _E, _r, _r, _o, _r));
endText(color.rgb);

beginTextM(4, vec2(15, 36));
    printLine();
    text.fgCol = vec4(vec3(1.0), 1.0);
    printString((_U, _s, _i, _n, _g, _space, _t, _h, _e, _space, _quote, _V, _o, _x, _y, _quote, _space, _a, _n, _d, _space, _quote, _D, _i, _s, _t, _a, _n, _t));
    printLine();
    printString((_H, _o, _r, _i, _z, _o, _n, _s, _quote, _space, _m, _o, _d, _s, _space, _a, _t, _space, _t, _h, _e, _space, _s, _a, _m, _e));
    printLine();
    printString((_t, _i, _m, _e, _space, _i, _s, _space, _n, _o, _t, _space, _s, _u, _p, _p, _o, _r, _t, _e, _d, _dot));
    printLine();
    printLine();
    printString((_P, _l, _e, _a, _s, _e, _space, _r, _e, _m, _o, _v, _e, _space, _a, _t, _space, _l, _e, _a, _s, _t, _space, _o, _n, _e, _space, _o, _f));
    printLine();
    printString((_t, _h, _e, _space, _m, _o, _d, _s, _space, _t, _o, _space, _f, _i, _x, _space, _t, _h, _i, _s, _space, _p, _r, _o, _b, _l, _e, _m, _dot));
endText(color.rgb);

beginTextM(2, vec2(30, 175));
    printLine();
    text.fgCol = vec4(vec3(0.65), 1.0);

endText(color.rgb);