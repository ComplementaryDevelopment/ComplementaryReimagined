/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Shadowcomp 1//////////Shadowcomp 1//////////Shadowcomp 1//////////
#ifdef SHADOWCOMP

#define OPTIMIZATION_ACL_HALF_RATE_UPDATES
#define OPTIMIZATION_ACL_BEHIND_PLAYER

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
#endif

//Common Variables//
ivec3[6] face_offsets = ivec3[6](
	ivec3( 1,  0,  0),
	ivec3( 0,  1,  0),
	ivec3( 0,  0,  1),
	ivec3(-1,  0,  0),
	ivec3( 0, -1,  0),
	ivec3( 0,  0, -1)
);

writeonly uniform image3D floodfill_img;
writeonly uniform image3D floodfill_img_copy;

//Common Functions//
vec4 GetLightSample(sampler3D lightSampler, ivec3 pos) {
	return texelFetch(lightSampler, pos, 0);
}

vec4 GetLightAverage(sampler3D lightSampler, ivec3 pos, ivec3 voxelVolumeSize) {
	vec4 light_old = GetLightSample(lightSampler, pos);
	vec4 light_px  = GetLightSample(lightSampler, clamp(pos + face_offsets[0], ivec3(0), voxelVolumeSize - 1));
	vec4 light_py  = GetLightSample(lightSampler, clamp(pos + face_offsets[1], ivec3(0), voxelVolumeSize - 1));
	vec4 light_pz  = GetLightSample(lightSampler, clamp(pos + face_offsets[2], ivec3(0), voxelVolumeSize - 1));
	vec4 light_nx  = GetLightSample(lightSampler, clamp(pos + face_offsets[3], ivec3(0), voxelVolumeSize - 1));
	vec4 light_ny  = GetLightSample(lightSampler, clamp(pos + face_offsets[4], ivec3(0), voxelVolumeSize - 1));
	vec4 light_nz  = GetLightSample(lightSampler, clamp(pos + face_offsets[5], ivec3(0), voxelVolumeSize - 1));

	vec4 light = light_old + light_px + light_py + light_pz + light_nx + light_ny + light_nz;
    return light / 7.2; // Slightly higher than 7 to prevent the light from travelling too far
}

//Includes//
#include "/lib/misc/voxelization.glsl"

//Program//
void main() {
	ivec3 pos = ivec3(gl_GlobalInvocationID);
	vec3 posM = vec3(pos) / vec3(voxelVolumeSize);
	vec3 posOffset = floor(previousCameraPosition) - floor(cameraPosition);
	ivec3 previousPos = ivec3(vec3(pos) - posOffset);

	ivec3 absPosFromCenter = abs(pos - voxelVolumeSize / 2);
	if (absPosFromCenter.x + absPosFromCenter.y + absPosFromCenter.z > 16) {
	#ifdef OPTIMIZATION_ACL_BEHIND_PLAYER
		vec4 viewPos = gbufferProjectionInverse * vec4(0.0, 0.0, 1.0, 1.0);
		viewPos /= viewPos.w;
		vec3 nPlayerPos = normalize(mat3(gbufferModelViewInverse) * viewPos.xyz);
		if (dot(normalize(posM - 0.5), nPlayerPos) < 0.0) {
			#ifdef COLORED_LIGHT_FOG
				if ((frameCounter & 1) == 0) {
					imageStore(floodfill_img_copy, pos, GetLightSample(floodfill_sampler, previousPos));
				} else {
					imageStore(floodfill_img, pos, GetLightSample(floodfill_sampler_copy, previousPos));
				}
			#endif
			return;
		}
	#endif
	}

	vec4 light = vec4(0.0);
	uint voxel = texelFetch(voxel_sampler, pos, 0).x;

	if ((frameCounter & 1) == 0) {
		if (voxel == 1u) {
			imageStore(floodfill_img_copy, pos, vec4(0.0));
			return;
		}
		#ifdef OPTIMIZATION_ACL_HALF_RATE_UPDATES
			if (posM.x < 0.5) {
				imageStore(floodfill_img_copy, pos, GetLightSample(floodfill_sampler, previousPos));
				return;
			}
		#endif
		light = GetLightAverage(floodfill_sampler, previousPos, voxelVolumeSize);
	} else {
		if (voxel == 1u) {
			imageStore(floodfill_img, pos, vec4(0.0));
			return;
		}
		#ifdef OPTIMIZATION_ACL_HALF_RATE_UPDATES
			if (posM.x > 0.5) {
				imageStore(floodfill_img, pos, GetLightSample(floodfill_sampler_copy, previousPos));
				return;
			}
		#endif
		light = GetLightAverage(floodfill_sampler_copy, previousPos, voxelVolumeSize);
	}

	if (voxel == 0u || voxel >= 200u) {
		if (voxel >= 200u) {
			vec3 tint = specialTintColor[min(voxel - 200u, specialTintColor.length() - 1u)];
			light.rgb *= tint;
		}
	} else {
		vec4 color = GetSpecialBlocklightColor(int(voxel));
		light = max(light, vec4(pow2(color.rgb), color.a));
	}

	if ((frameCounter & 1) == 0) {
		imageStore(floodfill_img_copy, pos, light);
	} else {
		imageStore(floodfill_img, pos, light);
	}
}

#endif