bool intersectsAABB(vec3 ro, vec3 rd, vec3 aabbMin, vec3 aabbMax) {
    vec3 t0 = (aabbMin - ro) / rd;
    vec3 t1 = (aabbMax - ro) / rd;

    vec3 tMin = min(t0, t1);
    vec3 tMax = max(t0, t1);

    float m0 = max(max(tMin.x, tMin.y), tMin.z);
    float m1 = min(min(tMax.x, tMax.y), tMax.z);

    return m1 > max0(m0);
}

bool intersectsParallelogram(vec3 ro, vec3 rd, vec3 v0, vec3 v1, vec3 v2, float tMin, out float t, out vec2 uv, inout vec3 normal) {
    vec3 a = v1 - v0, n = cross(a, v2 - v0);

    t = dot(v0 - ro, n) / dot(n, rd);
    if (t < 0.0 || t > tMin) return false;

    vec3 b = v2 - v1;
    vec3 c = ro + rd * t  - v0;

    uv = vec2(dot(c, a) / dot(a, a), dot(c, b) / dot(b, b));
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return false;

    normal = normalize(n);
    return true;
}

void CheckQuadAt(int i, vec3 playerPos, vec3 rayDir, inout vec3 albedo, inout float tMin, inout vec3 normal) {
    int i0 = 3 * i, i1 = 3 * i + 1, i2 = 3 * i + 2;

    vec3 v0 = playerVerticesSSBO.vertexPositions[i0];
    vec3 v1 = playerVerticesSSBO.vertexPositions[i1];
    vec3 v2 = playerVerticesSSBO.vertexPositions[i2];

    float t;
    vec2 uv;
    if (intersectsParallelogram(playerPos, rayDir, v0, v1, v2, tMin, t, uv, normal)) {
        vec2 texCoord0 = playerVerticesSSBO.vertexData[i0];
        vec2 texCoord1 = playerVerticesSSBO.vertexData[i1];
        vec2 texCoord2 = playerVerticesSSBO.vertexData[i2];

        vec2 quadTexCoord = mix(texCoord0, texCoord1, uv.x) + uv.y * (texCoord2 - texCoord1);
        vec4 playerAtlasSample = texelFetch(playerAtlas_sampler, ivec2(64 * quadTexCoord), 0);

        if (playerAtlasSample.a > 0.2) {albedo = playerAtlasSample.rgb; tMin = t;}
    }
}

bool rayTracePlayer(vec3 playerPos, vec3 rayDir, float wsrTraceLength, out vec3 albedo, out vec3 normal) {
    float tMin = wsrTraceLength;
    vec3 aabbPos = playerPos * 1000.0;

    // Head
    if (intersectsAABB(aabbPos, rayDir, playerVerticesSSBO.bounds.headMin, playerVerticesSSBO.bounds.headMax)) {
        for (int i = 0; i < 12; i++) {
            CheckQuadAt(i, playerPos, rayDir, albedo, tMin, normal);
        }
    }
    // Right Hand
    if (intersectsAABB(aabbPos, rayDir, playerVerticesSSBO.bounds.rightHandMin, playerVerticesSSBO.bounds.rightHandMax)) {
        for (int i = 12; i < 24; i++) {
            CheckQuadAt(i, playerPos, rayDir, albedo, tMin, normal);
        }
    }
    // Left Leg
    if (intersectsAABB(aabbPos, rayDir, playerVerticesSSBO.bounds.leftLegMin, playerVerticesSSBO.bounds.leftLegMax)) {
        for (int i = 24; i < 36; i++) {
            CheckQuadAt(i, playerPos, rayDir, albedo, tMin, normal);
        }
    }
    // Left Hand
    if (intersectsAABB(aabbPos, rayDir, playerVerticesSSBO.bounds.leftHandMin, playerVerticesSSBO.bounds.leftHandMax)) {
        for (int i = 36; i < 48; i++) {
            CheckQuadAt(i, playerPos, rayDir, albedo, tMin, normal);
        }
    }
    // Right leg
    if (intersectsAABB(aabbPos, rayDir, playerVerticesSSBO.bounds.rightLegMin, playerVerticesSSBO.bounds.rightLegMax)) {
        for (int i = 48; i < 60; i++) {
            CheckQuadAt(i, playerPos, rayDir, albedo, tMin, normal);
        }
    }
    // Torso
    if (intersectsAABB(aabbPos, rayDir, playerVerticesSSBO.bounds.torsoMin, playerVerticesSSBO.bounds.torsoMax)) {
        for (int i = 60; i < 72; i++) {
            CheckQuadAt(i, playerPos, rayDir, albedo, tMin, normal);
        }
    }
    
    return tMin < wsrTraceLength;
}