////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

flat in vec3 upVec, sunVec;

flat in vec4 glColor;

#ifdef OVERWORLD
	flat in float vanillaStars;
#endif

//Uniforms//
uniform int isEyeInWater;

uniform float viewWidth, viewHeight;
uniform float blindness;
uniform float darknessFactor;

uniform vec3 fogColor;
uniform vec3 skyColor;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#ifdef CAVE_FOG
	uniform vec3 cameraPosition;
#endif

//Pipeline Constants//

//Common Variables//
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;

//Common Functions//

//Includes//
#include "/lib/util/dither.glsl"

#ifdef OVERWORLD
	#include "/lib/atmospherics/sky.glsl"
	#include "/lib/atmospherics/stars.glsl"
#endif

//Program//
void main() {
	vec4 color = vec4(glColor.rgb, 1.0);
	
	#ifdef OVERWORLD
	if (vanillaStars < 0.5) {
		vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;
		vec3 nViewPos = normalize(viewPos.xyz);

		float VdotU = dot(nViewPos, upVec);
		float VdotS = dot(nViewPos, sunVec);
		float dither = Bayer8(gl_FragCoord.xy);

		color.rgb = GetSky(VdotU, VdotS, dither, true, false);
		
		color.rgb += GetStars(viewPos.xyz, VdotU, VdotS);
	} else discard;
	#endif

	if (max(blindness, darknessFactor) > 0.1) color.rgb = vec3(0.0);

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

flat out vec3 upVec, sunVec;

flat out vec4 glColor;

#ifdef OVERWORLD
	flat out float vanillaStars;
#endif

//Uniforms//

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	gl_Position = ftransform();

	glColor = gl_Color;
	
	upVec = normalize(gbufferModelView[1].xyz);
	sunVec = GetSunVector();
	
	#ifdef OVERWORLD
		//Vanilla Star Dedection by Builderb0y
		vanillaStars = float(glColor.r == glColor.g && glColor.g == glColor.b && glColor.r > 0.0);
	#endif
}

#endif
