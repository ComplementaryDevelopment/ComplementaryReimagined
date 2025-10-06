#ifndef INCLUDE_CLOUD_SHADOWS
    #define INCLUDE_CLOUD_SHADOWS

    #ifdef CLOUDS_REIMAGINED
        #include "/lib/atmospherics/clouds/cloudCoord.glsl"
    #endif

    float GetCloudShadow(vec3 playerPos) {
        #ifndef OVERWORLD
            return 1.0;
        #endif

        float cloudShadow = 1.0;

        vec3 worldPos = playerPos + cameraPosition;
        #if defined DO_PIXELATION_EFFECTS && defined PIXELATED_SHADOWS
            //worldPos = playerPosPixelated + cameraPosition; // Disabled for now because cloud shadows are too soft to notice pixelation
        #endif

        #ifdef CLOUDS_REIMAGINED
            float EdotL = dot(eastVec, lightVec);
            float EdotLM = tan(acos(EdotL));

            #if SUN_ANGLE != 0
                float NVdotLM = tan(acos(dot(northVec, lightVec)));
            #endif

            float distToCloudLayer1 = cloudAlt1i - worldPos.y;
            vec3 cloudOffset1 = vec3(distToCloudLayer1 / EdotLM, 0.0, 0.0);
            #if SUN_ANGLE != 0
                cloudOffset1.z += distToCloudLayer1 / NVdotLM;
            #endif
            vec2 cloudPos1 = GetRoundedCloudCoord(ModifyTracePos(worldPos + cloudOffset1, cloudAlt1i).xz, 0.35);
            float cloudSample = texture2D(gaux4, cloudPos1).b;
            cloudSample *= clamp(distToCloudLayer1 * 0.1, 0.0, 1.0);

            #ifdef DOUBLE_REIM_CLOUDS
                float distToCloudLayer2 = cloudAlt2i - worldPos.y;
                vec3 cloudOffset2 = vec3(distToCloudLayer2 / EdotLM, 0.0, 0.0);
                #if SUN_ANGLE != 0
                    cloudOffset2.z += distToCloudLayer2 / NVdotLM;
                #endif
                vec2 cloudPos2 = GetRoundedCloudCoord(ModifyTracePos(worldPos + cloudOffset2, cloudAlt2i).xz, 0.35);
                float cloudSample2 = texture2D(gaux4, cloudPos2).b;
                cloudSample2 *= clamp(distToCloudLayer2 * 0.1, 0.0, 1.0);

                cloudSample = 1.0 - (1.0 - cloudSample) * (1.0 - cloudSample2);
            #endif

            cloudSample *= sqrt3(1.0 - abs(EdotL));
            cloudShadow = 1.0 - 0.85 * cloudSample;
        #else
            vec2 csPos = worldPos.xz + worldPos.y * 0.25;
            csPos.x += syncedTime;
            csPos *= 0.000002 * CLOUD_UNBOUND_SIZE_MULT;

            vec2 shadowoffsets[8] = vec2[8](
                vec2( 0.0   , 1.0   ),
                vec2( 0.7071, 0.7071),
                vec2( 1.0   , 0.0   ),
                vec2( 0.7071,-0.7071),
                vec2( 0.0   ,-1.0   ),
                vec2(-0.7071,-0.7071),
                vec2(-1.0   , 0.0   ),
                vec2(-0.7071, 0.7071));
            float cloudSample = 0.0;
            for (int i = 0; i < 8; i++) {
                cloudSample += texture2DLod(noisetex, csPos + 0.005 * shadowoffsets[i], 0.0).b;
            }

            cloudShadow = smoothstep1(pow2(min1(cloudSample * 0.2)));
        #endif

        return cloudShadow;
    }

#endif