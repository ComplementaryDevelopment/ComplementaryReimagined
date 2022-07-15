#if HAND_SWAYING == 1
    const float handSwayMult = 0.5;
#elif HAND_SWAYING == 2
    const float handSwayMult = 1.0;
#elif HAND_SWAYING == 3
    const float handSwayMult = 2.0;
#endif
gl_Position.x += handSwayMult * (sin(frameTimeCounter * 0.86)) / 256.0;
gl_Position.y += handSwayMult * (cos(frameTimeCounter * 1.5)) / 64.0;

//dvd screensaver
//gl_Position.x -= - 0.1 + mod(frameTimeCounter * 0.3, 1.0) * sign(mod(frameTimeCounter * 0.3, 2.0) - 1.0) + float(mod(frameTimeCounter * 0.3, 2.0) < 1.0);
//gl_Position.y += mod(frameTimeCounter * 0.61803398875, 1.0) * sign(mod(frameTimeCounter * 0.61803398875, 2.0) - 1.0) + float(mod(frameTimeCounter * 0.61803398875, 2.0) < 1.0);