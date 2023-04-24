////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;

in vec4 glColor;

//Uniforms//
uniform sampler2D tex;

//Pipeline Constants//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	vec4 color = texture2D(tex, texCoord) * glColor;

	#ifdef IPBR
		if (CheckForColor(color.rgb, vec3(224, 121, 250))) { // Enderman Eye Edges
			color.rgb = vec3(0.8, 0.25, 0.8);
		}
	#endif

	color.rgb = pow1_5(color.rgb);
	color.rgb *= pow2(1.0 + color.b + 0.5 * color.g) * 1.5;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;

out vec4 glColor;

//Uniforms//

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
