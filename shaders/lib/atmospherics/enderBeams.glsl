#ifndef INCLUDE_ENDER_BEAMS
    #define INCLUDE_ENDER_BEAMS

    #include "/lib/colors/lightAndAmbientColors.glsl"

    vec2 wind = vec2(syncedTime * 0.00);

    float BeamNoise(vec2 planeCoord, vec2 wind) {
        float noise = texture2DLod(noisetex, planeCoord * 0.175   - wind * 0.0625, 0.0).b;
              noise+= texture2DLod(noisetex, planeCoord * 0.04375 + wind * 0.0375, 0.0).b * 5.0;

        return noise;
    }

    vec3 DrawEnderBeams(float VdotU, vec3 playerPos, vec3 nViewPos) {
        int sampleCount = 8;
        float beamMult = 1.0;
        float beamPow = 3.0;
        float beamPurpleReducer = vlFactor;
        float beamOrangeIncreaser = vlFactor;

        float VdotUM = 1.0 - pow2(VdotU);
        float VdotUM2 = sqrt(VdotUM) + 0.15 * smoothstep1(pow2(pow2(1.0 - abs(VdotU))));

        #if defined IS_IRIS && MC_VERSION >= 12109
            vec3 worldEndFlashPosition = mat3(gbufferModelViewInverse) * endFlashPosition;
            worldEndFlashPosition = normalize(vec3(worldEndFlashPosition.x, 0.0, worldEndFlashPosition.z));
            vec3 nViewPosWorld = mat3(gbufferModelViewInverse) * nViewPos;
            vec3 nViewPosWorldM = normalize(vec3(nViewPosWorld.x, 0.0, nViewPosWorld.z));

            float endFlashDirectionFactor = pow(max0(dot(worldEndFlashPosition, nViewPosWorldM)), 12.0);
            float endFlashFactor = endFlashIntensity * endFlashDirectionFactor;

            beamOrangeIncreaser = mix(beamOrangeIncreaser, 1.0, endFlashFactor);
            beamPurpleReducer = mix(beamPurpleReducer, 1.6, endFlashFactor);
            beamPow = mix(beamPow, 0.7, endFlashFactor * (pow(VdotUM, 8.0) * 0.75 + 0.25 * pow(1.0 - abs(VdotU) * 0.1 - 0.9 * pow2(VdotU), 30.0)));
            VdotUM = mix(VdotUM, sqrt2(VdotUM), endFlashFactor);
        #endif

        vec3 beamPurple = normalize(ambientColor * ambientColor * ambientColor) * (2.5 - beamPurpleReducer);
        vec3 beamOrange = endOrangeCol * (300.0 + 700.0 * beamOrangeIncreaser);

        vec4 beams = vec4(0.0);
        float gradientMix = 1.0;
        for (int i = 0; i < sampleCount; i++) {
            vec2 planeCoord = playerPos.xz + cameraPosition.xz;
            planeCoord *= (1.0 + i * 6.0 / sampleCount) * 0.0014;

            float noise = BeamNoise(planeCoord, wind);
                  noise = max(0.75 - 1.0 / abs(noise - (4.0 + VdotUM * 2.0)), 0.0) * 3.0;

            if (noise > 0.0) {
                noise *= 0.65;
                float fireNoise = texture2DLod(noisetex, abs(planeCoord * 0.2) - wind, 0.0).b;
                noise *= 0.5 * fireNoise + 0.75;
                noise = pow(noise, 1.75) * 2.9 / sampleCount;
                noise *= VdotUM2;

                vec3 beamColor = beamPurple;
                beamColor += beamOrange * pow2(pow2(fireNoise - 0.5));
                beamColor *= gradientMix / sampleCount;

                noise *= exp2(-6.0 * i / float(sampleCount));
                beams += vec4(noise * beamColor, noise);
            }
            gradientMix += 1.0;
        }

        beamMult *= pow(beams.a, beamPow) * 3.5;
        beams.rgb = sqrt(beams.rgb) * beamMult;

        return beams.rgb;
    }

#endif //INCLUDE_ENDER_BEAMS