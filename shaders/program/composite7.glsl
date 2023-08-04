////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

//Uniforms//
uniform float viewWidth, viewHeight;

#ifndef LIGHT_COLORING
    uniform sampler2D colortex3;
#else
    uniform sampler2D colortex8;
#endif

//Pipeline Constants//

//Common Variables//

//Common Functions//

//Includes//
#ifdef FXAA
	#include "/lib/antialiasing/fxaa.glsl"
#endif

//Program//
void main() {
    #ifndef LIGHT_COLORING
        vec3 color = texelFetch(colortex3, texelCoord, 0).rgb;
    #else
        vec3 color = texelFetch(colortex8, texelCoord, 0).rgb;
    #endif

	#ifdef FXAA
		FXAA311(color);
	#endif

    #ifndef LIGHT_COLORING
    /* DRAWBUFFERS:3 */
    #else
    /* DRAWBUFFERS:8 */
    #endif
	gl_FragData[0] = vec4(color, 1.0);
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

//Uniforms//

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	gl_Position = ftransform();

	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif
