#extension GL_ARB_gpu_shader5 : enable
#extension GL_ARB_shading_language_packing : enable

struct faceData {
	vec3 glColor;
	vec2 lightmap;
	vec3 textureBounds;

};

#if defined SHADOW && defined VERTEX_SHADER
	#define SSBO_QUALIFIER
#else
	#define SSBO_QUALIFIER readonly
#endif

#if WORLD_SPACE_PLAYER_REF == 1
	#include "/lib/voxelization/SSBOs/playerVerticesBuffer.glsl"
#endif

#include "/lib/voxelization/SSBOs/blockDataBuffer.glsl"
#include "/lib/voxelization/SSBOs/wsrLodBuffer.glsl"
#include "/lib/voxelization/SSBOs/wsrBuffer.glsl"

// Face index with no duplicates!
// Number of unique indecies 3abc + ab + bc + ca compared to 6abc, 
// (where a, b, and c refer to sceneVoxelVolumeSize.x, y, and z)
int getFaceIndex(ivec3 voxelPos, vec3 normal) {
	const int offsetY = (sceneVoxelVolumeSize.x + 1) * sceneVoxelVolumeSize.y * sceneVoxelVolumeSize.z;
	const int offsetZ = (sceneVoxelVolumeSize.y + 1) * sceneVoxelVolumeSize.x * sceneVoxelVolumeSize.z + offsetY;

	if (abs(normal.x) > 0.99)
		return max(int(normal.x), 0) + voxelPos.x + voxelPos.y * (sceneVoxelVolumeSize.x + 1) + 
							           			    voxelPos.z * (sceneVoxelVolumeSize.x + 1) * sceneVoxelVolumeSize.y;
	else if (abs(normal.y) > 0.99)
		return max(int(normal.y), 0) + voxelPos.y + voxelPos.x * (sceneVoxelVolumeSize.y + 1) + 
									   				voxelPos.z * (sceneVoxelVolumeSize.y + 1) * sceneVoxelVolumeSize.x + offsetY; 
	else
		return max(int(normal.z), 0) + voxelPos.z + voxelPos.x * (sceneVoxelVolumeSize.z + 1) + 
									   				voxelPos.y * (sceneVoxelVolumeSize.z + 1) * sceneVoxelVolumeSize.x + offsetZ;
}

uvec4 packFaceData(faceData data) {
	uvec3 uv = uvec3(clamp(data.textureBounds * 65536.0, 0.0, 65535.0));
	uvec2 lightmap = uvec2(clamp(data.lightmap * 65536.0, 0.0, 65535.0));
	return uvec4((uv.x << 16u) | uv.y, uv.z, packUnorm4x8(vec4(data.glColor, 0.0)), (lightmap.x << 16u) | lightmap.y);
}

faceData getFaceData(ivec3 voxelPos, vec3 normal) {
	uvec4 data = blockDataSSBO.data[getFaceIndex(voxelPos, normal)];
	return faceData(unpackUnorm4x8(data.z).xyz, 
					vec2(data.w >> 16u, data.w & 65535u) / 65536.0,
					vec3(data.x >> 16u, data.x & 65535u, data.y) / 65536.0);
}

bool checkLodVoxelAt(ivec3 lodVoxelPos) {
	uint voxelIndex = uint(lodVoxelPos.x + lodVoxelPos.y * sceneVoxelLodVolumeSize.x +
						   				   lodVoxelPos.z * sceneVoxelLodVolumeSize.x * sceneVoxelLodVolumeSize.y); 
	
	uint mask = 1u << (voxelIndex & 31u);
	return (wsrLodSSBO.bitmasks[voxelIndex >> 5] & mask) != 0;
}

bool checkVoxelAt(ivec3 voxelPos) {
	uint voxelIndex = uint(voxelPos.x + voxelPos.y * sceneVoxelVolumeSize.x +
						   				voxelPos.z * sceneVoxelVolumeSize.x * sceneVoxelVolumeSize.y); 
	
	uint mask = 1u << (voxelIndex & 31u);
	return (wsrSSBO.bitmasks[voxelIndex >> 5] & mask) != 0;
}

#if defined SHADOW && defined VERTEX_SHADER
void storeFaceData(ivec3 voxelPos, vec3 normal, vec2 origin, float textureRad, bool storeToAllFaces, bool storeToAllFacesExceptTop, vec3 playerPos) {
	vec2 lmCoordM = lmCoord;

	if (storeToAllFaces || storeToAllFacesExceptTop) {
		vec3 playerPosPrevious = playerPos - previousCameraPosition + cameraPosition;
		vec3 voxelPosPrevious = playerToPreviousSceneVoxel(playerPosPrevious);
		faceData oldFaceData = getFaceData(ivec3(voxelPosPrevious), normal);
		lmCoordM = mix(max(lmCoord, oldFaceData.lightmap), lmCoord, 0.01);
	}

	uvec4 newData = packFaceData(faceData(glColor.rgb, vec2(lmCoordM.x * 0.99 + 0.001, lmCoordM.y), vec3(origin, textureRad)));

	if (storeToAllFaces || storeToAllFacesExceptTop) {
		vec3 faceOffsets[6] = vec3[6](
			vec3( 0.0,  1.0,  0.0),
			vec3( 0.0,  0.0,  1.0),
			vec3( 1.0,  0.0,  0.0),
			vec3( 0.0,  0.0, -1.0),
			vec3( 0.0, -1.0,  0.0),
			vec3(-1.0,  0.0,  0.0)
		);

		int start = 0 + int(storeToAllFacesExceptTop);
		for(int i = start; i < 6; i++) {
			if (!checkVoxelAt(ivec3(voxelPos + faceOffsets[i])))
				blockDataSSBO.data[getFaceIndex(voxelPos, faceOffsets[i])] = newData;
		}
	} else {
		blockDataSSBO.data[getFaceIndex(voxelPos, normal)] = newData;
	}
}

void updateWsrLodBitmask(ivec3 lodVoxelPos) {
	uint voxelIndex = uint(lodVoxelPos.x + lodVoxelPos.y * sceneVoxelLodVolumeSize.x +
						   				   lodVoxelPos.z * sceneVoxelLodVolumeSize.x * sceneVoxelLodVolumeSize.y); 
										   
	atomicOr(wsrLodSSBO.bitmasks[voxelIndex >> 5], 1u << (voxelIndex & 31u));
}

void updateWsrBitmask(ivec3 voxelPos) {
	uint voxelIndex = uint(voxelPos.x + voxelPos.y * sceneVoxelVolumeSize.x +
						   				voxelPos.z * sceneVoxelVolumeSize.x * sceneVoxelVolumeSize.y); 
										   
	atomicOr(wsrSSBO.bitmasks[voxelIndex >> 5], 1u << (voxelIndex & 31u));
}
#endif