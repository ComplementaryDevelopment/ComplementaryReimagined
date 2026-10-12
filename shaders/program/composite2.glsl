/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

//Pipeline Constants//
#if defined TAAU && WORLD_BLUR == 2 && WB_DOF_FOCUS == 0
    /*
    const int colortex9Format = R32F; // Half-float depth loses precision at long distances
    */
    const bool colortex9Clear = false;
#endif

//Common Variables//
#if defined TAAU && WORLD_BLUR == 2 && WB_DOF_FOCUS == 0
    uniform sampler2D colortex9;
#endif

//Common Functions//

//Includes//
#if defined TAAU && WORLD_BLUR == 2 && WB_DOF_FOCUS == 0
    #include "/lib/antialiasing/jitter.glsl"
#endif

//Program//
void main() {
    #if defined TAAU && WORLD_BLUR == 2 && WB_DOF_FOCUS == 0
        vec2 center = TAAJitter(vec2(0.5), 0.5);
        ivec2 centerTexel = clamp(ivec2(center * scaledViewSizeF), ivec2(0), scaledViewSize - 1);
        float currentDepth = texelFetch(depthtex1, centerTexel, 0).r;
        float previousDepth = texelFetch(colortex9, ivec2(0), 0).r;
        if (previousDepth <= 0.0 || previousDepth > 1.0 || isnan(previousDepth)) previousDepth = currentDepth;

        // Same smoothing as centerDepthSmooth
        float focusDepth = mix(previousDepth, currentDepth, 1.0 - exp2(-10.0 * frameTime));

        /* DRAWBUFFERS:9 */
        gl_FragData[0] = vec4(focusDepth, 0.0, 0.0, 1.0);
    #else
        discard;
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();
}

#endif
