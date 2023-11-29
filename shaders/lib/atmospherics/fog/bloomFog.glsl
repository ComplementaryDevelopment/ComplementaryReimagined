#ifdef CAVE_FOG
    #include "/lib/atmospherics/fog/caveFactor.glsl"
#endif

const float rainBloomAdd   = 8.0;
const float nightBloomAdd  = 3.0;
const float caveBloomAdd   = 14.0;
const float waterBloomAdd  = 14.0;

#ifdef BORDER_FOG
    const float netherBloomAdd = 14.0;
#else
    const float netherBloomAdd = 3.0;
#endif

float GetBloomFog(float lViewPos) {
    #ifdef OVERWORLD
        float bloomFog = pow2(pow2(1.0 - exp(-lViewPos * (0.02 + 0.04 * float(isEyeInWater == 1)))));

        float bloomFogMult;
        if (isEyeInWater != 1) {
            bloomFogMult = (rainFactor2 * rainBloomAdd + nightBloomAdd * (1.0 - sunFactor)) * eyeBrightnessM;
            #ifdef CAVE_FOG
                bloomFogMult += GetCaveFactor() * caveBloomAdd;
            #endif
        } else {
            bloomFogMult = waterBloomAdd;
        }
    #elif defined NETHER
        float farM = min(far, NETHER_VIEW_LIMIT); // consistency9023HFUE85JG
        float bloomFog = lViewPos / clamp(farM, 96.0, 256.0);
        bloomFog *= bloomFog * bloomFog;
        bloomFog = 1.0 - exp(-8.0 * bloomFog);
        bloomFog *= float(isEyeInWater == 0);

        float bloomFogMult = netherBloomAdd;
    #endif

    bloomFogMult *= BLOOM_STRENGTH * 8.33333;

    return 1.0 + bloomFog * bloomFogMult;
}