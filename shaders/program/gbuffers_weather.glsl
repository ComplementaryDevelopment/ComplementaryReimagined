////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

/*in float discarder;
in float discarder2;*/

flat in vec2 lmCoord;
in vec2 texCoord;

flat in vec3 upVec, sunVec;

flat in vec4 glColor;

//Uniforms//
uniform int isEyeInWater;

uniform vec3 skyColor;

uniform sampler2D tex;

//Pipeline Constants//

//Common Variables//
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;

//Common Functions//

//Includes//
#include "/lib/colors/lightAndAmbientColors.glsl"

#ifdef COLOR_CODED_PROGRAMS
	#include "/lib/misc/colorCodedPrograms.glsl"
#endif

//Program//
void main() {
	vec4 color = texture2D(tex, texCoord);
	color *= glColor;

	if (color.a < 0.1 || isEyeInWater == 3) discard;

	//if (abs(discarder - 0.5) < 0.499 || discarder2 < 0.35) discard;

	#if WEATHER_TEX_OPACITY == 100
		const float rainTexOpacity = 0.25;
		const float snowTexOpacity = 0.5;
	#else
		#define WEATHER_TEX_OPACITY_M 100.0 / WEATHER_TEX_OPACITY
		const float rainTexOpacity = pow(0.25, WEATHER_TEX_OPACITY_M);
		const float snowTexOpacity = pow(0.5, WEATHER_TEX_OPACITY_M);
	#endif

	if (color.r + color.g < 1.5) color.a *= rainTexOpacity;
	else color.a *= snowTexOpacity;

	color.rgb = sqrt2(color.rgb) * (blocklightCol * 2.0 * lmCoord.x + ambientColor * lmCoord.y * (0.7 + 0.35 * sunFactor));

	#ifdef COLOR_CODED_PROGRAMS
		ColorCodeProgram(color);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

/*out float discarder;
out float discarder2;*/

flat out vec2 lmCoord;
out vec2 texCoord;

flat out vec3 upVec, sunVec;

flat out vec4 glColor;

//Uniforms//
uniform float frameTimeCounter;

uniform mat4 gbufferModelViewInverse;

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	glColor = gl_Color;

	/*discarder = 0.0;
	discarder2 = 1.0;
		
	if (abs(length(position.xz) - 2.25) < 0.5) {
		if (position.y > 0.0) {
			position.xz *= 5.0;
			position.y *= 0.5;
			discarder2 = 1.0;
		} else {
			position.xz *= -3.0;
			position.y = 5.0;
			discarder2 = 0.0;
		}
		discarder = 1.0;
		glColor.a *= 0.4;
	} //else glColor.a = 0.0;
	position.xz += (0.1 * position.y + 0.05) * vec2(sin(frameTimeCounter * 0.3) + 0.5, sin(frameTimeCounter * 0.5) * 0.5);
	position.xz *= 1.0 - 0.08 * position.y;*/

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmCoord  = GetLightMapCoordinates();
	
	upVec = normalize(gbufferModelView[1].xyz);
	sunVec = GetSunVector();
}

#endif
