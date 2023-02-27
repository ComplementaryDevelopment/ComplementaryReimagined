////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

flat in vec3 upVec, sunVec;

#if LIGHTSHAFT_BEHAVIOUR == 1 && LIGHTSHAFT_QUALITY > 0 && defined OVERWORLD && defined REALTIME_SHADOWS || defined END
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

uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

#if defined SSAO || defined PBR_REFLECTIONS
	uniform mat4 gbufferProjection;
#endif

#if defined SSAO || defined WORLD_OUTLINE
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

#if defined SSAO || defined WORLD_OUTLINE
    vec2 view = vec2(viewWidth, viewHeight);
#endif

#ifdef TEMPORAL_FILTER
	ivec2 neighbourhoodOffsets[8] = ivec2[8](
		ivec2(-1, -1),
		ivec2( 0, -1),
		ivec2( 1, -1),
		ivec2(-1,  0),
		ivec2( 1,  0),
		ivec2(-1,  1),
		ivec2( 0,  1),
		ivec2( 1,  1)
	);
#endif

#if LIGHTSHAFT_BEHAVIOUR == 1 && LIGHTSHAFT_QUALITY > 0 && defined OVERWORLD && defined REALTIME_SHADOWS || defined END
#else
	float vlFactor = 0.0;
#endif

//Common Functions//
float GetLinearDepth(float depth) {
	return (2.0 * near) / (far + near - depth * farMinusNear);
}

#ifdef SSAO
    vec2 OffsetDist(float x, int s) {
        float n = fract(x * 1.414) * 3.1415;
        return pow2(vec2(cos(n), sin(n)) * x / s);
    }

    float DoAmbientOcclusion(float z0, float linearZ0, float dither) {
		if (z0 < 0.56) return 1.0;
        float ao = 0.0;
        int samples = 12;
        
        float sampleDepth = 0.0, angle = 0.0, dist = 0.0;
        float fovScale = gbufferProjection[1][1] / 1.37;
        float distScale = max(farMinusNear * linearZ0 + near, 3.0);
        vec2 scale = vec2(0.4 / aspectRatio, 0.5) * fovScale / distScale;

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
        
        return pow(ao, 0.8);
    }
#endif

#ifdef PBR_REFLECTIONS
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

#ifdef TEMPORAL_FILTER
	// Previous frame reprojection from Chocapic13
	vec2 Reprojection(vec3 playerPos, vec3 cameraOffset) {
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
	#ifdef OVERWORLD
		#include "/lib/atmospherics/sky.glsl"
	#endif
	#ifdef END
		#include "/lib/atmospherics/enderBeams.glsl"
	#endif
#endif

#if AURORA_STYLE > 0
	#include "/lib/atmospherics/auroraBorealis.glsl"
#endif

#ifdef CLOUDS_ACTIVATE
	#include "/lib/atmospherics/clouds/mainClouds.glsl"
#endif

#ifdef END
	#include "/lib/atmospherics/enderStars.glsl"
#endif

#ifdef WORLD_OUTLINE
	#include "/lib/misc/worldOutline.glsl"
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
	#ifdef TAA
		float ditherAnimate = 1.61803398875 * mod(float(frameCounter), 3600.0);
		dither = fract(dither + ditherAnimate);
	#endif

	float VdotU = dot(nViewPos, upVec);
	float VdotS = dot(nViewPos, sunVec);
	float skyFade = 0.0;
	vec3 waterRefColor = vec3(0.0);

	#if AURORA_STYLE > 0
		vec3 auroraBorealis = vec3(0.0);
	#endif

	#ifdef TEMPORAL_FILTER
		vec4 refAndCloudNew = vec4(0.0);
	#endif

	#ifdef CLOUDS_ACTIVATE
		bool sun = false;
	#endif
	
	if (z0 < 1.0) {
		vec3 texture5 = texelFetch(colortex1, texelCoord, 0).rgb;

		#if defined SSAO || defined WORLD_OUTLINE
			float linearZ0 = GetLinearDepth(z0);
		#endif

		#ifdef SSAO
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
					#if RP_MODE == 2 // SEUSPBR
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
				#ifdef TEMPORAL_FILTER
					roughCoord += fract(frameTimeCounter);
				#endif
				vec3 roughNoise = vec3(texture2D(noisetex, roughCoord).r, texture2D(noisetex, roughCoord + 0.1).r, texture2D(noisetex, roughCoord + 0.2).r);
				roughNoise = vec3(0.3, 0.3, 0.3) * (roughNoise - vec3(0.5));
				
				roughNoise *= pow2(1.0 - smoothnessD);

				normalM += roughNoise;
			
				#include "/lib/materials/materialMethods/deferredReflections.glsl"

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
				color.rgb += auroraBorealis;
			#endif
		#endif
		#ifdef NETHER
			color.rgb = netherSkyColor;
		#endif
		#ifdef END
			color.rgb = endSkyColor;
			color.rgb += GetEnderStars(viewPos.xyz, VdotU);
		#endif
	}
	
	float cloudLinearDepth = 1.0;

	#ifdef TEMPORAL_FILTER
		vec4 refAndCloudWrite = vec4(0.0);
	#endif

	if (z0 > 0.56) {
		#ifdef CLOUDS_ACTIVATE
			vec4 clouds = GetClouds(cloudLinearDepth, skyFade, playerPos, viewPos.xyz, lViewPos, VdotS, VdotU, dither);

			#if AURORA_STYLE > 0
				clouds.rgb += auroraBorealis * 0.1;
			#endif

			#ifndef TEMPORAL_FILTER
				color = mix(color, clouds.rgb, clouds.a);
			#else
				refAndCloudNew.rgb += clouds.rgb * clouds.a;
				refAndCloudNew.a = max(refAndCloudNew.a, clouds.a);
			#endif
		#endif

		#ifdef TEMPORAL_FILTER
			vec3 cameraOffset = cameraPosition - previousCameraPosition;
			vec2 prvCoord = Reprojection(playerPos, cameraOffset);
			vec4 refAndCloudOld = texture2D(colortex7, prvCoord);

			float blendFactor = float(prvCoord.x > 0.0 && prvCoord.x < 1.0 && prvCoord.y > 0.0 && prvCoord.y < 1.0);
			float velocity = length(cameraOffset) * max(16.0 - lViewPos / gbufferProjection[1][1], 3.0);
			blendFactor *= max(exp(-velocity) * 0.95, 0.5);

			for (int i = 0; i < 8; i++) {
				float depthCheck = texelFetch(depthtex0, texelCoord + neighbourhoodOffsets[i] * 4, 0).r;
				if (abs(GetLinearDepth(depthCheck) - GetLinearDepth(z0)) > 0.09) blendFactor = 0.0;
			}
			blendFactor *= min1(refAndCloudOld.a * 10000000.0);

			refAndCloudWrite = mix(refAndCloudNew, refAndCloudOld, blendFactor);

			color.rgb *= 1.0 - refAndCloudWrite.a;
			color.rgb += refAndCloudWrite.rgb;
		#endif
	}

	#if LIGHTSHAFT_BEHAVIOUR == 1 && LIGHTSHAFT_QUALITY > 0 && defined OVERWORLD && defined REALTIME_SHADOWS || defined END
		if (viewWidth + viewHeight - gl_FragCoord.x - gl_FragCoord.y < 1.5)
			cloudLinearDepth = vlFactor;
	#endif

	/*DRAWBUFFERS:054*/
    gl_FragData[0] = vec4(color, 1.0);
	gl_FragData[1] = vec4(waterRefColor, 1.0 - skyFade);
	gl_FragData[2] = vec4(cloudLinearDepth, 0.0, 0.0, 1.0);
	#ifdef TEMPORAL_FILTER
		/*DRAWBUFFERS:0547*/
		gl_FragData[3] = refAndCloudWrite;
	#endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

flat out vec3 upVec, sunVec;

#if LIGHTSHAFT_BEHAVIOUR == 1 && LIGHTSHAFT_QUALITY > 0 && defined OVERWORLD && defined REALTIME_SHADOWS || defined END
    flat out float vlFactor;
#endif

//Uniforms//
#if LIGHTSHAFT_BEHAVIOUR == 1 && LIGHTSHAFT_QUALITY > 0 && defined OVERWORLD && defined REALTIME_SHADOWS || defined END
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

	#if LIGHTSHAFT_BEHAVIOUR == 1 && LIGHTSHAFT_QUALITY > 0 && defined OVERWORLD && defined REALTIME_SHADOWS || defined END
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
