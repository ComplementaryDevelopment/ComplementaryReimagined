vec3 pos = vec3(0.0);
float dist = 0.0;
int sr = 0;

vec3 nViewPosR = reflect(nViewPos, normalM);
float RVdotU = dot(normalize(nViewPosR), upVec);
float RVdotS = dot(normalize(nViewPosR), sunVec);

vec3 start = viewPos.xyz;
vec3 vector = 0.5 * reflect(normalize(viewPos.xyz), normalize(normalM));
vec3 viewPosRT = viewPos.xyz + vector;
vec3 tvector = vector;

float lVectorPow = 1.1 + float(ssao > 0.9999) * 0.04;

vec3 rfragpos = vec3(0.0);
for(int i = 0; i < 30; i++) {
    pos = nvec3(gbufferProjection * nvec4(viewPosRT)) * 0.5 + 0.5;
    if (pos.x < -0.05 || pos.x > 1.05 || pos.y < -0.05 || pos.y > 1.05) break;

    rfragpos = vec3(pos.xy, texture2D(depthtex0, pos.xy).r);
    rfragpos = nvec3(gbufferProjectionInverse * nvec4(rfragpos * 2.0 - 1.0));
    dist = length(start - rfragpos);

    float dif = length(rfragpos) - length(viewPosRT);
    float err = min(abs(dif + 2.0), abs(dif));

    float lVector = pow(length(vector), lVectorPow);
    if (err < lVector) {
            sr++;
            if(sr >= 6) break;
            tvector -= vector;
            vector *= 0.1;
    }
    vector *= 2.0;
    tvector += vector * (dither * 0.05 + 0.95);
    viewPosRT = start + tvector;
}

float border = clamp(1.0 - pow(cdist(pos.xy), 50.0), 0.0, 1.0);

vec4 reflection = vec4(0.0);
if (pos.z < 0.9999) {
    reflection.a = border;
    if (reflection.a > 0.001) {
        float smoothnessDM = pow2(smoothnessD);
        float lodFactor = 1.0 - exp(-0.125 * (1.0 - smoothnessDM) * dist);
        float lod = log2(viewHeight / 8.0 * (1.0 - smoothnessDM) * lodFactor) * 0.45;
              lod = max(lod - 1.0, 0);
		//float check = float(texture2DLod(depthtex0, pos.st, 0).r < 0.9999);
        reflection.rgb = texture2DLod(colortex0, pos.xy, lod).rgb;
    }
}

if (reflection.a < 1.0) {
    #ifdef OVERWORLD
        vec3 skyReflection = GetSky(RVdotU, RVdotS, dither, false, true) * skyLightFactor;
    #elif defined END
        vec3 skyReflection = (endSkyColor + 0.4 * DrawEnderBeams(RVdotU, playerPos)) * skyLightFactor;
    #else
        vec3 skyReflection = vec3(0.0);
    #endif

    reflection.rgb = mix(skyReflection, reflection.rgb, reflection.a);
}

vec3 colorAdd = fresnelM * reflection.rgb * reflectColor;
float colorMultInv = fresnelM * (0.75 - intenseFresnel * 0.5) * max(reflection.a, skyLightFactor);

#ifndef TEMPORAL_FILTER
    color *= 1.0 - colorMultInv;
    color += colorAdd;
#else
    refAndCloudNew.rgb = colorAdd;
    refAndCloudNew.a = colorMultInv;
#endif