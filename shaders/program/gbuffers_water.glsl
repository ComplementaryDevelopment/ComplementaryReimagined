////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

flat in int mat;

in vec2 texCoord;
in vec2 lmCoord;

flat in vec3 upVec, sunVec, northVec, eastVec;
in vec3 normal;

in vec4 glColor;

#if WATER_STYLE >= 2 || RAIN_PUDDLES >= 1 && WATER_STYLE == 1 || defined GENERATED_NORMALS || defined CUSTOM_PBR
	flat in vec3 binormal, tangent;
#endif

#if WATER_STYLE >= 2 || defined FANCY_NETHERPORTAL || defined GENERATED_NORMALS
	in vec2 signMidCoordPos;
	flat in vec2 absMidCoordPos;
#endif

#if defined FANCY_NETHERPORTAL || WATER_STYLE >= 3
	in vec3 viewVector;
#endif

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

uniform float near;
uniform float far;
uniform float nightVision;
uniform float blindness;
uniform float darknessFactor;
uniform float frameTimeCounter;

uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform float viewWidth;
uniform float viewHeight;

uniform sampler2D texture;

#if WATER_QUALITY >= 2 || WATER_STYLE >= 2 || defined FANCY_NETHERPORTAL
	uniform sampler2D noisetex;
#endif

#ifdef CLOUDS_REIMAGINED
	uniform sampler2D gaux1;
#endif

#if WATER_QUALITY >= 2 || REFLECTION_QUALITY >= 1
	uniform sampler2D depthtex1;
#endif

#if REFLECTION_QUALITY >= 1
	uniform mat4 gbufferProjection;

	uniform sampler2D gaux2;
#endif

#if RAIN_PUDDLES >= 1
	uniform float isRainy;
#endif

#if defined GENERATED_NORMALS || defined COATED_TEXTURES
	uniform ivec2 atlasSize;
#endif

#ifdef CLOUD_SHADOWS
	uniform sampler2D gaux3;
#endif

#ifdef CUSTOM_PBR
	uniform sampler2D normals;
	uniform sampler2D specular;
#endif

//Pipeline Constants//

//Common Variables//
float NdotU = dot(normal, upVec);
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;

#ifdef OVERWORLD
	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
	vec3 lightVec = sunVec;
#endif

#if WATER_STYLE >= 2 || RAIN_PUDDLES >= 1 && WATER_STYLE == 1 || defined GENERATED_NORMALS || defined CUSTOM_PBR
	mat3 tbnMatrix = mat3(
		tangent.x, binormal.x, normal.x,
		tangent.y, binormal.y, normal.y,
		tangent.z, binormal.z, normal.z
	);
#endif

//Common Functions//
float GetLinearDepth(float depth) {
	return (2.0 * near) / (far + near - depth * (far - near));
}

#if REFLECTION_QUALITY >= 2
	vec3 nvec3(vec4 pos) {
		return pos.xyz/pos.w;
	}

	vec4 nvec4(vec3 pos) {
		return vec4(pos.xyz, 1.0);
	}

	float cdist(vec2 coord) {
		return max(abs(coord.s-0.5) * 1.82, abs(coord.t-0.5) * 2.0);
	}
#endif

#if WATER_STYLE >= 3
	float GetWaterHeightMap(vec2 waterPos, vec3 nViewPos, vec2 wind) {
		vec2 noiseA = 0.5 - texture2D(noisetex, waterPos - wind * 0.6).rg;
		vec2 noiseB = 0.5 - texture2D(noisetex, waterPos * 2.0 + wind).rg;

		return noiseA.r - noiseA.r * noiseB.r + noiseB.r * 0.6 + (noiseA.g + noiseB.g) * 2.5;
	}
#endif

//Includes//
#include "/lib/util/dither.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/mainLighting.glsl"
#include "/lib/atmospherics/fog/mainFog.glsl"

#if REFLECTION_QUALITY >= 1 && defined OVERWORLD
	#include "/lib/atmospherics/sky.glsl"
#endif

#ifdef TAA
	#include "/lib/util/jitter.glsl"
#endif

#if defined GENERATED_NORMALS || defined COATED_TEXTURES
	#include "/lib/util/miplevel.glsl"
#endif

#ifdef GENERATED_NORMALS
	#include "/lib/materials/materialMethods/generatedNormals.glsl"
#endif

#ifdef CUSTOM_PBR
	#include "/lib/materials/materialHandling/customMaterials.glsl"
#endif

//Program//
void main() {
	vec4 colorP = texture2D(texture, texCoord);
	vec4 color = colorP * vec4(glColor.rgb, 1.0);

	vec2 screenCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
	vec3 screenPos = vec3(screenCoord, gl_FragCoord.z);
	#ifdef TAA
		vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
		vec3 viewPos = ScreenToView(screenPos);
    #endif
	float lViewPos = length(viewPos);

	float dither = Bayer64(gl_FragCoord.xy);
	#ifdef TAA
		dither = fract(dither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	#ifdef CLOUDS_REIMAGINED
		float cloudLinearDepth = texelFetch(gaux1, texelCoord, 0).r;

		if (pow2(cloudLinearDepth + OSIEBCA * dither) * far < min(lViewPos, far)) discard;
	#endif

	vec3 nViewPos = normalize(viewPos);
    vec3 playerPos = ViewToPlayer(viewPos);
	float VdotU = dot(nViewPos, upVec);
	float VdotS = dot(nViewPos, sunVec);
	float VdotN = dot(nViewPos, normal);

	// Materials
	vec4 translucentMult = vec4(1.0);
	bool noSmoothLighting = false, noDirectionalShading = false, translucentMultCalculated = false;
	#ifdef GENERATED_NORMALS
		bool noGeneratedNormals = false;
	#endif
	float smoothnessG = 0.0, highlightMult = 1.0, reflectMult = 0.0, emission = 0.0;
	vec2 lmCoordM = lmCoord;
	vec3 normalM = VdotN > 0.0 ? -normal : normal; // Iris' Broken Water Normal Workaround
	vec3 shadowMult = vec3(1.0);
	float fresnel = clamp(1.0 + dot(normalM, nViewPos), 0.0, 1.0);

	#ifdef IPBR
		#include "/lib/materials/materialHandling/translucentMaterials.glsl"

		#ifdef GENERATED_NORMALS
			vec3 normalMP = normalM;
			if (!noGeneratedNormals) GenerateNormals(normalM, colorP.rgb * colorP.a * 1.5);
		#endif
	#else
		#ifdef CUSTOM_PBR
			float smoothnessD, materialMask;
			GetCustomMaterials(normalM, NdotU, smoothnessG, smoothnessD, highlightMult, emission, materialMask);
			reflectMult = smoothnessD;
		#endif

		if (mat == 31000) { // Water
			#include "/lib/materials/specificMaterials/translucents/water.glsl"
		}
	#endif

	// Blending
	if (!translucentMultCalculated) {
		translucentMult = vec4(mix(vec3(1.0), normalize(pow2(color.rgb)) * pow2(color.rgb), sqrt1(color.a)) * (1.0 - pow(color.a, 64.0)), 1.0);
		translucentMult = mix(translucentMult, vec4(1.0), min1(lViewPos * TRANSLUCENT_BLEND_FALLOFF_MULT));
	}

	// Lighting
	DoLighting(color.rgb, shadowMult, playerPos, viewPos, lViewPos, normalM, lmCoordM,
	           noSmoothLighting, noDirectionalShading, false, false, 0,
			   smoothnessG, highlightMult, emission);

	// Reflections
	fresnel = pow2(fresnel) * reflectMult;
	#if REFLECTION_QUALITY >= 2
		#include "/lib/materials/materialMethods/translucentReflections.glsl"
	#elif REFLECTION_QUALITY == 1
	    #ifdef OVERWORLD
			vec3 normalMR = normalM;
			#ifdef GENERATED_NORMALS
				normalMR = mix(normalMP, normalM, 0.05);
			#endif
			vec3 nViewPosR = reflect(nViewPos, normalMR);
			float RVdotU = dot(normalize(nViewPosR), upVec);
			float RVdotS = dot(normalize(nViewPosR), sunVec);

			vec4 clipPosR = gbufferProjection * vec4(nViewPosR, 1.0);
			vec3 screenPosR = clipPosR.xyz / clipPosR.w * 0.5 + 0.5;

			vec4 reflection = vec4(0.0);
			vec2 rEdge = vec2(0.6, 0.53);
			vec2 screenPosRM = abs(screenPosR.xy - 0.5);
			if (screenPosRM.x < rEdge.x && screenPosRM.y < rEdge.y) {
				vec2 edgeFactor = pow2(pow2(pow2(screenPosRM / rEdge)));
				screenPosR.y += (dither - 0.5) * (0.03 * (edgeFactor.x + edgeFactor.y) + 0.004);

				screenPosR.z = texture2D(depthtex1, screenPosR.xy).x;
				vec3 viewPosR = ScreenToView(screenPosR);
				if (lViewPos <= 2.0 + length(viewPosR)) {
					reflection = texture2D(gaux2, screenPosR.xy);
					reflection.rgb = pow2(reflection.rgb + 1.0);
				}

				edgeFactor.x = pow2(edgeFactor.x);
				edgeFactor = 1.0 - edgeFactor;
				reflection.a *= edgeFactor.x * edgeFactor.y;
			}

			reflection.a *= reflection.a;

			if (reflection.a < 1.0) {
				float skyLightFactor = pow2(max(lmCoordM.y - 0.7, 0.0) * 3.33333);

				vec3 skyReflection = GetLowQualitySky(RVdotU, RVdotS, dither, true, true);
				skyReflection = mix(color.rgb * 0.5, skyReflection, skyLightFactor);

				float specularHighlight = pow2(pow2(pow2(pow2(RVdotS))));
				skyReflection += specularHighlight * highlightColor * shadowMult * highlightMult * invRainFactor;

				reflection.rgb = mix(skyReflection, reflection.rgb, reflection.a);
			}

			color.rgb = mix(color.rgb, reflection.rgb, fresnel);
		#endif
    #endif

	float sky = 0.0;
	DoFog(color.rgb, sky, lViewPos, playerPos, VdotU, VdotS, dither);
	color.a *= 1.0 - sky;

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = color;
	gl_FragData[1] = translucentMult;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

flat out int mat;

out vec2 texCoord;
out vec2 lmCoord;

flat out vec3 upVec, sunVec, northVec, eastVec;
out vec3 normal;

out vec4 glColor;

#if WATER_STYLE >= 2 || RAIN_PUDDLES >= 1 && WATER_STYLE == 1 || defined GENERATED_NORMALS || defined CUSTOM_PBR
	flat out vec3 binormal, tangent;
#endif

#if WATER_STYLE >= 2 || defined FANCY_NETHERPORTAL || defined GENERATED_NORMALS
	out vec2 signMidCoordPos;
	flat out vec2 absMidCoordPos;
#endif

#if defined FANCY_NETHERPORTAL || WATER_STYLE >= 3
	out vec3 viewVector;
#endif

#ifdef WAVING_WATER_VERTEX
	uniform float frameTimeCounter;

	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;
#endif

//Uniforms//
#ifdef TAA
	uniform float viewWidth, viewHeight;
#endif

//Attributes//
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;
attribute vec4 at_tangent;

//Common Variables//

//Common Functions//

//Includes//
#ifdef TAA
	#include "/lib/util/jitter.glsl"
#endif

#ifdef WAVING_WATER_VERTEX
	#include "/lib/materials/materialMethods/wavingBlocks.glsl"
#endif

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmCoord  = GetLightMapCoordinates();

	glColor = gl_Color;

	mat = int(mc_Entity.x + 0.5);

	#ifdef WAVING_WATER_VERTEX
		vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

		DoWave(position.xyz, mat);
		
		gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	#else
		gl_Position = ftransform();
	#endif

	#ifdef TAA
		gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif

	normal = normalize(gl_NormalMatrix * gl_Normal);
	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);
	northVec = normalize(gbufferModelView[2].xyz);
	sunVec = GetSunVector();

	#if WATER_STYLE >= 2 || RAIN_PUDDLES >= 1 && WATER_STYLE == 1 || defined GENERATED_NORMALS || defined CUSTOM_PBR
		#define TANGENT_CALCULATED
		binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
		tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	#endif

	#if WATER_STYLE >= 2 || defined FANCY_NETHERPORTAL || defined GENERATED_NORMALS
		vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
		vec2 texMinMidCoord = texCoord - midCoord;
		signMidCoordPos = sign(texMinMidCoord);
		absMidCoordPos  = abs(texMinMidCoord);
	#endif

	#if defined FANCY_NETHERPORTAL || WATER_STYLE >= 3
		#ifndef TANGENT_CALCULATED
			vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
			vec3 tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
		#endif

        mat3 tbnMatrix = mat3(
            tangent.x, binormal.x, normal.x,
            tangent.y, binormal.y, normal.y,
            tangent.z, binormal.z, normal.z
        );

		viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	#endif

	gl_Position.z -= 0.0001;
}

#endif
