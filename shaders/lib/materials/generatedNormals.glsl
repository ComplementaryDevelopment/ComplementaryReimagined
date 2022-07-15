const float normalThreshold = 0.05;
const float packSizeGN = 128.0;

float GetDif(float lOriginalAlbedo, vec2 offsetCoord) {
    #ifndef GBUFFERS_WATER
        float lNearbyAlbedo = length(texture2D(texture, offsetCoord).rgb);    
    #else
        vec4 textureSample = texture2D(texture, offsetCoord);
        float lNearbyAlbedo = length(textureSample.rgb * textureSample.a * 1.5);
    #endif
    float dif = lOriginalAlbedo - lNearbyAlbedo;
    if (dif > 0.0) dif = max(dif - normalThreshold, 0.0);
    else           dif = min(dif + normalThreshold, 0.0);
    return dif;
}

void GenerateNormals(inout vec3 normalM, vec3 color) {
    vec2 absMidCoordPos2 = absMidCoordPos * 2.0;

    float lOriginalAlbedo = length(color.rgb);
    float normalMult = max0(1.0 - mipDelta) * 1.5;

    #ifndef SAFER_GENERATED_NORMALS
        vec2 offsetR = 16.0 / atlasSize;
    #else
        vec2 offsetR = max(absMidCoordPos2.x, absMidCoordPos2.y) * vec2(float(atlasSize.y) / float(atlasSize.x), 1.0);
    #endif
    offsetR /= packSizeGN;

    vec2 midCoord = texCoord - midCoordPos;
    vec2 maxOffsetCoord = midCoord + absMidCoordPos;
    vec2 minOffsetCoord = midCoord - absMidCoordPos;
    if (normalMult > 0.0) {
	    vec3 normalMap = vec3(0.0, 0.0, 1.0);

        vec2 offsetCoord = texCoord + vec2( 0.0, offsetR.y);
        if (offsetCoord.y < maxOffsetCoord.y) 
            normalMap.y += GetDif(lOriginalAlbedo, offsetCoord);

        offsetCoord = texCoord + vec2( offsetR.x, 0.0);
        if (offsetCoord.x < maxOffsetCoord.x) 
            normalMap.x += GetDif(lOriginalAlbedo, offsetCoord);

        offsetCoord = texCoord + vec2( 0.0,-offsetR.y);
        if (offsetCoord.y > minOffsetCoord.y) 
            normalMap.y -= GetDif(lOriginalAlbedo, offsetCoord);
            
        offsetCoord = texCoord + vec2(-offsetR.x, 0.0);
        if (offsetCoord.x > minOffsetCoord.x) 
            normalMap.x -= GetDif(lOriginalAlbedo, offsetCoord);
        
        normalMap.xy *= normalMult;

        mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
                              tangent.y, binormal.y, normal.y,
                              tangent.z, binormal.z, normal.z);

        if (normalMap.xy != vec2(0.0, 0.0))
            normalM = clamp(normalize(normalMap.xyz * tbnMatrix), vec3(-1.0), vec3(1.0));
    }
}