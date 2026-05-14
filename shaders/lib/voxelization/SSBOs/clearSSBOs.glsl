#define SSBO_QUALIFIER

#include "/lib/voxelization/SSBOs/playerVerticesBuffer.glsl"

void clearSSBOs() {
    if (gl_FragCoord.x + gl_FragCoord.y < 1.5) {
        playerVerticesSSBO.bounds = playerBounds(ivec3(1e6), ivec3(-1e6), ivec3(1e6), ivec3(-1e6), 
                                                 ivec3(1e6), ivec3(-1e6), ivec3(1e6), ivec3(-1e6), 
                                                 ivec3(1e6), ivec3(-1e6), ivec3(1e6), ivec3(-1e6));
    }
}