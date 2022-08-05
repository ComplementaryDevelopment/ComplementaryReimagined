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

vec4 GetVolumetricLight(inout float vlFactor, vec3 translucentMult, float lViewPos, vec3 nViewPos, float VdotL, float VdotU, vec2 texCoord, float z0, float z1, float dither) {
	if (max(blindness, darknessFactor) > 0.1) return vec4(0.0);
	vec4 volumetricLight = vec4(0.0);

	#ifdef OVERWORLD
		float vlSceneIntensity = isEyeInWater != 1 ? vlFactor : 1.0;

		if (sunVisibility < 0.5) vlSceneIntensity = 0.0;
	#else
		float vlSceneIntensity = 0.0;
	#endif

	#ifdef OVERWORLD
		float VdotLM = max((VdotL + 1.0) / 2.0, 0.0);
		float VdotUM = mix(pow2(1.0 - max(VdotU, 0.0)), 1.0, 0.5 * vlSceneIntensity);
		      VdotUM = smoothstep1(VdotUM);
			  VdotUM = pow(VdotUM, min(lViewPos / far, 1.0) * (3.0 - 2.0 * vlSceneIntensity));
		float vlMult = mix(VdotUM * VdotLM, 0.5 + 0.5 * VdotLM, rainFactor2) * vlTime;
			  vlMult *= mix(invNoonFactor * 0.875 + 0.125, 1.0, max(vlSceneIntensity, rainFactor2));
			  vlMult *= mix(0.4, 1.0, max(sunVisibility, invRainFactor));
	#endif

	#ifdef OVERWORLD
		#if LIGHTSHAFT_QUALITY == 4
			int sampleCount = vlSceneIntensity < 0.5 ? 30 : 50;
		#elif LIGHTSHAFT_QUALITY == 3
			int sampleCount = vlSceneIntensity < 0.5 ? 15 : 30;
		#elif LIGHTSHAFT_QUALITY == 2
			int sampleCount = vlSceneIntensity < 0.5 ? 10 : 20;
		#elif LIGHTSHAFT_QUALITY == 1
			int sampleCount = vlSceneIntensity < 0.5 ? 6 : 12;
		#endif
		#ifndef TAA
			sampleCount *= 2;
		#endif
	#else
		int sampleCount = 16;
	#endif
	float addition = 1.0;
	float maxDist = mix(max(far, 96.0) * 0.55, 80.0, vlSceneIntensity);
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
		//if (volumetricLight.a >= 1.0) break;

		vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, GetDistX(currentDist), 1.0) * 2.0 - 1.0);
		viewPos /= viewPos.w;
		vec4 wpos = gbufferModelViewInverse * viewPos;
		#ifdef END
			vec3 playerPos = wpos.xyz / wpos.w;
			vec4 enderBeamSample = vec4(DrawEnderBeams(VdotU, playerPos), 1.0) / sampleCount;
		#endif
		wpos = shadowModelView * wpos;
		wpos = shadowProjection * wpos;
		wpos /= wpos.w;
		float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
		float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
		vec4 shadowPosition = DistortShadow(wpos,distortFactor);
		shadowPosition.z += 0.0001;
		
		#ifdef OVERWORLD
			float percentComplete = currentDist / maxDist;
			float sampleMult = mix(percentComplete * 3.0, sampleMultIntense, max(rainFactor, vlSceneIntensity));
			if (currentDist < 5.0) sampleMult *= smoothstep1(clamp(currentDist / 5.0, 0.0, 1.0));
			sampleMult /= sampleCount;
		#endif

		float shadowSample = 1.0;
		vec3 vlSample = vec3(1.0);
		if (length(shadowPosition.xy * 2.0 - 1.0) < 1.0) {
			shadowSample = shadow2D(shadowtex0, shadowPosition.xyz).z;
			vlSample = vec3(shadowSample);

			if (shadowSample == 0.0) {
				float testsample = shadow2D(shadowtex1, shadowPosition.xyz).z;
				if (testsample == 1.0) {
					vec3 colsample = texelFetch(shadowcolor1, ivec2(shadowPosition.xy * shadowMapResolution), 0).rgb * 4.0;
					colsample *= colsample;
					vlSample = colsample * (1.0 - vlSample) + vlSample;
				}
			} else if (isEyeInWater == 1 && translucentMult == vec3(1.0)) vlSample = vec3(0.0);
		}
		
		if (currentDist > depth0) vlSample *= translucentMult;

		#ifdef OVERWORLD
			volumetricLight += vec4(vlSample, shadowSample) * sampleMult;
		#else
			volumetricLight += vec4(vlSample, shadowSample) * enderBeamSample;
		#endif
	}

	#if defined OVERWORLD && defined SCENE_AWARE_LIGHT_SHAFTS
		if (viewWidth + viewHeight - gl_FragCoord.x - gl_FragCoord.y < 1.5) {
			if (frameCounter % int(0.06666 / frameTimeSmooth + 0.5) == 0) { // Change speed is not too different above 10 fps
				vec4 wpos = vec4(shadowModelView[3][0], shadowModelView[3][1], shadowModelView[3][2], shadowModelView[3][3]);
				wpos = shadowProjection * wpos;
				wpos /= wpos.w;
				vec4 shadowPosition = DistortShadow(wpos, 1.0 - shadowMapBias);
				shadowPosition.z -= 0.0005;
				float shadowSample = shadow2D(shadowtex0, shadowPosition.xyz).z;
				if (shadowSample > 0.5 || eyeBrightness.y > 180) vlFactor = max(vlFactor - OSIEBCA*3, 0.0);
				else                                             vlFactor = min(vlFactor + OSIEBCA*2, 1.0);
			}
		} else vlFactor = 0.0;
	#endif

	#ifdef OVERWORLD
		volumetricLight.rgb *= vlMult * pow(lightColor, vec3(0.5 + 0.5 * max(invNoonFactor, (1.0 + sunFactor) * rainFactor)));
	#else
		//if (gl_FragCoord.x > 960) volumetricLight.rgb = max(volumetricLight.rgb - dither / 255.0, vec3(0.0));
	#endif
	
	volumetricLight = clamp(volumetricLight, vec4(0.0), vec4(1.0));

	return volumetricLight;
}