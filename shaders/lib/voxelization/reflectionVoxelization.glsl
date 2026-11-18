#if COLORED_LIGHTING < 512
    const ivec3 sceneVoxelVolumeSize = ivec3(COLORED_LIGHTING_INTERNAL, 64, COLORED_LIGHTING_INTERNAL);
#else
    const ivec3 sceneVoxelVolumeSize = ivec3(512, 64, 512);
#endif

const ivec3 sceneVoxelLodVolumeSize = sceneVoxelVolumeSize / 4;

vec3 playerToSceneVoxel(vec3 playerPos) {
    return playerPos + cameraPositionBestFract + 0.5 * vec3(sceneVoxelVolumeSize);
}

vec3 playerToPreviousSceneVoxel(vec3 previousPlayerPos) {
    return previousPlayerPos + previousCameraPositionBestFract + 0.5 * vec3(sceneVoxelVolumeSize);
}

bool CheckInsideSceneVoxelVolume(vec3 voxelPos) {
    voxelPos /= vec3(sceneVoxelVolumeSize);
    return clamp01(voxelPos) == voxelPos;
}

bool CheckInsideLodVoxelVolume(vec3 voxelPos) {
    voxelPos /= vec3(sceneVoxelVolumeSize / 4);
    return clamp01(voxelPos) == voxelPos;
}

#include "/lib/voxelization/reflectionVoxelData.glsl"

#if defined SHADOW && defined VERTEX_SHADER
    void UpdateSceneVoxelMap(int mat, vec3 normal, vec3 position) {
        vec3 viewPos  = mat3(gl_ModelViewMatrix) * (gl_Vertex.xyz + at_midBlock.xyz / 64.0) + gl_ModelViewMatrix[3].xyz;
        vec3 scenePos = mat3(shadowModelViewInverse) * viewPos + shadowModelViewInverse[3].xyz;
        vec3 voxelPos = playerToSceneVoxel(scenePos);

        if (CheckInsideSceneVoxelVolume(voxelPos)) {
            bool doSolidBlockCheck = true;
            bool storeToAllFaces = false;
            bool storeToAllFacesExceptTop = false;
            uint matM = mat > 10 ? uint(mat) : 1u;
            vec2 textureRad = abs(texCoord - mc_midTexCoord.xy);
            vec2 origin = mc_midTexCoord.xy - textureRad;

            #include "/lib/voxelization/voxelHandling.glsl"

            if (doSolidBlockCheck) {
                if (
                    mat % 2 == 1 // Non-solids
                    || abs(mat - 5000) <= 4999 // Block entities that we treat as non-solid
                )
                return;
            }

            imageStore(wsr_img, ivec3(voxelPos), uvec4(matM, 0u, 0u, 0u));
            imageStore(wsr_lod_img, ivec3(voxelPos) / 4, uvec4(1u, 0u, 0u, 0u));
            storeFaceData(ivec3(voxelPos), round(normal), origin, textureRad.x, storeToAllFaces, storeToAllFacesExceptTop, scenePos);
        }
    }

    #if WORLD_SPACE_PLAYER_REF == 1
        uniform writeonly image2D playerAtlas_img;

        #define updateAABB(aabb_min, aabb_max, pos) \
                      atomicMin(aabb_min.x, pos.x); \
                      atomicMin(aabb_min.y, pos.y); \
                      atomicMin(aabb_min.z, pos.z); \
                      atomicMax(aabb_max.x, pos.x); \
                      atomicMax(aabb_max.y, pos.y); \
                      atomicMax(aabb_max.z, pos.z);


        void UpdatePlayerVertexList(vec3 position) {
            int localVertexID = gl_VertexID % 288;
            // This fixes the whole system being broken on MC 26.2 and above due to the batching system.
            // Don't ask me how it even works, I don't know either. I just tried doing modulo by player vertex count

            if (entityId == 50017 && textureSize(tex, 0) == ivec2(64)) { // Current Player

                // The atlas takes 4 frames to fully generate, reload every 600 frames
                if (framemod600 > 5 && framemod600 <= 9 && localVertexID < 256) {
                    int i = localVertexID * 4 + int(framemod4) * 1024;
                    for (int j = 0; j < 4; j++) {
                        ivec2 coord = ivec2((i + j) % 64, (i + j) / 64);
                        imageStore(playerAtlas_img, coord, texelFetch(tex, coord, 0));
                    }
                }

                position -= 0.2 * playerLookVector;

                ivec3 aabbPos = ivec3(position * 1000.0);

                if (localVertexID < 48) { // Head
                    updateAABB(playerVerticesSSBO.headMin, playerVerticesSSBO.headMax, aabbPos);
                } else if (localVertexID < 96) { // Right Hand
                    updateAABB(playerVerticesSSBO.rightHandMin, playerVerticesSSBO.rightHandMax, aabbPos);
                } else if (localVertexID < 144) { // Left Leg
                    updateAABB(playerVerticesSSBO.leftLegMin, playerVerticesSSBO.leftLegMax, aabbPos);
                } else if (localVertexID < 192) { // Left Hand
                    updateAABB(playerVerticesSSBO.leftHandMin, playerVerticesSSBO.leftHandMax, aabbPos);
                } else if (localVertexID < 240) { // Right leg
                    updateAABB(playerVerticesSSBO.rightLegMin, playerVerticesSSBO.rightLegMax, aabbPos);
                } else { // Torso
                    updateAABB(playerVerticesSSBO.torsoMin, playerVerticesSSBO.torsoMax, aabbPos);
                }

                if (localVertexID % 4 != 3) {
                    int ssboIndex = localVertexID - localVertexID / 4;
                    playerVerticesSSBO.vertexPositions[ssboIndex] = position;
                    playerVerticesSSBO.vertexData[ssboIndex] = texCoord;
                }
            }
        }
    #endif
#endif
