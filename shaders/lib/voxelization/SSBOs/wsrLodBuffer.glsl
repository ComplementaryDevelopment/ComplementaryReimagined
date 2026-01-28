#extension GL_ARB_shader_storage_buffer_object : enable

layout(std430, binding = 2) SSBO_QUALIFIER buffer wsrLodBuffer {
	uint bitmasks[];
} wsrLodSSBO;  