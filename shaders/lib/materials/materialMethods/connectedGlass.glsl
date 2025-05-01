ivec3[6] glassOffsets = ivec3[](
    ivec3( 1, 0, 0),
    ivec3(-1, 0, 0),
    ivec3( 0, 1, 0),
    ivec3( 0,-1, 0),
    ivec3( 0, 0, 1),
    ivec3( 0, 0,-1)
);

ivec3[12] glassCornerOffsets = ivec3[](
    ivec3( 1, 1, 0),
    ivec3( 1,-1, 0),
    ivec3(-1, 1, 0),
    ivec3(-1,-1, 0),
    ivec3( 0, 1, 1),
    ivec3( 0, 1,-1),
    ivec3( 0,-1, 1),
    ivec3( 0,-1,-1),
    ivec3( 1, 0, 1),
    ivec3( 1, 0,-1),
    ivec3(-1, 0, 1),
    ivec3(-1, 0,-1)
);

vec2 GetModifiedMidCoord() {
    float epsilon1 = 0.00001;
    vec2 midCoord = texCoord - signMidCoordPos * absMidCoordPos;
    return midCoord - epsilon1;
}

void DoSimpleConnectedGlass(inout vec4 color) {
    color = texture2DLod(tex, GetModifiedMidCoord(), 0);
}

#ifdef GBUFFERS_WATER
    void DoConnectedGlass(inout vec4 colorP, inout vec4 color, inout bool noGeneratedNormals, vec3 playerPos, vec3 worldGeoNormal, uint voxelID, bool isPane) {
        vec3 worldGeoNormalM = vec3( // Fixes Iris 1.8 normal precision issues causing the coordinates to be imperfect
            round(worldGeoNormal.x),
            round(worldGeoNormal.y),
            round(worldGeoNormal.z)
        );
        vec3 playerPosM = playerPos - worldGeoNormalM * 0.25;
        vec3 voxelPos = SceneToVoxel(playerPosM);

        if (CheckInsideVoxelVolume(voxelPos)) {
            #if IRIS_VERSION >= 10800
                float epsilon2 = 0.0;
            #else
                float epsilon2 = 0.001;
            #endif
            float pixelOffset = 0.5 / (absMidCoordPos.y * atlasSize.y);
            float pixelOffsetPlus = pixelOffset + epsilon2;
            float pixelOffsetMinus = pixelOffset - epsilon2;
            
            colorP = texture2DLod(tex, texCoord, 0);
            vec4 colorPvanilla = colorP;

            vec2 midCoordM = GetModifiedMidCoord();
            vec3 worldPos = playerPosM + cameraPositionBestFract;
            vec3 floorWorldPos = floor(worldPos);

            // Remove edges
            for (int i = 0; i < 6; i++) {
                uint voxel = texelFetch(voxel_sampler, ivec3(voxelPos) + glassOffsets[i], 0).r;
                if (voxel == voxelID) {
                    if (floor(worldPos + glassOffsets[i] * pixelOffsetPlus) != floorWorldPos) {
                        colorP = texture2DLod(tex, midCoordM, 0);
                    }
                    #ifdef GENERATED_NORMALS
                        if (floor(worldPos + glassOffsets[i] * pixelOffsetPlus * 1.25) != floorWorldPos) {
                            noGeneratedNormals = true;
                        }
                    #endif
                }
            }

            // Fixes the connections by restoring the edges that aren't connected
            for (int i = 0; i < 6; i++) {
                uint voxel = texelFetch(voxel_sampler, ivec3(voxelPos) + glassOffsets[i], 0).r;
                if (voxel != voxelID) {
                    //if (floor(worldPos + glassOffsets[i] * 0.0625) != floorWorldPos) {
                    if (floor(worldPos + glassOffsets[i] * pixelOffsetMinus) != floorWorldPos) {
                        colorP = colorPvanilla;
                    }
                }
            }

            if (isPane) {
                // Fixes lines between layers of glass panes
                if (NdotU > 0.9) {
                    uint voxel = texelFetch(voxel_sampler, ivec3(voxelPos) + ivec3(0, 1, 0), 0).r;
                    if (voxel == voxelID) discard;
                }
                if (NdotU < -0.9) {
                    uint voxel = texelFetch(voxel_sampler, ivec3(voxelPos) - ivec3(0, 1, 0), 0).r;
                    if (voxel == voxelID) discard;
                }
            }
            
            #ifdef CONNECTED_GLASS_CORNER_FIX
                // Restores corners
                for (int i = 0; i < 12; i++) {
                    uint voxel = texelFetch(voxel_sampler, ivec3(voxelPos) + glassCornerOffsets[i], 0).r;
                    if ((voxel != voxelID) && (!isPane || voxel > 0u)) {
                        if (floor((worldPos - glassCornerOffsets[i] * (1.0 - pixelOffsetMinus))) == floorWorldPos) {
                            colorP = colorPvanilla;
                        }
                    }
                }
            #endif
        
            color = colorP * vec4(glColor.rgb, 1.0);
        }
    }
#endif
