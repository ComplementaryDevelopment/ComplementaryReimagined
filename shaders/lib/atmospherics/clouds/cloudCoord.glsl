#ifndef INCLUDE_CLOUD_COORD
    #define INCLUDE_CLOUD_COORD

    const float cloudNarrowness = 0.05;

    // Thanks to SixthSurge
    vec2 GetRoundedCloudCoord(vec2 pos, float cloudRoundness) { // cloudRoundness is meant to be 0.125 for clouds and 0.35 for cloud shadows
        vec2 coord = pos.xy + 0.5;
        vec2 signCoord = sign(coord);
        coord = abs(coord) + 1.0;
        vec2 i, f = modf(coord, i);
        f = smoothstep(0.5 - cloudRoundness, 0.5 + cloudRoundness, f);
        coord = i + f;
        return (coord - 0.5) * signCoord / 256.0;
    }

    vec3 ModifyTracePos(vec3 tracePos, int cloudAltitude) {
        #if CLOUD_SPEED_MULT == 100
            float wind = syncedTime;
        #else
            #define CLOUD_SPEED_MULT_M CLOUD_SPEED_MULT * 0.01
            float wind = frameTimeCounter * CLOUD_SPEED_MULT_M;
        #endif
        tracePos.x += wind;
        tracePos.z += cloudAltitude * 64.0;
        tracePos.xz *= cloudNarrowness;
        return tracePos.xyz;
    }

#endif