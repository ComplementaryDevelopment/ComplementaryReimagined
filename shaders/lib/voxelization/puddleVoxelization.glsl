const ivec3 puddle_voxelVolumeSize = ivec3(128);

vec3 TransformMat(mat4 m, vec3 pos) {
    return mat3(m) * pos + m[3].xyz;
}

vec3 SceneToPuddleVoxel(vec3 scenePos) {
	return scenePos + fract(cameraPosition) + (0.5 * vec3(puddle_voxelVolumeSize));
}

bool CheckInsidePuddleVoxelVolume(vec3 voxelPos) {
    #ifndef SHADOW
        voxelPos -= puddle_voxelVolumeSize / 2;
        voxelPos += sign(voxelPos) * 0.95;
        voxelPos += puddle_voxelVolumeSize / 2;
    #endif
    voxelPos /= vec3(puddle_voxelVolumeSize);
	return clamp01(voxelPos) == voxelPos;
}

#if defined SHADOW && defined VERTEX_SHADER
    void UpdatePuddleVoxelMap(int mat) {
        if (renderStage != MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) return;
        if (mat == 32000) return; // Water

        vec3 model_pos = gl_Vertex.xyz + at_midBlock.xyz / 64.0;
        vec3 view_pos  = TransformMat(gl_ModelViewMatrix, model_pos);
        vec3 scenePos = TransformMat(shadowModelViewInverse, view_pos);
        vec3 voxelPos = SceneToPuddleVoxel(scenePos);

        if (CheckInsidePuddleVoxelVolume(voxelPos))
            if (scenePos.y >= -3.5)
            imageStore(puddle_img, ivec2(voxelPos.xz), uvec4(10u, 0u, 0u, 0u));
    }
#endif