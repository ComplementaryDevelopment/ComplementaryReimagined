#define SSBO_QUALIFIER

#if WORLD_SPACE_PLAYER_REF == 1
    #include "/lib/voxelization/SSBOs/playerVerticesBuffer.glsl"
#endif

#include "/lib/voxelization/SSBOs/wsrBuffer.glsl"
#include "/lib/voxelization/SSBOs/wsrLodBuffer.glsl"

#if COLORED_LIGHTING < 512
    const ivec3 sceneVoxelVolumeSize = ivec3(COLORED_LIGHTING_INTERNAL, 64, COLORED_LIGHTING_INTERNAL);
#else
    const ivec3 sceneVoxelVolumeSize = ivec3(512, 64, 512);
#endif

void clearSSBOs() {
    int pixelIndex = int(gl_FragCoord.x) + int(viewWidth) * int(gl_FragCoord.y);

    int k = sceneVoxelVolumeSize.x * sceneVoxelVolumeSize.y * sceneVoxelVolumeSize.z / 32;
    if (pixelIndex < k) {
        if (pixelIndex < k / 64)
            wsrLodSSBO.bitmasks[pixelIndex] = 0u;

        wsrSSBO.bitmasks[pixelIndex] = 0u;
    }

    #if WORLD_SPACE_PLAYER_REF == 1
        if (pixelIndex == 0) {
            playerVerticesSSBO.bounds = playerBounds(ivec3(1e6), ivec3(-1e6), ivec3(1e6), ivec3(-1e6), 
                                                     ivec3(1e6), ivec3(-1e6), ivec3(1e6), ivec3(-1e6), 
                                                     ivec3(1e6), ivec3(-1e6), ivec3(1e6), ivec3(-1e6));
        }
    #endif
}