// GGX area light approximation from Horizon Zero Dawn
float GetNoHSquared(float radiusTan, float NoL, float NoV, float VoL) {
    float radiusCos = 1.0 / sqrt(1.0 + radiusTan * radiusTan);
    
    float RoL = 2.0 * NoL * NoV - VoL;
    if (RoL >= radiusCos)
        return 1.0;

    float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    float triple = sqrt(clamp(1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL, 0.0, 1.0));
    
    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;    
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * p + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr + 
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    VoTr = cosTheta * VoTr + sinTheta * VoBr;
    
    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;
    return clamp(NoH * NoH / HoH, 0.0, 1.0);
}

float GGX(vec3 normalM, vec3 viewPos, vec3 lightVec, float NdotLmax0, float smoothnessG) {
    smoothnessG = sqrt1(smoothnessG * 0.9 + 0.1);
    float roughnessP = (1.35 - smoothnessG);
    float roughness = pow2(pow2(roughnessP));
    
    vec3 halfVec = normalize(lightVec - viewPos);

    float dotLH = clamp(dot(halfVec, lightVec), 0.0, 1.0);
    float dotNV = dot(normalM, -viewPos);
    
    #if REFLECTION_QUALITY >= 2
        float dotNH = GetNoHSquared(0.01, NdotLmax0, dotNV, dot(-viewPos, lightVec));
    #else
        float dotNH = pow2(min1(2.0 * NdotLmax0 * dotNV * length(halfVec) - dot(-viewPos, lightVec)));
    #endif
    
    float denom = dotNH * roughness - dotNH + 1.0;
    float D = roughness / (3.141592653589793 * denom * denom);
    float f0 = 0.05;
    float F = exp2((-5.55473 * dotLH - 6.98316) * dotLH) * (1.0 - f0) + f0;

    float NdotLmax0M = sqrt3(NdotLmax0 * max(dot(normal, lightVec), 0.0));
    float specular = max(NdotLmax0M * D * F / pow2(dotLH), 0.0);
    specular = max(specular, 0.0);
    specular = specular / (0.125 * specular + 1.0);

    specular *= sqrt1(NdotLmax0);

    return specular;
}