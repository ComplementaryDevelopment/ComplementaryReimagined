#include "/lib/atmospherics/clouds/cloudCoord.glsl"

const float cloudStretch = 5.5;
const float cloudHeight  = cloudStretch * 2.0;

bool GetCloudNoise(vec3 tracePos, inout vec3 tracePosM, int cloudAltitude) {
    tracePosM = ModifyTracePos(tracePos, cloudAltitude);
    vec2 coord = GetRoundedCloudCoord(tracePosM.xz, 0.125);

    #ifdef DEFERRED1
        float noise = texture2D(colortex3, coord).b;
    #else
        float noise = texture2D(gaux4, coord).b;
    #endif

    float threshold = clamp(abs(cloudAltitude - tracePos.y) / cloudStretch, 0.001, 0.999);
    threshold = pow2(pow2(pow2(threshold)));
    return noise > threshold * 0.5 + 0.25;
}

vec4 GetVolumetricClouds(int cloudAltitude, float distanceThreshold, inout float cloudLinearDepth, float skyFade, float skyMult0, vec3 cameraPos, vec3 nPlayerPos, float lViewPosM, float VdotS, float VdotU, float dither) {
    vec4 volumetricClouds = vec4(0.0);

    float higherPlaneAltitude = cloudAltitude + cloudStretch;
    float lowerPlaneAltitude  = cloudAltitude - cloudStretch;

    float lowerPlaneDistance  = (lowerPlaneAltitude - cameraPos.y) / nPlayerPos.y;
    float higherPlaneDistance = (higherPlaneAltitude - cameraPos.y) / nPlayerPos.y;
    float minPlaneDistance = min(lowerPlaneDistance, higherPlaneDistance);
          minPlaneDistance = max(minPlaneDistance, 0.0);
    float maxPlaneDistance = max(lowerPlaneDistance, higherPlaneDistance);
    if (maxPlaneDistance < 0.0) return vec4(0.0);
    float planeDistanceDif = maxPlaneDistance - minPlaneDistance;

    #if CLOUD_QUALITY == 1 || !defined DEFERRED1
        int sampleCount = max(int(planeDistanceDif) / 16, 6);
    #elif CLOUD_QUALITY == 2
        int sampleCount = max(int(planeDistanceDif) / 8, 12);
    #elif CLOUD_QUALITY == 3
        int sampleCount = max(int(planeDistanceDif), 12);
    #endif

    float stepMult = planeDistanceDif / sampleCount;
    vec3 traceAdd = nPlayerPos * stepMult;
    vec3 tracePos = cameraPos + minPlaneDistance * nPlayerPos;
    tracePos += traceAdd * dither;
    tracePos.y -= traceAdd.y;

    #ifdef FIX_AMD_REFLECTION_CRASH
        sampleCount = min(sampleCount, 30); //BFARC
    #endif

    for (int i = 0; i < sampleCount; i++) {
        tracePos += traceAdd;

        vec3 cloudPlayerPos = tracePos - cameraPos;
        float lTracePos = length(cloudPlayerPos);
        float lTracePosXZ = length(cloudPlayerPos.xz);
        float cloudMult = 1.0;
        if (lTracePosXZ > distanceThreshold) break;
        if (lTracePos > lViewPosM) {
            if (skyFade < 0.7) continue;
            else cloudMult = skyMult0;
        }

        vec3 tracePosM;
        if (GetCloudNoise(tracePos, tracePosM, cloudAltitude)) {
            float lightMult = 1.0;

            #if SHADOW_QUALITY > -1
                float shadowLength = min(shadowDistance, far) * 0.9166667; //consistent08JJ622
                if (shadowLength > lTracePos)
                if (GetShadowOnCloud(tracePos, cameraPos, cloudAltitude, lowerPlaneAltitude, higherPlaneAltitude)) {
                    #ifdef CLOUD_CLOSED_AREA_CHECK
                        if (eyeBrightness.y != 240) continue;
                        else
                    #endif
                    lightMult = 0.25;
                }
            #endif

            float cloudShading = 1.0 - (higherPlaneAltitude - tracePos.y) / cloudHeight;
            float VdotSM1 = max0(sunVisibility > 0.5 ? VdotS : - VdotS);

            #if CLOUD_QUALITY >= 2
                #ifdef DEFERRED1
                    float cloudShadingM = 1.0 - pow2(cloudShading);
                #else
                    float cloudShadingM = 1.0 - cloudShading;
                #endif

                float gradientNoise = InterleavedGradientNoiseForClouds();

                vec3 cLightPos = tracePosM;
                vec3 cLightPosAdd = normalize(ViewToPlayer(lightVec * 1000000000.0)) * vec3(0.08);
                cLightPosAdd *= shadowTime;

                float light = 2.0;
                cLightPos += (1.0 + gradientNoise) * cLightPosAdd;
                #ifdef DEFERRED1
                    light -= texture2D(colortex3, GetRoundedCloudCoord(cLightPos.xz, 0.125)).b * cloudShadingM;
                #else
                    light -= texture2D(gaux4, GetRoundedCloudCoord(cLightPos.xz, 0.125)).b * cloudShadingM;
                #endif
                cLightPos += gradientNoise * cLightPosAdd;
                #ifdef DEFERRED1
                    light -= texture2D(colortex3, GetRoundedCloudCoord(cLightPos.xz, 0.125)).b * cloudShadingM;
                #else
                    light -= texture2D(gaux4, GetRoundedCloudCoord(cLightPos.xz, 0.125)).b * cloudShadingM;
                #endif

                float VdotSM2 = VdotSM1 * shadowTime * 0.25;
                    VdotSM2 += 0.5 * cloudShading + 0.08;
                cloudShading = VdotSM2 * light * lightMult;
            #endif

            vec3 colorSample = cloudAmbientColor + cloudLightColor * (0.07 + cloudShading);
            vec3 cloudSkyColor = GetSky(VdotU, VdotS, dither, true, false);
            #ifdef ATM_COLOR_MULTS
                cloudSkyColor *= sqrtAtmColorMult; // C72380KD - Reduced atmColorMult impact on some things
            #endif
            float distanceRatio = (distanceThreshold - lTracePosXZ) / distanceThreshold;
            float cloudDistanceFactor = clamp(distanceRatio, 0.0, 0.75);
            #ifndef DISTANT_HORIZONS
                float cloudFogFactor = cloudDistanceFactor;
            #else
                float cloudFogFactor = pow1_5(clamp(distanceRatio, 0.0, 1.0)) * 0.75;
            #endif
            float skyMult1 = 1.0 - 0.2 * (1.0 - skyFade) * max(sunVisibility2, nightFactor);
            float skyMult2 = 1.0 - 0.33333 * skyFade;
            colorSample = mix(cloudSkyColor, colorSample * skyMult1, cloudFogFactor * skyMult2);
            colorSample *= pow2(1.0 - maxBlindnessDarkness);

            cloudLinearDepth = sqrt(lTracePos / renderDistance);
            volumetricClouds.a = pow(cloudDistanceFactor * 1.33333, 0.5 + 10.0 * pow(abs(VdotSM1), 90.0)) * cloudMult;
            volumetricClouds.rgb = colorSample;
            break;
        }
    }

    return volumetricClouds;
}