if (abs(materialMaskInt - 149.5) < 50.0) { // Entity Reflection Handling (see common.glsl for details)
    materialMaskInt -= 100;
    entityOrHand = true;
}

if (materialMaskInt != 0) {
    if (materialMaskInt < 9) {
        if (materialMaskInt < 5) {
            if (materialMaskInt < 3) {
                if (materialMaskInt == 1) { // Intense Fresnel
                    intenseFresnel = 1.0;
                } else /*if (materialMaskInt == 2)*/ { // Copper Fresnel
                    intenseFresnel = 1.0;
                    reflectColor = mix(vec3(0.5, 0.75, 0.5), vec3(1.0, 0.45, 0.3), sqrt1(smoothnessD));
                }
            } else {
                if (materialMaskInt == 3) { // Gold Fresnel
                    intenseFresnel = 1.0;
                    reflectColor = vec3(1.0, 0.8, 0.5);
                } else /*if (materialMaskInt == 4)*/ { // End Portal

                }
            }
        } else {
            if (materialMaskInt < 7) {
                if (materialMaskInt == 5) { // Redstone Fresnel
                    intenseFresnel = 1.0;
                    reflectColor = vec3(1.0, 0.3, 0.2);
                } else /*if (materialMaskInt == 6)*/ { //

                }
            } else {
                if (materialMaskInt == 7) { //

                } else /*if (materialMaskInt == 8)*/ { //

                }
            }
        }
    } else {
        if (materialMaskInt < 13) {
            if (materialMaskInt < 11) {
                if (materialMaskInt == 9) { //

                } else /*if (materialMaskInt == 10)*/ { //

                }
            } else {
                if (materialMaskInt == 11) { //

                } else /*if (materialMaskInt == 12)*/ { //

                }
            }
        } else {
            if (materialMaskInt < 15) {
                if (materialMaskInt == 13) { //

                } else /*if (materialMaskInt == 14)*/ { //

                }
            } else {
                if (materialMaskInt == 15) { //
                
                } else { // materialMaskInt >= 16 && <= 240

                }
            }
        }
    }
}