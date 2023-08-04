////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;

flat in vec4 glColor;

#ifdef OVERWORLD
	flat in vec3 upVec, sunVec;
#endif

//Uniforms//
uniform int isEyeInWater;

uniform float viewWidth, viewHeight;

uniform vec3 skyColor;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D tex;

#ifdef CAVE_FOG
	uniform vec3 cameraPosition;
#endif

//Pipeline Constants//

//Common Variables//
#ifdef OVERWORLD
	float SdotU = dot(sunVec, upVec);
	float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
	float sunVisibility2 = sunVisibility * sunVisibility;
#endif

//Common Functions//

//Includes//
#include "/lib/colors/lightAndAmbientColors.glsl"

#ifdef CAVE_FOG
    #include "/lib/atmospherics/fog/caveFactor.glsl"
#endif

#ifdef COLOR_CODED_PROGRAMS
	#include "/lib/misc/colorCodedPrograms.glsl"
#endif

//Program//
void main() {
	#ifdef OVERWORLD
		vec2 tSize = textureSize(tex, 0);
		vec4 color = texture2D(tex, texCoord);
		color.rgb *= glColor.rgb;
	
		vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;
		vec3 nViewPos = normalize(viewPos.xyz);
		
		float VdotS = dot(nViewPos, sunVec);
		float VdotU = dot(nViewPos, upVec);

		if (abs(tSize.y - 264.0) < 248.5) { //tSize.y must range from 16 to 512
			#if SUN_MOON_STYLE >= 2
				discard;
			#endif

			if (VdotS > 0.0) { // Sun
				if (color.b > 0.1775) { // 0.065 to 0.290
					if (color.b > 0.48) { // 0.295 to 0.665
						color.rgb *= 12.0;
					} else {
						color.rgb *= 8.0;
					}

					color.rgb *= normalize(lightColor);
					color.rgb *= 0.2 + 0.8 * sunVisibility2;
				} else discard;
			} else { // Moon
				color.rgb *= sqrt2(max0(color.r - 0.115)); // 0.065 to 0.165
				color.rgb *= 1.5;
			}

			color.rgb *= GetHorizonFactor(VdotU);

			#ifdef CAVE_FOG
				color.rgb *= 1.0 - 0.75 * GetCaveFactor();
			#endif
		} else { // Custom Sky
			#if MC_VERSION >= 11300
				color.rgb *= color.rgb * smoothstep1(sqrt1(max0(VdotU)));
			#else
				discard;
				// Old mc custom skyboxes are weirdly broken, so we discard.
			#endif
		}

		if (isEyeInWater == 1) color.rgb *= 0.25;
		color.a *= invRainFactor * invRainFactor;
	#endif

	#ifdef NETHER
		vec4 color = vec4(0.0);
	#endif

	#ifdef END
		vec4 color = vec4(endSkyColor, 1.0);
	#endif

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

#ifdef OVERWORLD
	flat out vec3 upVec, sunVec;
#endif

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

	#ifdef OVERWORLD
		upVec = normalize(gbufferModelView[1].xyz);
		sunVec = GetSunVector();
	#endif
}

#endif
