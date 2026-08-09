vec2 worldOutlineOffset[4] = vec2[4] (
    vec2(-1.0, 1.0),
    vec2( 0,   1.0),
    vec2( 1.0, 1.0),
    vec2( 1.0, 0)
);

void DoWorldOutline(inout vec3 color, float linearZ0, vec3 playerPos, float fresnel, float dither) {
    #ifndef WORLD_OUTLINE_SCALED
        vec2 scale = vec2(1.0 / view);
    #else
        float scm = 0.005;
        float fovScale = gbufferProjection[1][1];
        float distScale = max((far - near) * linearZ0 + near, 3.0);
        vec2 scale = vec2(scm / aspectRatio, scm) * fovScale / distScale;
        scale *= 0.99 + 0.2 * dither;
    #endif

    // Fix screen edges
    vec2 texCoordDirection = sign(texCoord - vec2(0.5));
    vec2 checkCoord = texCoord + scale * vec2(texCoordDirection.x * WORLD_OUTLINE_THICKNESS, texCoordDirection.y * WORLD_OUTLINE_THICKNESS);
    vec2 absCheckCoord = abs(checkCoord - vec2(0.5));
    float outlineMult = max0(0.5 - max(absCheckCoord.x, absCheckCoord.y));
          outlineMult = min1(outlineMult * 0.1 / (scale.x * WORLD_OUTLINE_THICKNESS));
 
    #if defined DISTANT_HORIZONS || defined VOXY
        float horizontalDistance = length(playerPos.xz);
        float verticalDistance = abs(playerPos.y);
        float fadeEndistance = max(horizontalDistance, verticalDistance);
    
        #ifdef DISTANT_HORIZONS
            float farM = far * 0.8;
        #else
            float farM = far * 0.95;
        #endif
        float fade = smoothstep(far * 0.4, farM, fadeEndistance);
        
        outlineMult *= 1.0 - fade;
    #endif

    if (outlineMult < 0.0001) return;

    outlineMult *= 0.25;

    float r0 = 1.0 / GetLinearDepth(texture2D(depthtex0, texCoord + vec2(-WORLD_OUTLINE_THICKNESS, -WORLD_OUTLINE_THICKNESS) * scale).r);
    float r1 = 1.0 / GetLinearDepth(texture2D(depthtex0, texCoord + vec2(-WORLD_OUTLINE_THICKNESS,  WORLD_OUTLINE_THICKNESS) * scale).r);
    float r2 = 1.0 / GetLinearDepth(texture2D(depthtex0, texCoord + vec2( WORLD_OUTLINE_THICKNESS, -WORLD_OUTLINE_THICKNESS) * scale).r);
    float r3 = 1.0 / GetLinearDepth(texture2D(depthtex0, texCoord + vec2( WORLD_OUTLINE_THICKNESS,  WORLD_OUTLINE_THICKNESS) * scale).r);
    float rA = 0.25 * (r0 + r1 + r2 + r3);
    float slope = (1.0 / linearZ0 - rA) * (linearZ0 * linearZ0);

    float threshold = linearZ0 / 2000.0 * WORLD_OUTLINE_THICKNESS;
    float outline = clamp(slope / threshold, 0.0, 1.0) * WORLD_OUTLINE_I;

    outline *= outlineMult;
 
    color += min(color * outline, vec3(outline));
}
