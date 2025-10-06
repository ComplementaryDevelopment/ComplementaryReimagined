#extension GL_ARB_shader_storage_buffer_object : enable

// Structs
struct vec6 {
    vec3 a;
    vec3 b;
};

struct faceData {
	vec3 textureBounds;
	vec3 glColor;
	vec2 lightmap;
};

struct blockData {
    vec4[6] packedFaceData;
};
//

#if defined SHADOW && defined VERTEX_SHADER || defined CLEAR_SSBO
layout(std430, binding = 0) buffer blockDataSSBO {
    blockData data[];
};  
#else
layout(std430, binding = 0) readonly buffer blockDataSSBO {
    blockData data[];
};  
#endif

int getSSBOIndex(ivec3 voxelPos) {
    return voxelPos.x + voxelPos.y * sceneVoxelVolumeSize.x + voxelPos.z * sceneVoxelVolumeSize.x * sceneVoxelVolumeSize.y;
}

int getFaceIndex(vec3 normal) {
    return int(2.0 * abs(normal.y) + 4.0 * abs(normal.z) + (normal.x + normal.y + normal.z) * 0.5 + 0.5);
}

// the packing / unpacking assumes normalized floats
float pack2x16(float a, float b) {
	a = clamp(a, 0.0, 0.99);
	b = clamp(b, 0.0, 0.99);
	uint low = uint(a * 65535.0);
	uint high = uint(b * 65535.0);
	return (low | (high << 16)) / 4294967295.0;
}

vec3 pack2x16(vec3 a, vec3 b) {
	a = clamp(a, 0.0, 0.99);
	b = clamp(b, 0.0, 0.99);
	uvec3 low = uvec3(a * 65535.0);
	uvec3 high = uvec3(b * 65535.0);
	return (low | (high << 16)) / 4294967295.0;
}

vec2 unpack2x16(float val) {
	uint temp = uint(val * 4294967295.0);
	return vec2(float(temp & 65535u), (temp >> 16u)) / 65535.0;
}

vec6 unpack2x16(vec3 val) {
	uvec3 temp = uvec3(val * 4294967295.0);
	return vec6(vec3(temp & 65535u) / 65535.0, (temp >> 16u) / 65535.0);
}

faceData getFaceData(ivec3 voxelPos, vec3 normal) {
	vec4 packedData = data[getSSBOIndex(voxelPos)].packedFaceData[getFaceIndex(normal)];
	vec6 attribUnpacked = unpack2x16(packedData.rgb);
	vec2 lightmap = unpack2x16(packedData.a);
	return faceData(attribUnpacked.a, attribUnpacked.b, lightmap);
}

float getFacePriority(ivec3 voxelPos, int faceIndex) {
	vec4 packedData = data[getSSBOIndex(voxelPos)].packedFaceData[faceIndex];
	vec2 priorityAndSkylight = unpack2x16(packedData.a);
	return priorityAndSkylight.x;
}

#if defined SHADOW && defined VERTEX_SHADER
void storeFaceData(ivec3 voxelPos, vec3 normal, vec2 origin, float textureRad, bool storeToAllFaces, bool storeToAllFacesExceptTop, vec3 playerPos) {
	vec3 attrib = vec3(pack2x16(vec3(origin, textureRad), glColor.rgb));
	vec2 lmCoordM = lmCoord;

	if (storeToAllFaces || storeToAllFacesExceptTop) {
		vec3 playerPosPrevious = playerPos - previousCameraPosition + cameraPosition;
		vec3 voxelPosPrevious = playerToPreviousSceneVoxel(playerPosPrevious);
		faceData oldFaceData = getFaceData(ivec3(voxelPosPrevious), normal);
		lmCoordM = mix(max(lmCoord, oldFaceData.lightmap), lmCoord, 0.01);
	}

	float light = pack2x16(lmCoordM.x * 0.99 + 0.001, lmCoordM.y);
	vec4 newData = vec4(attrib, light);

	if (storeToAllFaces) {
		data[getSSBOIndex(voxelPos)].packedFaceData = vec4[](newData, newData, newData, newData, newData, newData);
	} else if (storeToAllFacesExceptTop) {
		data[getSSBOIndex(voxelPos)].packedFaceData[0] = newData;
		data[getSSBOIndex(voxelPos)].packedFaceData[1] = newData;
		data[getSSBOIndex(voxelPos)].packedFaceData[2] = newData;
		data[getSSBOIndex(voxelPos)].packedFaceData[4] = newData;
		data[getSSBOIndex(voxelPos)].packedFaceData[5] = newData;
 	} else {
		data[getSSBOIndex(voxelPos)].packedFaceData[getFaceIndex(normal)] = newData;
	}
}
#endif