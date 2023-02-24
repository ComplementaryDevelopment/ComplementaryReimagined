#include "/lib/colors/lightAndAmbientColors.glsl"
#include "/lib/atmospherics/sky.glsl"

#ifdef CLOUDS_REIMAGINED
    #include "/lib/atmospherics/clouds/reimaginedClouds.glsl"
#endif
#if CLOUD_STYLE == 3
    #include "/lib/atmospherics/clouds/planarClouds.glsl"
#endif

vec4 GetClouds(inout float cloudLinearDepth, float skyFade, vec3 playerPos, vec3 viewPos, float lViewPos, float VdotS, float VdotU, float dither) {
    vec4 clouds = vec4(0.0);

    #ifdef CLOUDS_REIMAGINED
        const float threshold1 = 1000.0;
        const float threshold2 = 1000.0;

        vec3 nPlayerPos = normalize(playerPos);
        float lViewPosM = lViewPos < far * 1.5 ? lViewPos - 1.0 : 1000000000.0;
        float skyMult0 = pow2(skyFade * 3.333333 - 2.333333);

        #if CLOUD_STYLE == 1
            clouds =
            GetVolumetricClouds(CLOUD_ALT1, threshold1, cloudLinearDepth, skyFade, skyMult0, nPlayerPos, lViewPosM, VdotS, VdotU, dither);
        #else
            float maxCloudAlt = max(CLOUD_ALT1, CLOUD_ALT2);
            float minCloudAlt = min(CLOUD_ALT1, CLOUD_ALT2);
            if (maxCloudAlt - minCloudAlt < 10.0) maxCloudAlt = minCloudAlt + 12.0; // We can probably eliminate this check later

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

    #if CLOUD_STYLE == 3
        if (skyFade > 0.00001) clouds = DrawCloud(viewPos, dither, VdotS, VdotU) * skyFade;
    #endif

    return clouds;
}