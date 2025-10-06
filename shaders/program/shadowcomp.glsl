/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Shadowcomp 1//////////Shadowcomp 1//////////Shadowcomp 1//////////
#ifdef SHADOWCOMP

#define OPTIMIZATION_ACT_BEHIND_PLAYER
#define OPTIMIZATION_ACT_HALF_RATE_SPREADING
//#define OPTIMIZATION_ACT_SHARED_MEMORY

layout (local_size_x = 8, local_size_y = 8, local_size_z = 8) in;
#if COLORED_LIGHTING_INTERNAL == 128
	const ivec3 workGroups = ivec3(16, 8, 16);
#elif COLORED_LIGHTING_INTERNAL == 192
	const ivec3 workGroups = ivec3(24, 12, 24);
#elif COLORED_LIGHTING_INTERNAL == 256
	const ivec3 workGroups = ivec3(32, 16, 32);
#elif COLORED_LIGHTING_INTERNAL == 384
	const ivec3 workGroups = ivec3(48, 24, 48);
#elif COLORED_LIGHTING_INTERNAL == 512
	const ivec3 workGroups = ivec3(64, 32, 64);
#elif COLORED_LIGHTING_INTERNAL == 768
	const ivec3 workGroups = ivec3(96, 32, 96);
#elif COLORED_LIGHTING_INTERNAL == 1024
	const ivec3 workGroups = ivec3(128, 32, 128);
#endif

#ifdef OPTIMIZATION_ACT_SHARED_MEMORY
	shared vec4 sharedLight[10][10][10];
#endif

//Common Variables//
writeonly uniform image3D floodfill_img;
writeonly uniform image3D floodfill_img_copy;

//Common Functions//
vec4 GetLightSample(sampler3D lightSampler, ivec3 pos) {
	#ifdef OPTIMIZATION_ACT_SHARED_MEMORY
		ivec3 localPos = pos - ivec3(gl_WorkGroupID) * ivec3(8); // Convert global pos to local shared pos
		if (all(greaterThanEqual(localPos, ivec3(0))) && all(lessThan(localPos, ivec3(8)))) {
			return sharedLight[localPos.x][localPos.y][localPos.z];
		} else {
			return texelFetch(lightSampler, pos, 0); // fallback to global fetch
		}
	#else
		return texelFetch(lightSampler, pos, 0);
	#endif
}

vec4 GetLightCalculated(sampler3D lightSampler, ivec3 pos, ivec3 voxelVolumeSize, uint voxel) {
	vec4 light_old = GetLightSample(lightSampler, pos);
	vec4 light_px  = GetLightSample(lightSampler, clamp(pos + ivec3( 1,  0,  0), ivec3(0), voxelVolumeSize - 1));
	vec4 light_py  = GetLightSample(lightSampler, clamp(pos + ivec3( 0,  1,  0), ivec3(0), voxelVolumeSize - 1));
	vec4 light_pz  = GetLightSample(lightSampler, clamp(pos + ivec3( 0,  0,  1), ivec3(0), voxelVolumeSize - 1));
	vec4 light_nx  = GetLightSample(lightSampler, clamp(pos + ivec3(-1,  0,  0), ivec3(0), voxelVolumeSize - 1));
	vec4 light_ny  = GetLightSample(lightSampler, clamp(pos + ivec3( 0, -1,  0), ivec3(0), voxelVolumeSize - 1));
	vec4 light_nz  = GetLightSample(lightSampler, clamp(pos + ivec3( 0,  0, -1), ivec3(0), voxelVolumeSize - 1));

	vec4 light = light_old + light_px + light_py + light_pz + light_nx + light_ny + light_nz;
    light /= 7.2; // Slightly higher than 7 to prevent the light from travelling too far

	if (voxel >= 200u) {
		vec3 tint = specialTintColor[min(voxel - 200u, specialTintColor.length() - 1u)];
		light.rgb *= tint;
		light.a *= dot(tint, vec3(0.333333));
	}

	return light;
}

//Includes//
#include "/lib/voxelization/lightVoxelization.glsl"

//Program//
void main() {
	ivec3 pos = ivec3(gl_GlobalInvocationID);
	vec3 posM = vec3(pos) / vec3(voxelVolumeSize);
	vec3 posOffset = floor(previousCameraPosition) - floor(cameraPosition);
	ivec3 previousPos = pos - ivec3(posOffset);
    ivec3 localPos = ivec3(gl_LocalInvocationID);

	#ifdef OPTIMIZATION_ACT_SHARED_MEMORY
		vec4 prevLight = vec4(0.0);
		if (int(framemod2) == 0)
			prevLight = texelFetch(floodfill_sampler, previousPos, 0);
		else
			prevLight = texelFetch(floodfill_sampler_copy, previousPos, 0);

		sharedLight[localPos.x][localPos.y][localPos.z] = prevLight;

		barrier();

		ivec3 alignedOffset = ivec3(posOffset) / 8 * 8;
		previousPos = pos - alignedOffset;
	#endif

	#ifdef OPTIMIZATION_ACT_BEHIND_PLAYER
		ivec3 absPosFromCenter = abs(pos - voxelVolumeSize / 2);
		if (absPosFromCenter.x + absPosFromCenter.y + absPosFromCenter.z > 16) {
			vec4 viewPos = gbufferProjectionInverse * vec4(0.0, 0.0, 1.0, 1.0);
			viewPos /= viewPos.w;
			vec3 nPlayerPos = normalize(mat3(gbufferModelViewInverse) * viewPos.xyz);
			if (dot(normalize(posM - 0.5), nPlayerPos) < 0.0) {
				#ifdef COLORED_LIGHT_FOG
					if (int(framemod2) == 0) {
						imageStore(floodfill_img_copy, pos, GetLightSample(floodfill_sampler, previousPos));
					} else {
						imageStore(floodfill_img, pos, GetLightSample(floodfill_sampler_copy, previousPos));
					}
				#endif
				return;
			}
		}
	#endif

	vec4 light = vec4(0.0);	
	uint voxel = GetVoxelVolume(pos);

	if (voxel == 1u) { // Solid Blocks
		light = vec4(0.0);
	} else if (voxel == 0u || voxel >= 200u) { // Air, Non-solids, Translucents
		if (int(framemod2) == 0) {
			#ifdef OPTIMIZATION_ACT_HALF_RATE_SPREADING
				if (posM.z > 0.5) light = GetLightSample(floodfill_sampler, previousPos);
				else
			#endif
			light = GetLightCalculated(floodfill_sampler, previousPos, voxelVolumeSize, voxel);
		} else {
			#ifdef OPTIMIZATION_ACT_HALF_RATE_SPREADING
				if (posM.z < 0.5) light = GetLightSample(floodfill_sampler_copy, previousPos);
				else
			#endif
			light = GetLightCalculated(floodfill_sampler_copy, previousPos, voxelVolumeSize, voxel);
		}
	} else { // Light Sources
		vec4 color = GetSpecialBlocklightColor(int(voxel));
		light = max(light, vec4(pow2(color.rgb), color.a));
	}

	if (int(framemod2) == 0) {
		imageStore(floodfill_img_copy, pos, light);
	} else {
		imageStore(floodfill_img, pos, light);
	}
}

#endif