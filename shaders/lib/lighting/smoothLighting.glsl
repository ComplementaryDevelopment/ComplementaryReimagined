float smoothLightmapSteepFactor = 2.8 - 0.6 * vsBrightness + XLIGHT_CURVE;
float smoothLightmapCalmFactor = 2.8 + 0.6 * vsBrightness - XLIGHT_CURVE;

float GetTweakedSmoothLightmap(float light) {
    float lightmapSteep = pow2(pow2(light * light))  * smoothLightmapSteepFactor;
    float lightmapCalm = light * smoothLightmapCalmFactor;
    return pow(lightmapSteep + lightmapCalm, 2.25);
}
