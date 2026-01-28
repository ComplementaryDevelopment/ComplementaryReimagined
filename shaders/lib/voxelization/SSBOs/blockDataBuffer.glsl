#extension GL_ARB_shader_storage_buffer_object : enable

layout(std430, binding = 0) SSBO_QUALIFIER buffer blockDataBuffer {
    uvec4 data[];
} blockDataSSBO;  