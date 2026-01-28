#extension GL_ARB_shader_storage_buffer_object : enable

struct playerBounds {
    ivec3 headMin, headMax;
	ivec3 torsoMin, torsoMax;
	ivec3 leftLegMin, leftLegMax;
	ivec3 rightLegMin, rightLegMax;
	ivec3 leftHandMin, leftHandMax;
	ivec3 rightHandMin, rightHandMax;
};

layout(std430, binding = 3) SSBO_QUALIFIER buffer playerVerticesBuffer {
	vec3 vertexPositions[216];
    vec2 vertexData[216];
	playerBounds bounds;
} playerVerticesSSBO;  