#ifndef INCLUDE_ENDER_BEAMS
    #define INCLUDE_ENDER_BEAMS

    #include "/lib/colors/lightAndAmbientColors.glsl"

    vec2 wind = vec2(frameTimeCounter * 0.001);

    float BeamNoise(vec2 planeCoord, vec2 wind) {
        float noise = texture2DLod(noisetex, planeCoord * 0.175   - wind, 0.0).b * 0.5;
              noise+= texture2DLod(noisetex, planeCoord * 0.04375 + wind * 0.5, 0.0).b * 2.0;
              noise+= texture2DLod(noisetex, planeCoord * 0.7     - wind, 0.0).b * 0.5;

        return noise / 3.0;
    }

    vec3 DrawEnderBeams(vec3 playerPos, vec3 nViewPos, float scale) {
        float beamPowBeforeAltitude = 1.0;
        float beamPowAfterAltitude = 1.75;
        float lPlayerPosXZ = length(playerPos.xz);
        float beamPurpleReducer = vlFactor;
        float beamOrangeIncreaser = vlFactor * 1.5;

        #ifdef END_FLASHES
            vec3 worldEndFlashPosition = mat3(gbufferModelViewInverse) * endFlashPosition;
            worldEndFlashPosition = normalize(vec3(worldEndFlashPosition.x, 0.0, worldEndFlashPosition.z));
            vec3 nViewPosWorld = mat3(gbufferModelViewInverse) * nViewPos;
            vec3 nViewPosWorldM = normalize(vec3(nViewPosWorld.x, 0.0, nViewPosWorld.z));

            float endFlashDirectionFactor = pow(max0(dot(worldEndFlashPosition, nViewPosWorldM)), 32.0 - 24.0 * vlFactor);
            float endFlashFactor = endFlashIntensityM * endFlashDirectionFactor;
            
            endFlashFactor *= smoothstep(0.0, 512.0, lPlayerPosXZ);

            beamOrangeIncreaser = mix(beamOrangeIncreaser, 1.5, endFlashFactor);
            beamPurpleReducer = mix(beamPurpleReducer, 1.5, endFlashFactor);

            beamPowBeforeAltitude *= 1.0 - endFlashFactor;
            beamPowAfterAltitude *= 1.0 - 0.4 * endFlashFactor;
        #endif

        vec3 beamPurple = normalize(ambientColor * ambientColor * ambientColor) * (2.5 - beamPurpleReducer);
        vec3 beamOrange = endOrangeCol * (300.0 + 700.0 * beamOrangeIncreaser);

        vec2 planeCoordRaw = playerPos.xz + cameraPosition.xz;
        vec2 planeCoord = planeCoordRaw * 0.0007 * scale;

        float noise = BeamNoise(planeCoord, wind);
        float fireNoise = texture2DLod(noisetex, abs(planeCoord * 0.1) - wind, 0.0).b;

        float uncenteredDistance = (2000.0 * pow2(noise) + 40.0 * fireNoise) * 0.001 * END_BEAM_HEIGHT * (250.0 + 0.5 * lPlayerPosXZ);
        float altitude = playerPos.y + cameraPosition.y;
        float altitudeDis = abs(altitude - END_BEAM_CENTER_ALT);
        float altitudeFactor = 0.5 * smoothstep(uncenteredDistance, 0.0, altitudeDis)
                             + 0.5 * smoothstep(4.0 * uncenteredDistance, 0.0, altitudeDis);
        
        noise = pow2(noise) * 0.7 + 0.3 * fireNoise;
        noise = pow(noise, beamPowBeforeAltitude);
        noise *= pow(altitudeFactor, 4.0);
        noise = pow(noise, beamPowAfterAltitude);

        vec3 beamColor = beamPurple;
        beamColor += beamOrange * (0.0015 + 0.2 * smoothstep(0.0, 256.0, lPlayerPosXZ) * pow2(pow2(fireNoise - 0.5)));

        vec3 beams = noise * END_BEAM_INTENSITY * beamColor * (1.0 + smoothstep(0.0, 128.0, lPlayerPosXZ));

        if(any(isnan(beams))) beams = vec3(0.0);

        return beams;
    }

#endif //INCLUDE_ENDER_BEAMS