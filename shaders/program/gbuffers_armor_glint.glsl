//////////////////////////////////
// Complementary Base by EminGT //
//////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;

flat in vec4 glColor;

//Uniforms//
uniform sampler2D tex;

//Pipeline Constants//

//Common Variables//

//Common Functions//

//Includes//
#ifdef COLOR_CODED_PROGRAMS
	#include "/lib/misc/colorCodedPrograms.glsl"
#endif

//Program//
void main() {
	vec4 color = texture2D(tex, texCoord);
	color *= glColor;

	#ifdef COLOR_CODED_PROGRAMS
		ColorCodeProgram(color);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;

flat out vec4 glColor;

//Uniforms//
#if HAND_SWAYING > 0
	uniform float frameTimeCounter;
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

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
}

#endif
