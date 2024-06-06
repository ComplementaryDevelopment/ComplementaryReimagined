#if TAA_MODE == 1
    float blendMinimum = 0.3;
    float blendVariable = 0.2;
    float blendConstant = 0.7;

    float regularEdge = 20.0;
    float extraEdgeMult = 3.0;
#elif TAA_MODE == 2
    float blendMinimum = 0.6;
    float blendVariable = 0.2;
    float blendConstant = 0.7;

    float regularEdge = 5.0;
    float extraEdgeMult = 3.0;
#endif

// Previous frame reprojection from Chocapic13
vec2 Reprojection(vec3 pos, vec3 cameraOffset) {
    pos = pos * 2.0 - 1.0;

    vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0);
    viewPosPrev /= viewPosPrev.w;
    viewPosPrev = gbufferModelViewInverse * viewPosPrev;

    vec4 previousPosition = viewPosPrev + vec4(cameraOffset, 0.0);
    previousPosition = gbufferPreviousModelView * previousPosition;
    previousPosition = gbufferPreviousProjection * previousPosition;
    return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
}

vec3 RGBToYCoCg(vec3 col) {
    return vec3(
        col.r * 0.25 + col.g * 0.5 + col.b * 0.25,
        col.r * 0.5 - col.b * 0.5,
        col.r * -0.25 + col.g * 0.5 + col.b * -0.25
    );
}

vec3 YCoCgToRGB(vec3 col) {
    float n = col.r - col.b;
    return vec3(n + col.g, col.r + col.b, n - col.g);
}

vec3 ClipAABB(vec3 q, vec3 aabb_min, vec3 aabb_max){
    vec3 p_clip = 0.5 * (aabb_max + aabb_min);
    vec3 e_clip = 0.5 * (aabb_max - aabb_min) + 0.00000001;

    vec3 v_clip = q - vec3(p_clip);
    vec3 v_unit = v_clip.xyz / e_clip;
    vec3 a_unit = abs(v_unit);
    float ma_unit = max(a_unit.x, max(a_unit.y, a_unit.z));

    if (ma_unit > 1.0)
        return vec3(p_clip) + v_clip / ma_unit;
    else
        return q;
}

ivec2 neighbourhoodOffsets[8] = ivec2[8](
    ivec2( 1, 1),
    ivec2( 1,-1),
    ivec2(-1, 1),
    ivec2(-1,-1),
    ivec2( 1, 0),
    ivec2( 0, 1),
    ivec2(-1, 0),
    ivec2( 0,-1)
);

void NeighbourhoodClamping(vec3 color, inout vec3 tempColor, float z0, float z1, inout float edge) {
    vec3 minclr = color;
    vec3 maxclr = minclr;

    int cc = 2;
    ivec2 texelCoordM1 = clamp(texelCoord, ivec2(cc), ivec2(view) - cc); // Fixes screen edges
    for (int i = 0; i < 8; i++) {
        ivec2 texelCoordM2 = texelCoordM1 + neighbourhoodOffsets[i];

        float z0Check = texelFetch(depthtex0, texelCoordM2, 0).r;
        float z1Check = texelFetch(depthtex1, texelCoordM2, 0).r;
        if (max(abs(GetLinearDepth(z0Check) - GetLinearDepth(z0)), abs(GetLinearDepth(z1Check) - GetLinearDepth(z1))) > 0.09) {
            edge = regularEdge;

            if (int(texelFetch(colortex6, texelCoordM2, 0).g * 255.1) == 253) // Reduced Edge TAA
                edge *= extraEdgeMult;
        }

        vec3 clr = texelFetch(colortex3, texelCoordM2, 0).rgb;
        minclr = min(minclr, clr); maxclr = max(maxclr, clr);
    }

    tempColor = ClipAABB(tempColor, minclr, maxclr);
}

void DoTAA(inout vec3 color, inout vec3 temp, float z1) {
    int materialMask = int(texelFetch(colortex6, texelCoord, 0).g * 255.1);

    if (materialMask == 254) { // No SSAO, No TAA
        #ifndef CUSTOM_PBR
            if (z1 <= 0.56) return; // The edge pixel trick doesn't look nice on hand
        #endif
        int i = 0;
        while (i < 4) {
            int mms = int(texelFetch(colortex6, texelCoord + neighbourhoodOffsets[i], 0).g * 255.1);
            if (mms != materialMask) break;
            i++;
        } // Checking edge-pixels prevents flickering
        if (i == 4) return;
    }

    float z0 = texelFetch(depthtex0, texelCoord, 0).r;
    #ifndef TEMPORAL_FILTER
        z1 = texelFetch(depthtex1, texelCoord, 0).r;
    #endif

    #ifdef CUSTOM_PBR
        if (z1 <= 0.56) return; // materialMask might be occupied, so we do the check manually
    #endif

    vec3 coord = vec3(texCoord, z1);
    vec3 cameraOffset = cameraPosition - previousCameraPosition;
    vec2 prvCoord = Reprojection(coord, cameraOffset);

    vec3 tempColor = texture2D(colortex2, prvCoord).rgb;
    if (tempColor == vec3(0.0)) { // Fixes the first frame || Possibly fixes nans spreading around
        temp = color;
        return;
    }

    float edge = 0.0;
    NeighbourhoodClamping(color, tempColor, z0, z1, edge);

    if (materialMask == 253) // Reduced Edge TAA
        edge *= extraEdgeMult;

    #ifdef DISTANT_HORIZONS
        if (z0 == 1.0) {
            blendMinimum = 0.75;
            blendVariable = 0.05;
            blendConstant = 0.9;
            edge = 1.0;
        }
    #endif

    vec2 velocity = (texCoord - prvCoord.xy) * view;
    float blendFactor = float(prvCoord.x > 0.0 && prvCoord.x < 1.0 &&
                              prvCoord.y > 0.0 && prvCoord.y < 1.0);
    float velocityFactor = dot(velocity, velocity) * 10.0;
    blendFactor *= max(exp(-velocityFactor) * blendVariable + blendConstant - length(cameraOffset) * edge, blendMinimum);

    color = mix(color, tempColor, blendFactor);
    temp = color;

    //if (edge > 0.05) color.rgb = vec3(1.0, 0.0, 1.0);
}