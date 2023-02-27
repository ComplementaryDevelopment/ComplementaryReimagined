////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;
in vec2 lmCoord;

flat in vec3 upVec, sunVec, northVec, eastVec;
in vec3 normal;

in vec4 glColor;

#if defined GENERATED_NORMALS || defined COATED_TEXTURES
	in vec2 signMidCoordPos;
	flat in vec2 absMidCoordPos;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
	flat in vec3 binormal, tangent;
#endif

//Uniforms//
uniform int isEyeInWater;
uniform int entityId;
uniform int blockEntityId;

uniform float viewWidth;
uniform float viewHeight;
uniform float nightVision;
uniform float frameTimeCounter;

uniform ivec2 atlasSize;

uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 cameraPosition;

uniform vec4 entityColor;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D texture;

#ifdef COATED_TEXTURES
	uniform sampler2D noisetex;
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

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
	mat3 tbnMatrix = mat3(
		tangent.x, binormal.x, normal.x,
		tangent.y, binormal.y, normal.y,
		tangent.z, binormal.z, normal.z
	);
#endif

//Common Functions//

//Includes//
#include "/lib/util/dither.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/mainLighting.glsl"

#if defined GENERATED_NORMALS || defined COATED_TEXTURES
	#include "/lib/util/miplevel.glsl"
#endif

#ifdef GENERATED_NORMALS
	#include "/lib/materials/materialMethods/generatedNormals.glsl"
#endif

#ifdef COATED_TEXTURES
	#include "/lib/materials/materialMethods/coatedTextures.glsl"
#endif

#ifdef CUSTOM_PBR
	#include "/lib/materials/materialHandling/customMaterials.glsl"
#endif

//Program//
void main() {
	vec4 color = texture2D(texture, texCoord);
	#ifdef GENERATED_NORMALS
		vec3 colorP = color.rgb;
	#endif
	color *= glColor;

	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	vec3 viewPos = ScreenToView(screenPos);
	vec3 nViewPos = normalize(viewPos);
	vec3 playerPos = ViewToPlayer(viewPos);
	float lViewPos = length(viewPos);

	bool noSmoothLighting = atlasSize.x < 600.0; // To fix fire looking too dim
	
	float smoothnessD = 0.0, skyLightFactor = 0.0, materialMask = OSIEBCA * 254.0; // No SSAO, No TAA
	float smoothnessG = 0.0, highlightMult = 0.0, emission = 0.0, noiseFactor = 0.75;
	vec2 lmCoordM = lmCoord;
	vec3 normalM = normal;
	vec3 shadowMult = vec3(1.0);
	#ifdef IPBR
		#include "/lib/materials/materialHandling/entityMaterials.glsl"

		#ifdef GENERATED_NORMALS
			GenerateNormals(normalM, colorP);
		#endif

		#ifdef COATED_TEXTURES
			CoatTextures(color.rgb, noiseFactor, playerPos);
		#endif
	#else
		#ifdef CUSTOM_PBR
			GetCustomMaterials(normalM, NdotU, smoothnessG, smoothnessD, highlightMult, emission, materialMask);
		#endif
		
		if (entityId == 50004) { // Lightning Bolt
			#include "/lib/materials/specificMaterials/entities/lightningBolt.glsl"
		} else if (entityId == 50008) { // Item Frame, Glow Item Frame
			noSmoothLighting = true;
		}
	#endif

	normalM = gl_FrontFacing ? normalM : -normalM; // Inverted Normal Workaround

	DoLighting(color.rgb, shadowMult, playerPos, viewPos, lViewPos, normalM, lmCoordM,
				noSmoothLighting, false, false, true, 0,
				smoothnessG, highlightMult, emission);

	#if defined CUSTOM_PBR && defined PBR_REFLECTIONS
		#ifdef OVERWORLD
			skyLightFactor = pow2(max(lmCoord.y - 0.7, 0.0) * 3.33333);
		#else
			skyLightFactor = dot(shadowMult, shadowMult) / 3.0;
		#endif
	#endif

	/* DRAWBUFFERS:01 */
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(smoothnessD, materialMask, skyLightFactor, 1.0);

	#if REFLECTION_QUALITY >= 3 && RP_MODE >= 2
		/* DRAWBUFFERS:015 */
		gl_FragData[2] = vec4(mat3(gbufferModelViewInverse) * normalM, 1.0);
	#endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;
out vec2 lmCoord;

flat out vec3 upVec, sunVec, northVec, eastVec;
out vec3 normal;

out vec4 glColor;

#if defined GENERATED_NORMALS || defined COATED_TEXTURES
	out vec2 signMidCoordPos;
	flat out vec2 absMidCoordPos;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
	flat out vec3 binormal, tangent;
#endif

//Uniforms//
#ifdef FLICKERING_FIX
	uniform int entityId;

	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;
#endif

//Attributes//
#if defined GENERATED_NORMALS || defined COATED_TEXTURES
	attribute vec4 mc_midTexCoord;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
	attribute vec4 at_tangent;
#endif

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	gl_Position = ftransform();

	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lmCoord  = GetLightMapCoordinates();

	glColor = gl_Color;

	normal = normalize(gl_NormalMatrix * gl_Normal);

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);
	northVec = normalize(gbufferModelView[2].xyz);
	sunVec = GetSunVector();
	
	#if defined GENERATED_NORMALS || defined COATED_TEXTURES
		vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
		vec2 texMinMidCoord = texCoord - midCoord;
		signMidCoordPos = sign(texMinMidCoord);
		absMidCoordPos  = abs(texMinMidCoord);
	#endif

	#if defined GENERATED_NORMALS || defined CUSTOM_PBR
		binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
		tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	#endif

	#ifdef GBUFFERS_ENTITIES_GLOWING
		if (glColor.a > 0.99) gl_Position.z *= 0.01;
	#endif

	#ifdef FLICKERING_FIX
		if (entityId == 50008 || entityId == 50012) { // Item Frame, Glow Item Frame
			if (dot(normal, upVec) > 0.99) {
				vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
				vec3 comPos = fract(position.xyz + cameraPosition);
				comPos = abs(comPos - vec3(0.5));
				if ((comPos.y > 0.437 && comPos.y < 0.438) || (comPos.y > 0.468 && comPos.y < 0.469)) {
					gl_Position.z += 0.0001;
				}
			}
			if (gl_Normal.y == 1.0) { // Maps
				normal = upVec * 2.0;
			}
		} else if (entityId == 50084) { // Slime
			gl_Position.z -= 0.00015;
		}
		#ifndef REALTIME_SHADOWS
			if (glColor.a < 0.5) gl_Position.z += 0.0005;
		#endif
	#endif
}

#endif
