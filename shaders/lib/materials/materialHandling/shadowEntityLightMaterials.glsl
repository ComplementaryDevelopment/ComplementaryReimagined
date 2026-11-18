if (entityId < 50080) {
    if (entityId < 50052) {
        if (entityId < 50024) {
            if (entityId == 50000)      { lightId = 87; } // End Crystal
            else if (entityId == 50008) { lightId = 89; } // Enderman
            else if (entityId == 50020) { lightId = 5;  } // Blaze
        } else {
            if (entityId == 50024) {
                vec4 color = texture2DLod(tex, texCoord, 0);
                if (color.b - color.g - color.r > 0.0001)
                                        { lightId = 91; } // Charged Creeper
            }
            else if (entityId == 50028) { lightId = 85; } // Drowned
            else if (entityId == 50048) { lightId = 85; } // Glow Squid
        }
    } else {
        if (entityId < 50060) {
            if (entityId == 50052)      { lightId = 24; } // Magma Cube
            else if (entityId == 50056) { lightId = 68; } // Stray
        } else {
            if (entityId == 50060)      { lightId = 64; } // Vex
            else if (entityId == 50072) { lightId = 86; } // Experience Orb
        }
    }
} else {
    if (entityId < 50116) {
        if (entityId < 50092) {
            if (entityId == 50080)      { lightId = 64; } // Allay
            else if (entityId == 50088) { lightId = 5;  } // Entity Flame
        } else {
            if (entityId == 50092)      { lightId = 85; } // Trident Entity
            else if (entityId == 50100) { lightId = 68; } // Bogged
            else if (entityId == 50108) { lightId = 88; } // Creaking
        }
    } else {
        if (entityId < 50140) {
            if (entityId == 50116)      { lightId = 81; } // Copper Golem
            else if (entityId == 50120) { lightId = 68; } // Parched
            else if (entityId == 50124) { lightId = 68; } // Zombie Nautilus
        } else {
            if (entityId == 50140)      { lightId = 40; } // Spectral Arrow
            else if (entityId == 50144) { lightId = 90; } // Eye of Ender
            else if (entityId == 50148) { lightId = 87; } // Dragon Fireball
        }
    }
}
