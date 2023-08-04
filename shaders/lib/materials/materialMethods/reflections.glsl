#ifdef OVERWORLD
    #include "/lib/atmospherics/sky.glsl"
#endif
#if defined END && defined DEFERRED1
    #include "/lib/atmospherics/enderBeams.glsl"
#endif

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec3 refPos = vec3(0.0);

vec4 GetReflection(vec3 normalM, vec3 viewPos, vec3 nViewPos, vec3 playerPos, float lViewPos, float z0,
                   sampler2D depthtex, float dither, float skyLightFactor, float fresnel,
                   float smoothness, vec3 geoNormal, vec3 color, vec3 shadowMult, float highlightMult) {
    vec3 rfragpos = vec3(0.0);
    float dist = 0.0;
    int sr = 0;
    vec2 rEdge = vec2(0.6, 0.53);
    vec3 normalMR = normalM;

    #if defined GBUFFERS_WATER && defined GENERATED_NORMALS && WATER_STYLE == 1
        normalMR = mix(geoNormal, normalM, 0.05);
    #endif

    vec3 nViewPosR = reflect(nViewPos, normalMR);
    float RVdotU = dot(normalize(nViewPosR), upVec);
    float RVdotS = dot(normalize(nViewPosR), sunVec);

    vec3 start = viewPos + normalMR * (lViewPos * 0.025 * (1.0 - fresnel) + 0.05);
    vec3 vector = reflect(nViewPos, normalize(normalMR));
    vector *= 0.5;
    vec3 viewPosRT = viewPos + vector;
    vec3 tvector = vector;

    for(int i = 0; i < 30; i++) {
        refPos = nvec3(gbufferProjection * vec4(viewPosRT, 1.0)) * 0.5 + 0.5;
        if (abs(refPos.x - 0.5) > rEdge.x || abs(refPos.y - 0.5) > rEdge.y) break;

        rfragpos = vec3(refPos.xy, texture2D(depthtex, refPos.xy).r);
        rfragpos = nvec3(gbufferProjectionInverse * vec4(rfragpos * 2.0 - 1.0, 1.0));
        dist = length(start - rfragpos);

        float err = length(viewPosRT - rfragpos);
        
		if (err < length(vector) * 3.0) {
            sr++;
            if (sr >= 6) break;
            tvector -= vector;
            vector *= 0.1;
        }
        vector *= 2.0;
        tvector += vector * (0.95 + 0.1 * dither);
        viewPosRT = start + tvector;
    }

    vec2 absPos = abs(refPos.xy - 0.5);
    vec2 cdist = absPos / rEdge;
    float border = clamp(1.0 - pow(max(cdist.x, cdist.y), 50.0), 0.0, 1.0);

    vec4 reflection = vec4(0.0);
    if (refPos.z < 0.99997) {
        reflection.a = border;

        float lViewPosRT = length(rfragpos);

        if (reflection.a > 0.001) {
            vec2 edgeFactor = pow2(pow2(pow2(cdist)));
            refPos.y += (dither - 0.5) * (0.05 * (edgeFactor.x + edgeFactor.y));

            #ifdef DEFERRED1
                float smoothnessDM = pow2(smoothness);
                float lodFactor = 1.0 - exp(-0.125 * (1.0 - smoothnessDM) * dist);
                float lod = log2(viewHeight / 8.0 * (1.0 - smoothnessDM) * lodFactor) * 0.45;
				#ifdef CUSTOM_PBR
					if (z0 <= 0.56) lod *= 2.22;
                #endif
                lod = max(lod - 1.0, 0.0);

                reflection.rgb = texture2DLod(colortex0, refPos.xy, lod).rgb;
            #else
                reflection = texture2D(gaux2, refPos.xy);
                reflection.rgb = pow2(reflection.rgb + 1.0);
            #endif

            /**/
	        float skyFade = 0.0;
	        DoFog(reflection.rgb, skyFade, lViewPosRT, ViewToPlayer(rfragpos.xyz), RVdotU, RVdotS, dither);

            edgeFactor.x = pow2(edgeFactor.x);
            edgeFactor = 1.0 - edgeFactor;
            reflection.a *= pow(edgeFactor.x * edgeFactor.y, 2.0 + 3.0 * GetLuminance(reflection.rgb));
        }

        float posDif = lViewPosRT - lViewPos;
        reflection.a *= clamp(posDif + 3.0, 0.0, 1.0);
    }
    #if defined DEFERRED1 && defined TEMPORAL_FILTER
        else refPos.z = 1.0;
    #endif

    if (reflection.a < 1.0) {
        #ifdef OVERWORLD
            vec3 skyReflection = GetSky(RVdotU, RVdotS, dither, true, true);

            /**/
            vec3 vlColorApprox = pow(lightColor, vec3(0.8)) * 0.6;
            skyReflection += vlColorApprox * rainFactor2;

            #ifdef ATM_COLOR_MULTS
                skyReflection *= atmColorMult;
            #endif
            
            #ifdef DEFERRED1
                skyReflection *= skyLightFactor;
            #else
                skyReflection = mix(color * 0.5, skyReflection, skyLightFactor);

                float specularHighlight = GGX(normalM, nViewPos, lightVec, max(dot(normalM, lightVec), 0.0), smoothness);
                skyReflection += specularHighlight * highlightColor * shadowMult * highlightMult * invRainFactor;
            #endif
        #elif defined END
            #ifdef DEFERRED1
                vec3 skyReflection = (endSkyColor + 0.4 * DrawEnderBeams(RVdotU, playerPos)) * skyLightFactor;
            #else
                vec3 skyReflection = endSkyColor * shadowMult;
            #endif

            #ifdef ATM_COLOR_MULTS
                skyReflection *= atmColorMult;
            #endif
        #else
            vec3 skyReflection = vec3(0.0);
        #endif

        reflection.rgb = mix(skyReflection, reflection.rgb, reflection.a);
    }

    return reflection;
}