#define RAINBOW_DIAMETER 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00 4.25 4.50 4.75 5.00 5.25 5.50 5.75 6.00 6.25 6.50 6.75 7.00 7.50 8.00]
#define RAINBOW_STYLE 1 //[1 2]

vec3 GetRainbow(vec3 translucentMult, float z0, float z1, float lViewPos, float lViewPos1, float VdotL, float dither) {
    vec3 rainbow = vec3(0.0);

    float rainbowTime = min1(max0(SdotU - 0.1) / 0.15);
    rainbowTime = clamp(rainbowTime - pow2(pow2(pow2(noonFactor))) * 8.0, 0.0, 0.85);
    #if RAINBOWS == 1 // After Rain
        rainbowTime *= sqrt2(max0(wetness - 0.333) * 1.5) * invRainFactor * inRainy;
    #endif

    if (rainbowTime > 0.001) {
        float cloudLinearDepth = texelFetch(colortex4, texelCoord, 0).r;
        float cloudDistance = pow2(cloudLinearDepth + OSIEBCA * dither) * far;
        if (cloudDistance < lViewPos1) lViewPos = cloudDistance;

        float rainbowLength = max(far, 128.0) * 0.9;

        float rainbowCoord = clamp01(1.0 - (VdotL + 0.75) / (0.0625 * RAINBOW_DIAMETER));
        float rainbowFactor = rainbowCoord * (1.0 - rainbowCoord);
              rainbowFactor = pow2(pow2(rainbowFactor * 3.7));
              rainbowFactor *= pow2(min1(lViewPos / rainbowLength));
              rainbowFactor *= rainbowTime;
              rainbowFactor *= 1.0 - GetCaveFactor();

        if (rainbowFactor > 0.0) {
            #if RAINBOW_STYLE == 1
                float rainbowCoordM = pow(rainbowCoord, 1.4 + max(rainbowCoord - 0.5, 0.0) * 1.6);
                rainbowCoordM = smoothstep(0.0, 1.0, rainbowCoordM) * 0.85;
                rainbowCoordM += (dither - 0.5) * 0.1;
                    rainbow += clamp(abs(mod(rainbowCoordM * 6.0 + vec3(-0.55,4.3,2.2) ,6.0)-3.0)-1.0, 0.0, 1.0);
                    rainbowCoordM += 0.1;
                    rainbow += clamp(abs(mod(rainbowCoordM * 6.0 + vec3(-0.55,4.3,2.2) ,6.0)-3.0)-1.0, 0.0, 1.0);
                    rainbowCoordM -= 0.2;
                    rainbow += clamp(abs(mod(rainbowCoordM * 6.0 + vec3(-0.55,4.3,2.2) ,6.0)-3.0)-1.0, 0.0, 1.0);
                    rainbow /= 3.0;
                rainbow.r += pow2(max(rainbowCoord - 0.5, 0.0)) * (max(1.0 - rainbowCoord, 0.0)) * 26.0;
                rainbow = pow(rainbow, vec3(2.2)) * vec3(0.25, 0.075, 0.25) * 3.0;
            #else
                float rainbowCoordM = pow(rainbowCoord, 1.35);
                rainbowCoordM = smoothstep(0.0, 1.0, rainbowCoordM);
                rainbow += clamp(abs(mod(rainbowCoordM * 6.0 + vec3(0.0,4.0,2.0) ,6.0)-3.0)-1.0, 0.0, 1.0);
                rainbow *= rainbow * (3.0 - 2.0 * rainbow);
                rainbow = pow(rainbow, vec3(2.2)) * vec3(0.25, 0.075, 0.25) * 3.0;
            #endif

            if (z1 > z0 && lViewPos < rainbowLength)
            rainbow *= mix(translucentMult, vec3(1.0), lViewPos / rainbowLength);

            rainbow *= rainbowFactor;
        }
    }

    return rainbow;
}