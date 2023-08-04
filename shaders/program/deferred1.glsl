////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

flat in vec3 upVec, sunVec;

#if LIGHTSHAFT_BEHAVIOUR == 1 && defined LIGHTSHAFTS_ACTIVE
    flat in float vlFactor;
#endif

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

uniform float far, near;
uniform float viewWidth, viewHeight;
uniform float blindness;
uniform float darknessFactor;
uniform float frameTimeCounter;

uniform vec3 skyColor;
uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

#if SSAO_QUALI > 0 || defined PBR_REFLECTIONS
	uniform mat4 gbufferProjection;
#endif

#if SSAO_QUALI > 0 || defined WORLD_OUTLINE
	uniform float aspectRatio;
#endif

#ifdef PBR_REFLECTIONS
	uniform mat4 gbufferModelView;
	
	uniform sampler2D colortex5;
#endif

#if AURORA_STYLE > 0
	uniform int moonPhase;

	uniform float isSnowy;
#endif

#ifdef CLOUDS_REIMAGINED
	uniform ivec2 eyeBrightness;
	
	uniform sampler2D colortex3;
	
	#ifdef REALTIME_SHADOWS
		uniform sampler2DShadow shadowtex0;
	#endif
#endif

#ifdef TEMPORAL_FILTER
	uniform vec3 previousCameraPosition;

	uniform mat4 gbufferPreviousProjection;
	uniform mat4 gbufferPreviousModelView;

	uniform sampler2D colortex6;
	uniform sampler2D colortex7;
#endif

//Pipeline Constants//
const bool colortex0MipmapEnabled = true;

//Common Variables//
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;
float farMinusNear = far - near;

#ifdef OVERWORLD
	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
	vec3 lightVec = sunVec;
#endif

#if SSAO_QUALI > 0 || defined WORLD_OUTLINE
    vec2 view = vec2(viewWidth, viewHeight);
#endif

#if LIGHTSHAFT_BEHAVIOUR == 1 && defined LIGHTSHAFTS_ACTIVE
#else
	float vlFactor = 0.0;
#endif

//Common Functions//
float GetLinearDepth(float depth) {
	return (2.0 * near) / (far + near - depth * farMinusNear);
}

#if SSAO_QUALI > 0
    vec2 OffsetDist(float x, int s) {
        float n = fract(x * 1.414) * 3.1415;
        return pow2(vec2(cos(n), sin(n)) * x / s);
    }

    float DoAmbientOcclusion(float z0, float linearZ0, float dither) {
		if (z0 < 0.56) return 1.0;
        float ao = 0.0;

		#if SSAO_QUALI == 2
        	int samples = 4;
			float scm = 0.4;
		#elif SSAO_QUALI == 3
        	int samples = 12;
			float scm = 0.6;
		#endif

		#define SSAO_I_FACTOR 0.004
        
        float sampleDepth = 0.0, angle = 0.0, dist = 0.0;
        float fovScale = gbufferProjection[1][1];
        float distScale = max(farMinusNear * linearZ0 + near, 3.0);
        vec2 scale = vec2(scm / aspectRatio, scm) * fovScale / distScale;

        for (int i = 1; i <= samples; i++) {
            vec2 offset = OffsetDist(i + dither, samples) * scale;
            if (i % 2 == 0) offset.y = -offset.y;

            vec2 coord1 = texCoord + offset;
            vec2 coord2 = texCoord - offset;

            sampleDepth = GetLinearDepth(texture2D(depthtex0, coord1).r);
            float aosample = farMinusNear * (linearZ0 - sampleDepth) * 2.0;
            angle = clamp(0.5 - aosample, 0.0, 1.0);
            dist = clamp(0.5 * aosample - 1.0, 0.0, 1.0);

            sampleDepth = GetLinearDepth(texture2D(depthtex0, coord2).r);
            aosample = farMinusNear * (linearZ0 - sampleDepth) * 2.0;
            angle += clamp(0.5 - aosample, 0.0, 1.0);
            dist += clamp(0.5 * aosample - 1.0, 0.0, 1.0);
            
            ao += clamp(angle + dist, 0.0, 1.0);
        }
        ao /= samples;
        
		#define SSAO_IM SSAO_I * SSAO_I_FACTOR
		return pow(ao, SSAO_IM);
    }
#endif

#ifdef TEMPORAL_FILTER
	float GetApproxDistance(float depth) {
		return near * far / (far - depth * far);
	}

	// Previous frame reprojection from Chocapic13
	vec2 Reprojection(vec3 pos, vec3 cameraOffset) {
		pos = pos * 2.0 - 1.0;

		vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0);
		viewPosPrev /= viewPosPrev.w;
		viewPosPrev = gbufferModelViewInverse * viewPosPrev;

		vec4 previousPosition = viewPosPrev + vec4(cameraOffset, 0.0);
		previousPosition = gbufferPreviousModelView * previousPosition;
		previousPosition = gbufferPreviousProjection * previousPosition;
		return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
	}

	vec3 FHalfReprojection(vec3 pos) {
		pos = pos * 2.0 - 1.0;

		vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0);
		viewPosPrev /= viewPosPrev.w;
		viewPosPrev = gbufferModelViewInverse * viewPosPrev;

		return viewPosPrev.xyz;
	}

	vec2 SHalfReprojection(vec3 playerPos, vec3 cameraOffset) {
		vec4 proPos = vec4(playerPos + cameraOffset, 1.0);
		vec4 previousPosition = gbufferPreviousModelView * proPos;
		previousPosition = gbufferPreviousProjection * previousPosition;
		return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
	}
#endif

//Includes//
#include "/lib/util/spaceConversion.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/fog/mainFog.glsl"
#include "/lib/colors/skyColors.glsl"

#ifdef PBR_REFLECTIONS
	#include "/lib/materials/materialMethods/reflections.glsl"
#endif

#if AURORA_STYLE > 0
	#include "/lib/atmospherics/auroraBorealis.glsl"
#endif

#ifdef SHADER_CLOUDS_ACTIVE
	#include "/lib/atmospherics/clouds/mainClouds.glsl"
#endif

#ifdef END
	#include "/lib/atmospherics/enderStars.glsl"
#endif

#ifdef WORLD_OUTLINE
	#include "/lib/misc/worldOutline.glsl"
#endif

#ifdef ATM_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif

#ifdef NIGHT_NEBULA
	#include "/lib/atmospherics/nightNebula.glsl"
#endif

//Program//
void main() {
	vec3 color = texelFetch(colortex0, texelCoord, 0).rgb;
	float z0   = texelFetch(depthtex0, texelCoord, 0).r;

	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;
	float lViewPos = length(viewPos);
	vec3 nViewPos = normalize(viewPos.xyz);
	vec3 playerPos = ViewToPlayer(viewPos.xyz);

	float dither = texture2D(noisetex, texCoord * vec2(viewWidth, viewHeight) / 128.0).b;
	float ditherAnimate = 1.61803398875 * mod(float(frameCounter), 3600.0);
	dither = fract(dither + ditherAnimate);

	#ifdef ATM_COLOR_MULTS
		atmColorMult = GetAtmColorMult();
	#endif

	float VdotU = dot(nViewPos, upVec);
	float VdotS = dot(nViewPos, sunVec);
	float skyFade = 0.0;
	vec3 waterRefColor = vec3(0.0);

	#if AURORA_STYLE > 0
		vec3 auroraBorealis = vec3(0.0);
	#endif
	#ifdef NIGHT_NEBULA
		vec3 nightNebula = vec3(0.0);
	#endif

	#ifdef TEMPORAL_FILTER
		vec4 refToWrite = vec4(0.0);
	#endif

	#ifdef SHADER_CLOUDS_ACTIVE
		bool sun = false;
	#endif
	
	if (z0 < 1.0) {
		vec3 texture5 = texelFetch(colortex1, texelCoord, 0).rgb;

		#if SSAO_QUALI > 0 || defined WORLD_OUTLINE
			float linearZ0 = GetLinearDepth(z0);
		#endif

		#if SSAO_QUALI > 0
			float ssao = DoAmbientOcclusion(z0, linearZ0, dither);
		#else
			float ssao = 1.0;
		#endif
		
		int materialMaskInt = int(texture5.g * 255.1);
		float intenseFresnel = 0.0;
		float smoothnessD = texture5.r;
		vec3 reflectColor = vec3(1.0);

		#ifdef IPBR
			#include "/lib/materials/materialHandling/deferredMaterials.glsl"
		#else
			if (materialMaskInt <= 240) {
				#ifdef CUSTOM_PBR
					#if RP_MODE == 2 // seuspbr
						float metalness = materialMaskInt / 240.0;

						intenseFresnel = metalness;
						color.rgb *= 1.0 - 0.25 * metalness;
					#elif RP_MODE == 3 // labPBR
						float metalness = float(materialMaskInt >= 230);

						intenseFresnel = materialMaskInt / 240.0;
						color.rgb *= 1.0 - 0.25 * metalness;
					#endif
					reflectColor = mix(reflectColor, color.rgb / max(color.r + 0.00001, max(color.g, color.b)), metalness);
				#endif
			} else {
				if (materialMaskInt == 254) // No SSAO, No TAA
					ssao = 1.0;
			}
		#endif
		
		color.rgb *= ssao;

		#ifdef PBR_REFLECTIONS
			float skyLightFactor = texture5.b;
			vec3 normalM = mat3(gbufferModelView) * texelFetch(colortex5, texelCoord, 0).rgb;

			float fresnel = clamp(1.0 + dot(normalM, nViewPos), 0.0, 1.0);

			float fresnelFactor = (1.0 - smoothnessD) * 0.7;
			float fresnelM = max(fresnel - fresnelFactor, 0.0) / (1.0 - fresnelFactor);
			#ifdef IPBR
				fresnelM = mix(pow2(fresnelM), fresnelM * 0.75 + 0.25, intenseFresnel);
			#else
				fresnelM = mix(pow2(fresnelM), fresnelM * 0.5 + 0.5, intenseFresnel);
			#endif
			fresnelM = fresnelM * smoothnessD - dither * 0.001;

			if (fresnelM > 0.0) {
				vec3 roughPos = playerPos + cameraPosition;
				roughPos *= 256.0;
				vec2 roughCoord = roughPos.xz + roughPos.y;
				#ifndef TEMPORAL_FILTER
					float noiseMult = 0.3;
				#else
					float noiseMult = 0.3;
					float blendFactor = 1.0;
					roughCoord += fract(frameTimeCounter);
				#endif
				vec3 roughNoise = vec3(texture2D(noisetex, roughCoord).r, texture2D(noisetex, roughCoord + 0.1).r, texture2D(noisetex, roughCoord + 0.2).r);
				roughNoise = noiseMult * (roughNoise - vec3(0.5));
				roughNoise *= pow2(1.0 - smoothnessD);
				#ifdef CUSTOM_PBR
					if (z0 <= 0.56) {
						roughNoise *= 0.1;
						#ifdef TEMPORAL_FILTER
							blendFactor = 0.0;
						#endif
					}
				#endif

				normalM += roughNoise;

				vec4 reflection = GetReflection(normalM, viewPos.xyz, nViewPos, playerPos, lViewPos, z0,
				                                depthtex0, dither, skyLightFactor, fresnel,
												smoothnessD, vec3(0.0), vec3(0.0), vec3(0.0), 0.0);

				vec3 colorAdd = reflection.rgb * reflectColor;
				//float colorMultInv = (0.75 - intenseFresnel * 0.5) * max(reflection.a, skyLightFactor);
				//float colorMultInv = max(reflection.a, skyLightFactor);
				float colorMultInv = 1.0;

				#ifdef IPBR
					vec3 colorP = color;
				#endif

				#ifndef TEMPORAL_FILTER
					color *= 1.0 - colorMultInv * fresnelM;
					color += colorAdd * fresnelM;
				#else
					vec3 cameraOffset = cameraPosition - previousCameraPosition;
					vec2 prvCoord = SHalfReprojection(playerPos, cameraOffset);
					#if defined IPBR && !defined GENERATED_NORMALS
						vec2 prvRefCoord = Reprojection(vec3(texCoord, max(refPos.z, z0)), cameraOffset);
						vec4 oldRef = texture2D(colortex7, prvRefCoord);
					#else
						vec2 prvRefCoord1 = Reprojection(vec3(texCoord, z0), cameraOffset);
						vec2 prvRefCoord2 = Reprojection(vec3(texCoord, max(refPos.z, z0)), cameraOffset);
						vec4 oldRef1 = texture2D(colortex7, prvRefCoord1);
						vec4 oldRef2 = texture2D(colortex7, prvRefCoord2);
						vec3 dif1 = colorAdd - oldRef1.rgb;
						vec3 dif2 = colorAdd - oldRef2.rgb;
						float dotDif1 = dot(dif1, dif1);
						float dotDif2 = dot(dif2, dif2);

						float oldRefMixer = clamp01((dotDif1 - dotDif2) * 500.0);
						vec4 oldRef = mix(oldRef1, oldRef2, oldRefMixer);
					#endif

					vec4 newRef = vec4(colorAdd, colorMultInv);

					blendFactor *= float(prvCoord.x > 0.0 && prvCoord.x < 1.0 && prvCoord.y > 0.0 && prvCoord.y < 1.0);
					float velocity = length(cameraOffset) * max(16.0 - lViewPos / gbufferProjection[1][1], 3.0);
					blendFactor *= 0.7 + 0.3 * exp(-velocity);

					float z1P = texture2D(colortex6, prvCoord).r;
					vec3 disChange = playerPos - FHalfReprojection(vec3(prvCoord, z1P)) + cameraOffset;

					blendFactor *= exp(-dot(disChange, disChange) * 100.0);

					blendFactor = max0(blendFactor); // Prevents first frame NaN
					//newRef = max(newRef, vec4(0.0)); // Prevents some other NaN?
					refToWrite = mix(newRef, oldRef, blendFactor * 0.95);

					color.rgb *= 1.0 - refToWrite.a * fresnelM;
					color.rgb += refToWrite.rgb * fresnelM;
				#endif

				#ifdef IPBR
					color = max(colorP * intenseFresnel * 0.9, color);
				#endif

				//if (gl_FragCoord.x > 960) color = vec3(5.25,0,5.25);
			}
		#endif

		#ifdef WORLD_OUTLINE
			DoWorldOutline(color, linearZ0);
		#endif

		waterRefColor = sqrt(color) - 1.0;

		DoFog(color, skyFade, lViewPos, playerPos, VdotU, VdotS, dither);
	} else { // Sky
		skyFade = 1.0;
		
		#ifdef OVERWORLD
			#ifdef CLOUDS_REIMAGINED
				sun = color.r > 2.0;
			#endif

			#if AURORA_STYLE > 0
				auroraBorealis = GetAuroraBorealis(viewPos.xyz, VdotU, dither);
				#ifdef ATM_COLOR_MULTS
					auroraBorealis *= atmColorMult;
				#endif
				color.rgb += auroraBorealis;
			#endif
			#ifdef NIGHT_NEBULA
				nightNebula += GetNightNebula(viewPos.xyz, VdotU, VdotS);
				#ifdef ATM_COLOR_MULTS
					nightNebula *= atmColorMult;
				#endif
				color.rgb += nightNebula;
			#endif
		#endif
		#ifdef NETHER
			color.rgb = netherSkyColor;

			#ifdef ATM_COLOR_MULTS
				color.rgb *= atmColorMult;
			#endif
		#endif
		#ifdef END
			color.rgb = endSkyColor;
			color.rgb += GetEnderStars(viewPos.xyz, VdotU);

			#ifdef ATM_COLOR_MULTS
				color.rgb *= atmColorMult;
			#endif
		#endif
	}
	
	float cloudLinearDepth = 1.0;

	#ifdef SHADER_CLOUDS_ACTIVE
		if (z0 > 0.56) {
			vec4 clouds = GetClouds(cloudLinearDepth, skyFade, playerPos, viewPos.xyz, lViewPos, VdotS, VdotU, dither);

			#ifdef ATM_COLOR_MULTS
				clouds.rgb *= atmColorMult;
			#endif

			#if AURORA_STYLE > 0
				clouds.rgb += auroraBorealis * 0.1;
			#endif
			#ifdef NIGHT_NEBULA
				clouds.rgb += nightNebula * 0.2;
			#endif

			color = mix(color, clouds.rgb, clouds.a);
		}
	#endif

	#if LIGHTSHAFT_BEHAVIOUR == 1 && defined LIGHTSHAFTS_ACTIVE
		if (viewWidth + viewHeight - gl_FragCoord.x - gl_FragCoord.y < 1.5)
			cloudLinearDepth = vlFactor;
	#endif

	/*DRAWBUFFERS:054*/
    gl_FragData[0] = vec4(color, 1.0);
	gl_FragData[1] = vec4(waterRefColor, 1.0 - skyFade);
	gl_FragData[2] = vec4(cloudLinearDepth, 0.0, 0.0, 1.0);
	#ifdef TEMPORAL_FILTER
		/*DRAWBUFFERS:0547*/
		gl_FragData[3] = refToWrite;
	#endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

flat out vec3 upVec, sunVec;

#if LIGHTSHAFT_BEHAVIOUR == 1 && defined LIGHTSHAFTS_ACTIVE
    flat out float vlFactor;
#endif

//Uniforms//
#if LIGHTSHAFT_BEHAVIOUR == 1 && defined LIGHTSHAFTS_ACTIVE
	uniform float viewWidth, viewHeight;
	
	uniform sampler2D colortex4;

	#ifdef END
		uniform int frameCounter;
	
		uniform float frameTimeSmooth;
		uniform float far;

		uniform vec3 cameraPosition;
	#endif
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	gl_Position = ftransform();
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	upVec = normalize(gbufferModelView[1].xyz);
	sunVec = GetSunVector();

	#if LIGHTSHAFT_BEHAVIOUR == 1 && defined LIGHTSHAFTS_ACTIVE
		vlFactor = texelFetch(colortex4, ivec2(viewWidth-1, viewHeight-1), 0).r;

		#ifdef END
			if (frameCounter % int(0.06666 / frameTimeSmooth + 0.5) == 0) { // Change speed is not too different above 10 fps
				vec2 absCamPosXZ = abs(cameraPosition.xz);
				float maxCamPosXZ = max(absCamPosXZ.x, absCamPosXZ.y);

				if (gl_Fog.start / far > 0.5 || maxCamPosXZ > 350.0) vlFactor = max(vlFactor - OSIEBCA*2, 0.0);
				else                                                 vlFactor = min(vlFactor + OSIEBCA*2, 1.0);
			}
		#endif
    #endif
}

#endif
