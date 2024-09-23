#ifndef INCLUDE_LIGHT_AND_AMBIENT_MULTIPLIERS
    #define INCLUDE_LIGHT_AND_AMBIENT_MULTIPLIERS

    vec3 GetLightColorMult() {
        vec3 lightColorMult;

        #ifdef OVERWORLD
            vec3 morningLightMult = vec3(LIGHT_MORNING_R, LIGHT_MORNING_G, LIGHT_MORNING_B) * LIGHT_MORNING_I;
            vec3 noonLightMult = vec3(LIGHT_NOON_R, LIGHT_NOON_G, LIGHT_NOON_B) * LIGHT_NOON_I;
            vec3 nightLightMult = vec3(LIGHT_NIGHT_R, LIGHT_NIGHT_G, LIGHT_NIGHT_B) * LIGHT_NIGHT_I;
            vec3 rainLightMult = vec3(LIGHT_RAIN_R, LIGHT_RAIN_G, LIGHT_RAIN_B) * LIGHT_RAIN_I;

            lightColorMult = mix(noonLightMult, morningLightMult, invNoonFactor2);
            lightColorMult = mix(nightLightMult, lightColorMult, sunVisibility2);
            lightColorMult = mix(lightColorMult, dot(lightColorMult, vec3(0.33333)) * rainLightMult, rainFactor);
        #elif defined NETHER
            vec3 netherLightMult = vec3(LIGHT_NETHER_R, LIGHT_NETHER_G, LIGHT_NETHER_B) * LIGHT_NETHER_I;

            lightColorMult = netherLightMult;
        #elif defined END
            vec3 endLightMult = vec3(LIGHT_END_R, LIGHT_END_G, LIGHT_END_B) * LIGHT_END_I;

            lightColorMult = endLightMult;
        #endif

        return lightColorMult;
    }

    vec3 GetAtmColorMult() {
        vec3 atmColorMult;

        #ifdef OVERWORLD
            vec3 morningAtmMult = vec3(ATM_MORNING_R, ATM_MORNING_G, ATM_MORNING_B) * ATM_MORNING_I;
            vec3 noonAtmMult = vec3(ATM_NOON_R, ATM_NOON_G, ATM_NOON_B) * ATM_NOON_I;
            vec3 nightAtmMult = vec3(ATM_NIGHT_R, ATM_NIGHT_G, ATM_NIGHT_B) * ATM_NIGHT_I;
            vec3 rainAtmMult = vec3(ATM_RAIN_R, ATM_RAIN_G, ATM_RAIN_B) * ATM_RAIN_I;

            atmColorMult = mix(noonAtmMult, morningAtmMult, invNoonFactor2);
            atmColorMult = mix(nightAtmMult, atmColorMult, sunVisibility2);
            atmColorMult = mix(atmColorMult, dot(atmColorMult, vec3(0.33333)) * rainAtmMult, rainFactor);
        #elif defined NETHER
            vec3 netherAtmMult = vec3(ATM_NETHER_R, ATM_NETHER_G, ATM_NETHER_B) * ATM_NETHER_I;

            atmColorMult = netherAtmMult;
        #elif defined END
            vec3 endAtmMult = vec3(ATM_END_R, ATM_END_G, ATM_END_B) * ATM_END_I;

            atmColorMult = endAtmMult;
        #endif

        return atmColorMult;
    }

    vec3 lightColorMult;
    vec3 atmColorMult;
    vec3 sqrtAtmColorMult;

#endif //INCLUDE_LIGHT_AND_AMBIENT_MULTIPLIERS