#extension GL_ARB_shader_storage_buffer_object : enable

layout(std430, binding = 1) SSBO_QUALIFIER buffer wsrBuffer {
	uint bitmasks[];
} wsrSSBO;  