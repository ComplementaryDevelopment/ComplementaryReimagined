void ColorCodeProgram(inout vec4 color, int mat) {
    // Hold spider eyes in both hands to disable the function
    if (heldItemId == 40000 && heldItemId2 == 40000) return;

    #if defined GBUFFERS_TERRAIN // Green
        color.rgb = vec3(0.0, 1.0, 0.0);
    #elif defined GBUFFERS_WATER // Dark Blue
        color.rgb = vec3(0.0, 0.0, 1.0);
    #elif defined GBUFFERS_SKYBASIC // Light Blue
        color.rgb = vec3(0.0, 1.0, 2.0);
    #elif defined GBUFFERS_WEATHER // Magenta
        color.rgb = vec3(3.0, 0.0, 3.0);
    #elif defined GBUFFERS_BLOCK // Yellow
        color.rgb = vec3(1.5, 1.5, 0.0);
    #elif defined GBUFFERS_HAND // Orange
        color.rgb = vec3(1.5, 0.7, 0.0);
    #elif defined GBUFFERS_ENTITIES // Red
        color.rgb = vec3(1.5, 0.0, 0.0);
    #elif defined GBUFFERS_BASIC // White
        color.rgb = vec3(3.0, 3.0, 3.0);
    #elif defined GBUFFERS_SPIDEREYES // Red-Blue Vertical Stripes
        color.rgb = mix(vec3(2.0, 0.0, 0.0), vec3(0.0, 0.0, 2.0), mod(gl_FragCoord.x, 20.0) / 20.0);
    #elif defined GBUFFERS_TEXTURED   // Red-Blue Horizontal Stripes
        color.rgb = mix(vec3(2.0, 0.0, 0.0), vec3(0.0, 0.0, 2.0), mod(gl_FragCoord.y, 20.0) / 20.0);
    #elif defined GBUFFERS_CLOUDS     // Red-Green Vertical Stripes
        color.rgb = mix(vec3(2.0, 0.0, 0.0), vec3(0.0, 2.0, 0.0), mod(gl_FragCoord.x, 20.0) / 20.0);
    #elif defined GBUFFERS_BEACONBEAM // Red-Green Horizontal Stripes
        color.rgb = mix(vec3(2.0, 0.0, 0.0), vec3(0.0, 2.0, 0.0), mod(gl_FragCoord.y, 20.0) / 20.0);
    #elif defined GBUFFERS_ARMOR_GLINT  // Black-White Vertical Stripes
        color.rgb = mix(vec3(0.0, 0.0, 0.0), vec3(1.5, 1.5, 1.5), mod(gl_FragCoord.x, 20.0) / 20.0);
    #elif defined GBUFFERS_DAMAGEDBLOCK // Black-White Horizontal Stripes
        color.rgb = mix(vec3(0.0, 0.0, 0.0), vec3(1.5, 1.5, 1.5), mod(gl_FragCoord.y, 20.0) / 20.0);
    #elif defined GBUFFERS_SKYTEXTURED // Green-Blue Horizontal Stripes
        color.rgb = mix(vec3(0.0, 2.0, 0.0), vec3(0.0, 0.0, 2.0), mod(gl_FragCoord.y, 20.0) / 20.0);
    #endif

    color.rgb *= 0.75;

    // Hold spider eye in one hand to switch to ID=0 check mode
    if (heldItemId == 40000 || heldItemId2 == 40000) {
        if (mat == 0) // Magenta-Black Horizontal Stripes
        color.rgb = mix(vec3(0.0, 0.0, 0.0), vec3(3.0, 0.0, 3.0), mod(gl_FragCoord.y, 20.0) / 20.0);
        else
        color.rgb = vec3(0.25);
    }
}