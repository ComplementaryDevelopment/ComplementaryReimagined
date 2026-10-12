/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

// Resolve TAA/U in HDR and write its history here
// DoF, motion blur, bloom and tonemapping run later

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

//Pipeline Constants//
#include "/lib/pipelineSettings.glsl"

vec2 view = vec2(viewWidth, viewHeight);

#ifdef TAA
    #include "/lib/antialiasing/temporalCommon.glsl"
    #ifdef TAAU
        #include "/lib/antialiasing/jitter.glsl"
        #include "/lib/antialiasing/taau.glsl"
    #else
        #include "/lib/antialiasing/taa.glsl"
    #endif
#endif

void main() {
    #ifdef TAAU
        vec4 history = DoTAAU();
        vec3 color = TAADecode(history.rgb);
    #else
        vec3 color = texelFetch(colortex0, texelCoord, 0).rgb;
        #ifdef TAA
            color = TAAEncode(color);
            vec3 temp = vec3(0.0);
            float z1 = texelFetch(depthtex1, texelCoord, 0).r;
            DoTAA(color, temp, z1);
            vec4 history = vec4(temp, 1.0);
            color = TAADecode(color);
        #endif
    #endif

    #ifdef TAA
        /* DRAWBUFFERS:02 */
        gl_FragData[1] = history;
    #else
        /* DRAWBUFFERS:0 */
    #endif
    gl_FragData[0] = vec4(color, 1.0);
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif
