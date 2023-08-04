#include "/lib/atmospherics/clouds/cloudCoord.glsl"

vec3 cloudRainColor = mix(nightMiddleSkyColor, dayMiddleSkyColor, sunFactor) * 0.7;
vec3 cloudAmbientColor = mix(ambientColor * (sunVisibility2 * (0.55 + 0.1 * noonFactor) + 0.35), cloudRainColor * 0.5, rainFactor);
vec3 cloudLightColor   = mix(lightColor * (0.9 + 0.2 * noonFactor), cloudRainColor, rainFactor);

const float cloudStretch = CLOUD_STRETCH;
const float cloudHeight  = cloudStretch * 2.0;

float InterleavedGradientNoise() {
    float n = 52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y);
    #ifdef TAA
        return fract(n + 1.61803398875 * mod(float(frameCounter), 3600.0));
    #else
        return fract(n);
    #endif
}

#ifdef REALTIME_SHADOWS
    vec3 GetShadowOnCloudPosition(vec3 tracePos) {
        vec3 wpos = PlayerToShadow(tracePos - cameraPosition);
        float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
        float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
        vec3 shadowPosition = vec3(vec2(wpos.xy / distortFactor), wpos.z * 0.2);
        return shadowPosition * 0.5 + 0.5;
    }

    bool GetShadowOnCloud(vec3 tracePos, float cloudAltitude, float lowerPlaneAltitude, float higherPlaneAltitude) {
        const float cloudShadowOffset = 0.5;

        vec3 shadowPosition0 = GetShadowOnCloudPosition(tracePos);
        if (length(shadowPosition0.xy * 2.0 - 1.0) < 1.0) {
            float shadowsample0 = shadow2D(shadowtex0, shadowPosition0).z;

            if (shadowsample0 == 0.0) return true;
        }

        return false;
    }
#endif

bool GetCloudNoise(vec3 tracePos, float cloudAltitude) {
    vec2 coord = GetRoundedCloudCoord(ModifyTracePos(tracePos.xyz, cloudAltitude).xz);
    
    float noise = texture2D(colortex3, coord).b;
    float threshold = clamp(abs(cloudAltitude - tracePos.y) / cloudStretch, 0.001, 0.999);
    threshold = pow2(pow2(pow2(threshold)));
    return noise > (threshold * 0.5 + 0.25);
}

vec4 GetVolumetricClouds(float cloudAltitude, float distanceThreshold, inout float cloudLinearDepth, float skyFade, float skyMult0, vec3 nPlayerPos, float lViewPosM, float VdotS, float VdotU, float dither) {
	vec4 volumetricClouds = vec4(0.0);

    float higherPlaneAltitude = cloudAltitude + cloudStretch;
    float lowerPlaneAltitude  = cloudAltitude - cloudStretch;

    float lowerPlaneDistance  = (lowerPlaneAltitude - cameraPosition.y) / nPlayerPos.y;
    float higherPlaneDistance = (higherPlaneAltitude - cameraPosition.y) / nPlayerPos.y;
    float minPlaneDistance = min(lowerPlaneDistance, higherPlaneDistance);
          minPlaneDistance = max(minPlaneDistance, 0.0);
    float maxPlaneDistance = max(lowerPlaneDistance, higherPlaneDistance);
    if (maxPlaneDistance < 0.0) return vec4(0.0);
    float planeDistanceDif = maxPlaneDistance - minPlaneDistance;

    #ifndef HQ_REIM_CLOUD
        int sampleCount = max(int(planeDistanceDif) / 8, 12);
    #else
        int sampleCount = max(int(planeDistanceDif), 12);
    #endif

    float stepMult = planeDistanceDif / sampleCount;
    vec3 tracePos = cameraPosition + minPlaneDistance * nPlayerPos;
    vec3 traceAdd = nPlayerPos * stepMult;
    tracePos += traceAdd * dither;
    tracePos.y -= traceAdd.y;

    for (int i = 0; i < sampleCount; i++) {
        tracePos += traceAdd;

        vec3 cloudPlayerPos = tracePos - cameraPosition;
        float lTracePos = length(cloudPlayerPos);
        float lTracePosXZ = length(cloudPlayerPos.xz);
        float cloudMult = 1.0;
        if (lTracePosXZ > distanceThreshold) break;
        if (lTracePos > lViewPosM) {
            if (skyFade < 0.7) continue;
            else cloudMult = skyMult0;
        }

        if (GetCloudNoise(tracePos.xyz, cloudAltitude)) {
            float lightMult = 1.0;

            #ifdef REALTIME_SHADOWS
                if (GetShadowOnCloud(tracePos, cloudAltitude, lowerPlaneAltitude, higherPlaneAltitude)) {
                    #ifdef CLOUD_CLOSED_AREA_CHECK
                        if (eyeBrightness.y != 240) continue;
                        else
                    #endif
                    lightMult = 0.25;
                }
            #endif

            float cloudShading = 1.0 - (higherPlaneAltitude - tracePos.y) / cloudHeight;
            float cloudShadingM = 1.0 - pow2(cloudShading);

            float gradientNoise = InterleavedGradientNoise();

            vec3 cLightPos = ModifyTracePos(tracePos.xyz, cloudAltitude);
            vec3 cLightPosAdd = normalize(ViewToPlayer(lightVec * 1000000000.0)) * vec3(0.08);
            cLightPosAdd *= shadowTime;

            float VdotSM1 = max0(sunVisibility > 0.5 ? VdotS : - VdotS);
            #if DETAIL_QUALITY >= 1
                float light = 2.0;
                cLightPos += (1.0 + gradientNoise) * cLightPosAdd;
                light -= texture2D(colortex3, GetRoundedCloudCoord(cLightPos.xz)).b * cloudShadingM;
                cLightPos += gradientNoise * cLightPosAdd;
                light -= texture2D(colortex3, GetRoundedCloudCoord(cLightPos.xz)).b * cloudShadingM;

                float VdotSM2 = VdotSM1 * shadowTime * 0.25;
                    VdotSM2 += 0.5 * cloudShading + 0.08;
                cloudShading = VdotSM2 * light * lightMult;
            #endif
            
            vec3 colorSample = cloudAmbientColor + cloudLightColor * (0.07 + cloudShading);
            vec3 cloudSkyColor = GetSky(VdotU, VdotS, dither, true, false);
            float cloudFogFactor = clamp((distanceThreshold - lTracePosXZ) / distanceThreshold, 0.0, 0.75);
            float skyMult1 = 1.0 - 0.2 * (1.0 - skyFade) * max(sunVisibility2, nightFactor);
            float skyMult2 = 1.0 - 0.33333 * skyFade;
            colorSample = mix(cloudSkyColor, colorSample * skyMult1, cloudFogFactor * skyMult2);
            colorSample *= pow2(1.0 - max(blindness, darknessFactor));
            
            cloudLinearDepth = sqrt(lTracePos / far);
            volumetricClouds.a = pow(cloudFogFactor * 1.33333, 0.5 + 10.0 * pow(abs(VdotSM1), 90.0)) * cloudMult;
            volumetricClouds.rgb = colorSample;
            break;
        }
    }

    return volumetricClouds;
}