if (materialMaskInt != 0) {
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
            } else /*if (materialMaskInt == 4)*/ {

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
            if (materialMaskInt == 254) { // No SSAO, No TAA
                ssao = 1.0;
            } else /*if (materialMaskInt == "7 to 255 except 254")*/ { //
            
            }
        }
    }
}