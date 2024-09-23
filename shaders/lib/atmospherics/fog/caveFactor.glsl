#ifndef INCLUDE_CAVE_FACTOR
    #define INCLUDE_CAVE_FACTOR

    float GetCaveFactor() {
        return clamp(1.0 - cameraPosition.y / oceanAltitude, 0.0, 1.0 - eyeBrightnessM);
    }
#endif