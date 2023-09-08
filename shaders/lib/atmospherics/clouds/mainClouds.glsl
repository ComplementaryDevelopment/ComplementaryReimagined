#include "/lib/colors/lightAndAmbientColors.glsl"
#include "/lib/colors/cloudColors.glsl"
#include "/lib/atmospherics/sky.glsl"

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

    bool GetShadowOnCloud(vec3 tracePos, int cloudAltitude, float lowerPlaneAltitude, float higherPlaneAltitude) {
        const float cloudShadowOffset = 0.5;

        vec3 shadowPosition0 = GetShadowOnCloudPosition(tracePos);
        if (length(shadowPosition0.xy * 2.0 - 1.0) < 1.0) {
            float shadowsample0 = shadow2D(shadowtex0, shadowPosition0).z;

            if (shadowsample0 == 0.0) return true;
        }

        return false;
    }
#endif

#ifdef CLOUDS_REIMAGINED
    #include "/lib/atmospherics/clouds/reimaginedClouds.glsl"
#endif
#ifdef CLOUDS_UNBOUND
    #include "/lib/atmospherics/clouds/unboundClouds.glsl"
#endif

vec4 GetClouds(inout float cloudLinearDepth, float skyFade, vec3 playerPos, vec3 viewPos, float lViewPos, float VdotS, float VdotU, float dither) {
    vec4 clouds = vec4(0.0);

    vec3 nPlayerPos = normalize(playerPos);
    float lViewPosM = lViewPos < far * 1.5 ? lViewPos - 1.0 : 1000000000.0;
    float skyMult0 = pow2(skyFade * 3.333333 - 2.333333);

    #ifdef CLOUDS_REIMAGINED
        cloudAmbientColor *= 1.0 - 0.25 * rainFactor;

        const float threshold1 = 1000.0;
        const float threshold2 = 1000.0;

        #ifndef DOUBLE_REIM_CLOUDS
            clouds =
            GetVolumetricClouds(cloudAlt1i, threshold1, cloudLinearDepth, skyFade, skyMult0, nPlayerPos, lViewPosM, VdotS, VdotU, dither);
        #else
            int maxCloudAlt = max(cloudAlt1i, cloudAlt2i);
            int minCloudAlt = min(cloudAlt1i, cloudAlt2i);

            if (abs(cameraPosition.y - minCloudAlt) < abs(cameraPosition.y - maxCloudAlt)) {
                clouds =
                GetVolumetricClouds(minCloudAlt, threshold1, cloudLinearDepth, skyFade, skyMult0, nPlayerPos, lViewPosM, VdotS, VdotU, dither);
                if (clouds.a == 0.0) clouds =
                GetVolumetricClouds(maxCloudAlt, threshold2, cloudLinearDepth, skyFade, skyMult0, nPlayerPos, lViewPosM, VdotS, VdotU, dither);
            } else {
                clouds =
                GetVolumetricClouds(maxCloudAlt, threshold2, cloudLinearDepth, skyFade, skyMult0, nPlayerPos, lViewPosM, VdotS, VdotU, dither);
                if (clouds.a == 0.0) clouds =
                GetVolumetricClouds(minCloudAlt, threshold1, cloudLinearDepth, skyFade, skyMult0, nPlayerPos, lViewPosM, VdotS, VdotU, dither);
            }
        #endif
    #endif

    #ifdef CLOUDS_UNBOUND
        float thresholdMix = pow2(clamp01(VdotU * 5.0));
        float thresholdF = mix(far, 1000.0, thresholdMix * 0.5 + 0.5);

        clouds =
        GetVolumetricClouds(cloudAlt1i, thresholdF, cloudLinearDepth, skyFade, skyMult0, nPlayerPos, lViewPosM, VdotS, VdotU, dither);
    #endif

    return clouds;
}