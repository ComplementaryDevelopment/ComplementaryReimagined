/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;

in vec4 glColor;

//Pipeline Constants//

//Common Variables//

//Common Functions//

//Includes//
#ifdef COLOR_CODED_PROGRAMS
    #include "/lib/misc/colorCodedPrograms.glsl"
#endif

//Program//
void main() {
    vec4 color = texture2D(tex, texCoord) * glColor;

    color.rgb = pow1_5(color.rgb) * (
        1.5
        + vec3(4.1, 3.0, 4.1) * max0(color.r * color.b - color.g) // Tweak for Enderman
        + 5.0 * max0(color.g * color.b - color.r) // Tweak for Warden
        - 0.5 * sqrt(color.r * color.g * color.b) // Tweak for Breeze
        - vec3(0.0, 0.7, 0.7) * max0(color.r * color.g - color.b) // Tweak for Copper Golem
    );

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

out vec4 glColor;

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    glColor = gl_Color;
}

#endif
