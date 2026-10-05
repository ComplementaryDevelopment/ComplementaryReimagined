//////////////////////////////////
// Complementary Base by EminGT //
//////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;

flat in vec4 glColor;

//Pipeline Constants//

//Common Variables//

//Common Functions//

//Includes//
#ifdef COLOR_CODED_PROGRAMS
    #include "/lib/misc/colorCodedPrograms.glsl"
#endif

//Program//
void main() {
    RenderScaleSkipOutside();

    vec4 color = texture2DMaterial(tex, texCoord);
    color *= glColor;

    color.rgb *= glColor.a; // Needed for Minecraft's "Glint Strength" apparently

    #ifdef COLOR_CODED_PROGRAMS
        ColorCodeProgram(color, -1);
    #endif

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;

flat out vec4 glColor;

//Attributes//

//Common Variables//

//Common Functions//

//Includes//
#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif

//Program//
void main() {
    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    glColor = gl_Color;

    #if HAND_SWAYING > 0
        if (gl_ProjectionMatrix[2][2] > -0.5) {
            #include "/lib/misc/handSway.glsl"
        }
    #endif

    #ifdef TAA
        if (RENDER_SCALE_M < 1.0) gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    #endif

    DoRenderScale(gl_Position);
}

#endif
