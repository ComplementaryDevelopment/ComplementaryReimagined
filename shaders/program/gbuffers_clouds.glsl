////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

#if CLOUD_STYLE_DEFINE == 50
// We use CLOUD_STYLE_DEFINE instead of CLOUD_STYLE in this file because Optifine can't use generated defines for pipeline stuff
	in vec2 texCoord;

	flat in vec3 upVec, sunVec;

	in vec4 glColor;
#endif

//Uniforms//
#if CLOUD_STYLE_DEFINE == 50
	uniform vec3 skyColor;

	uniform sampler2D tex;

	#ifdef BORDER_FOG
		uniform float viewWidth;
		uniform float viewHeight;

		uniform mat4 gbufferProjectionInverse;
		uniform mat4 gbufferModelViewInverse;
		uniform mat4 shadowModelView;
		uniform mat4 shadowProjection;
	#endif
#endif

//Pipeline Constants//

//Common Variables//
#if CLOUD_STYLE_DEFINE == 50
	float SdotU = dot(sunVec, upVec);
	float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
	float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
	float sunVisibility2 = sunVisibility * sunVisibility;
#endif

//Common Functions//

//Includes//
#if CLOUD_STYLE_DEFINE == 50
	#include "/lib/colors/skyColors.glsl"
	#include "/lib/util/spaceConversion.glsl"

	#if defined TAA && defined BORDER_FOG
		#include "/lib/util/jitter.glsl"
	#endif

	#ifdef ATM_COLOR_MULTS
		#include "/lib/colors/colorMultipliers.glsl"
	#endif

	#ifdef COLOR_CODED_PROGRAMS
		#include "/lib/misc/colorCodedPrograms.glsl"
	#endif
#endif

//Program//
void main() {
	#if CLOUD_STYLE_DEFINE != 50
		discard;
	#else
		vec4 color = texture2D(tex, texCoord) * glColor;

		#ifdef OVERWORLD
			vec3 cloudLight = mix(vec3(0.7, 1.3, 1.2) * nightFactor, mix(dayDownSkyColor, dayMiddleSkyColor, 0.1), sunFactor);
			color.rgb *= sqrt(cloudLight) * (1.4 + 0.2 * noonFactor - rainFactor);

			#ifdef ATM_COLOR_MULTS
				atmColorMult = GetAtmColorMult();
				color.rgb *= atmColorMult;
			#endif
		#endif

		#ifdef BORDER_FOG
			vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
			#ifdef TAA
				vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
			#else
				vec3 viewPos = ScreenToView(screenPos);
			#endif
			vec3 playerPos = ViewToPlayer(viewPos);

			float xzMaxDistance = max(abs(playerPos.x), abs(playerPos.z));
			float cloudDistance = 375.0;
			cloudDistance = clamp((cloudDistance - xzMaxDistance) / cloudDistance, 0.0, 1.0);
			color.a *= clamp01(cloudDistance * 3.0);
		#endif

		#ifdef COLOR_CODED_PROGRAMS
			ColorCodeProgram(color);
		#endif

		/* DRAWBUFFERS:01 */
		gl_FragData[0] = color;
		gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
	#endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

#if CLOUD_STYLE_DEFINE == 50
	out vec2 texCoord;

	flat out vec3 upVec, sunVec;

	out vec4 glColor;
#endif

//Uniforms//
#if CLOUD_STYLE_DEFINE == 50
	uniform mat4 gbufferModelViewInverse;

	#ifdef TAA
		uniform float viewWidth, viewHeight;
	#endif
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//
#if CLOUD_STYLE_DEFINE == 50
	#ifdef TAA
		#include "/lib/util/jitter.glsl"
	#endif
#endif

//Program//
void main() {
	#if CLOUD_STYLE_DEFINE != 50
		gl_Position = vec4(-1.0);
	#else
		texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		glColor = gl_Color;

		upVec = normalize(gbufferModelView[1].xyz);
		sunVec = GetSunVector();

		vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
		position.xz -= vec2(88.0);
		gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

		#ifdef TAA
			gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
		#endif
	#endif
}

#endif
