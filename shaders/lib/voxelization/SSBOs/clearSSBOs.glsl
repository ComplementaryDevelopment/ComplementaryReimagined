#define SSBO_QUALIFIER

#include "/lib/voxelization/SSBOs/playerVerticesBuffer.glsl"

void clearSSBOs() {
    if (gl_FragCoord.x + gl_FragCoord.y < 1.5) {
        playerVerticesSSBO.headMin = ivec3(1e6);
        playerVerticesSSBO.headMax = ivec3(-1e6);
        playerVerticesSSBO.torsoMin = ivec3(1e6);
        playerVerticesSSBO.torsoMax = ivec3(-1e6);
        playerVerticesSSBO.leftLegMin = ivec3(1e6);
        playerVerticesSSBO.leftLegMax = ivec3(-1e6);
        playerVerticesSSBO.rightLegMin = ivec3(1e6);
        playerVerticesSSBO.rightLegMax = ivec3(-1e6);
        playerVerticesSSBO.leftHandMin = ivec3(1e6);
        playerVerticesSSBO.leftHandMax = ivec3(-1e6);
        playerVerticesSSBO.rightHandMin = ivec3(1e6);
        playerVerticesSSBO.rightHandMax = ivec3(-1e6);
    }
}
