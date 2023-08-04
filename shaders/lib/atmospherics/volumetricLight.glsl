// Volumetric tracing from Robobo1221, highly modified

#include "/lib/colors/lightAndAmbientColors.glsl"

float GetDepth(float depth) {
	return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float GetDistX(float dist) {
	return (far * (dist - near)) / (dist * (far - near));
}

vec4 DistortShadow(vec4 shadowpos, float distortFactor) {
	shadowpos.xy *= 1.0 / distortFactor;
	shadowpos.z = shadowpos.z * 0.2;
	shadowpos = shadowpos * 0.5 + 0.5;

	return shadowpos;
}

vec4 GetVolumetricLight(inout vec3 color, inout float vlFactor, vec3 translucentMult, float lViewPos, vec3 nViewPos, float VdotL, float VdotU, vec2 texCoord, float z0, float z1, float dither) {
	if (max(blindness, darknessFactor) > 0.1) return vec4(0.0);
	vec4 volumetricLight = vec4(0.0);

	// For some reason Optifine doesn't provide correct shadowMapResolution if Shadow Quality isn't 1x
	vec2 shadowMapResolutionM = textureSize(shadowtex0, 0);

	#ifdef OVERWORLD
		vec3 vlColor = lightColor;
		vec3 vlColorReducer = vec3(1.0);
		float vlSceneIntensity = isEyeInWater != 1 ? vlFactor : 1.0;
		float vlMult = 1.0;

		if (sunVisibility < 0.5) {
			vlSceneIntensity = 0.0;
			vlMult = 0.6 + 0.4 * max0(far - lViewPos) / far;
			vlColor = normalize(pow(vlColor, vec3(1.0 - max0(1.0 - 1.5 * nightFactor))));
			vlColor *= 0.0766 + 0.0766 * vsBrightness;
		} else {
			vlColorReducer = 1.0 / sqrt(vlColor);
		}

		float VdotLM = max((VdotL + 1.0) / 2.0, 0.0);
		float VdotUmax0 = max(VdotU, 0.0);
		float VdotUM = mix(pow2(1.0 - VdotUmax0), 1.0, 0.5 * vlSceneIntensity);
		      VdotUM = smoothstep1(VdotUM);
			  VdotUM = pow(VdotUM, min(lViewPos / far, 1.0) * (3.0 - 2.0 * vlSceneIntensity));
		vlMult *= mix(VdotUM * VdotLM, 0.5 + 0.5 * VdotLM, rainFactor2) * vlTime;
		vlMult *= mix(pow2(invNoonFactor) * 0.875 + 0.125, 1.0, max(vlSceneIntensity, rainFactor2));
		vlMult *= mix(0.25, 1.0, max(sunVisibility, invRainFactor));

		#if LIGHTSHAFT_QUALI == 4
			int sampleCount = vlSceneIntensity < 0.5 ? 30 : 50;
		#elif LIGHTSHAFT_QUALI == 3
			int sampleCount = vlSceneIntensity < 0.5 ? 15 : 30;
		#elif LIGHTSHAFT_QUALI == 2
			int sampleCount = vlSceneIntensity < 0.5 ? 10 : 20;
		#elif LIGHTSHAFT_QUALI == 1
			int sampleCount = vlSceneIntensity < 0.5 ? 6 : 12;
		#endif
		#ifndef TAA
			sampleCount *= 2;
		#endif
	#else
		float vlSceneIntensity = 0.0;

		#if LIGHTSHAFT_QUALI == 4
			int sampleCount = 20;
		#elif LIGHTSHAFT_QUALI == 3
			int sampleCount = 16;
		#elif LIGHTSHAFT_QUALI == 2
			int sampleCount = 12;
		#elif LIGHTSHAFT_QUALI == 1
			int sampleCount = 10;
		#elif LIGHTSHAFT_QUALI == 0
			int sampleCount = 8;
		#endif
	#endif

	float addition = 1.0;
	float maxDist = mix(max(far, 96.0) * 0.55, 80.0, vlSceneIntensity);

	#if WATER_FOG_MULT != 100
		if (isEyeInWater == 1) {
			#define WATER_FOG_MULT_M WATER_FOG_MULT * 0.01;
			maxDist /= WATER_FOG_MULT_M;
		}
	#endif

	float distMult = maxDist / (sampleCount + addition);
	float sampleMultIntense = isEyeInWater != 1 ? 1.0 : 0.85;

	float depth0 = GetDepth(z0);
	float depth1 = GetDepth(z1);
	#ifdef END
		if (z0 == 1.0) depth0 = 1000.0;
		if (z1 == 1.0) depth1 = 1000.0;
	#endif

	// Fast but inaccurate perspective distortion approximation
	float viewFactor = 1.0 - 0.7 * pow2(dot(nViewPos.xy, nViewPos.xy));
	maxDist *= viewFactor;
	distMult *= viewFactor;
	
	#ifdef OVERWORLD
		float maxCurrentDist = min(depth1, maxDist);
	#else
		float maxCurrentDist = min(depth1, far);
	#endif

	for (int i = 0; i < sampleCount; i++) {
		float currentDist = (i + dither) * distMult + addition;

		if (currentDist > maxCurrentDist) break;

		vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, GetDistX(currentDist), 1.0) * 2.0 - 1.0);
		viewPos /= viewPos.w;
		vec4 wpos = gbufferModelViewInverse * viewPos;
		vec3 playerPos = wpos.xyz / wpos.w;
		#ifdef END
			vec4 enderBeamSample = vec4(DrawEnderBeams(VdotU, playerPos), 1.0);
			enderBeamSample /= sampleCount;
		#endif
		
		float shadowSample = 1.0;
		vec3 vlSample = vec3(1.0);
		#ifdef REALTIME_SHADOWS
			wpos = shadowModelView * wpos;
			wpos = shadowProjection * wpos;
			wpos /= wpos.w;
			float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
			float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
			vec4 shadowPosition = DistortShadow(wpos,distortFactor);
			//shadowPosition.z += 0.0001;
			
			#ifdef OVERWORLD
				float percentComplete = currentDist / maxDist;
				float sampleMult = mix(percentComplete * 3.0, sampleMultIntense, max(rainFactor, vlSceneIntensity));
				if (currentDist < 5.0) sampleMult *= smoothstep1(clamp(currentDist / 5.0, 0.0, 1.0));
				sampleMult /= sampleCount;
			#endif

			if (length(shadowPosition.xy * 2.0 - 1.0) < 1.0) {
				// 28A3DK6 We need to use texelFetch here or a lot of Nvidia GPUs can't get a valid value
				shadowSample = texelFetch(shadowtex0, ivec2(shadowPosition.xy * shadowMapResolutionM), 0).x;
				shadowSample = clamp((shadowSample-shadowPosition.z)*65536.0,0.0,1.0);
				vlSample = vec3(shadowSample);

				#if SHADOW_QUALITY >= 1
					if (shadowSample == 0.0) {
						float testsample = shadow2D(shadowtex1, shadowPosition.xyz).z;
						if (testsample == 1.0) {
							vec3 colsample = texture2D(shadowcolor1, shadowPosition.xy).rgb * 4.0;
							colsample *= colsample;
							vlSample = colsample * (1.0 - vlSample) + vlSample;
							#ifdef OVERWORLD
								vlSample *= vlColorReducer;
							#endif
						}
					} else {
						// For water-tinting the water surface when observed from below the surface
						if (translucentMult != vec3(1.0) && currentDist > depth0) {
							if (isEyeInWater == 1) {
								vec3 translucentMultM = translucentMult * 2.8;
								vlSample *= pow(translucentMultM, vec3(sunVisibility * 3.0 * clamp01(playerPos.y * 0.03)));
							} else {
								vlSample *= 0.1 + 0.9 * pow2(pow2(translucentMult * 1.7));
							}
						}
						
						if (isEyeInWater == 1 && translucentMult == vec3(1.0)) vlSample = vec3(0.0);
					}
				#endif
			}
		#endif
		
		if (currentDist > depth0) vlSample *= translucentMult;

		#ifdef OVERWORLD
			volumetricLight += vec4(vlSample, shadowSample) * sampleMult;
		#else
			volumetricLight += vec4(vlSample, shadowSample) * enderBeamSample;
		#endif
	}

	#if defined OVERWORLD && LIGHTSHAFT_BEHAVIOUR == 1
		if (viewWidth + viewHeight - gl_FragCoord.x - gl_FragCoord.y < 1.5) {
			if (frameCounter % int(0.06666 / frameTimeSmooth + 0.5) == 0) { // Change speed is not too different above 10 fps
				int salsX = 5;
				int salsY = 5;
				vec2 viewM = 1.0 / vec2(salsX, salsY);
				float salsSampleSum = 0.0;
				int salsSampleCount = 0;
				for (float i = 0.25; i < salsX; i++) {
					for (float h = 0.45; h < salsY; h++) {
						vec2 coord = 0.3 + 0.4 * viewM * vec2(i, h);
						//float salsSample = texture2D(shadowtex0, coord).x;
						float salsSample = texelFetch(shadowtex0, ivec2(coord * shadowMapResolutionM), 0).x; // read 28A3DK6
						if (salsSample < 0.55) {
							vec3 salsShadowNDC = vec3(coord, salsSample) * 2.0 - 1.0;
							salsShadowNDC.z /= 0.2;
								float distb = sqrt(salsShadowNDC.x * salsShadowNDC.x + salsShadowNDC.y * salsShadowNDC.y);
								float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
								salsShadowNDC.xy *= distortFactor;

							vec4 salsShadowViewPos = shadowProjectionInverse * vec4(salsShadowNDC, 1.0);
							salsShadowViewPos.xyz /= salsShadowViewPos.w;
							salsSampleSum += (shadowModelViewInverse * vec4(salsShadowViewPos.xyz, 1.0)).y;
							salsSampleCount++;
						}
					}
				}

				float salsCheck = salsSampleSum / salsSampleCount;
				int reduceAmount = 2;
				
				int skyCheck = 0;
				for (float i = 0.1; i < 1.0; i += 0.2) {
					skyCheck += int(texelFetch(depthtex0, ivec2(view.x * i, view.y * 0.9), 0).x == 1.0);
				}
				if (skyCheck >= 4) {
					salsCheck = 0.0;
					reduceAmount = 3;
				}

				if (salsCheck > 7.0) {
					vlFactor = min(vlFactor + OSIEBCA, 1.0);
				} else {
					vlFactor = max(vlFactor - OSIEBCA * reduceAmount, 0.0);
				}
			}
		} else vlFactor = 0.0;

		/*beginTextM(8, vec2(6, 10));
		text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
		printFloat(salsCheck);
		endText(color);
		
		for (float i = 0.25; i < salsX; i++) {
			for (float h = 0.45; h < salsY; h++) {
				if (length(texCoord - (0.3 + 0.4 * viewM * vec2(i, h))) < 0.01) return vec4(1,0,1,1);
			}
		}*/
	#endif

	#ifdef OVERWORLD
		volumetricLight.rgb *= vlMult * pow(vlColor, vec3(0.5 + 0.5 * mix(invNoonFactor, (1.0 + sunFactor), rainFactor)));

		#if LIGHTSHAFT_DAY_I != 100 || LIGHTSHAFT_NIGHT_I != 100
			#define LIGHTSHAFT_DAY_IM LIGHTSHAFT_DAY_I * 0.01
			#define LIGHTSHAFT_NIGHT_IM LIGHTSHAFT_NIGHT_I * 0.01
			volumetricLight.rgb *= mix(LIGHTSHAFT_NIGHT_IM, LIGHTSHAFT_DAY_IM, sunVisibility);
		#endif

		#if LIGHTSHAFT_RAIN_I != 100
			#define LIGHTSHAFT_RAIN_IM LIGHTSHAFT_RAIN_I * 0.01
			volumetricLight.rgb *= mix(1.0, LIGHTSHAFT_RAIN_IM, rainFactor);
		#endif
	#endif
	
	volumetricLight = max(volumetricLight, vec4(0.0));
	volumetricLight.a = min(volumetricLight.a, 1.0);

	return volumetricLight;
}