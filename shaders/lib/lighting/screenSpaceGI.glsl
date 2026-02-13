/*
    Screen-Space Global Illumination (SSGI) / Ray-Traced Indirect Lighting
    Approximates path-traced indirect diffuse lighting using screen-space ray marching.
    Traces rays from each fragment in random hemisphere directions to gather
    indirect light bounces from nearby surfaces visible on screen.
*/

vec3 CosWeightedHemisphereDir(vec3 normal, float xi1, float xi2) {
    float r = sqrt(xi1);
    float phi = 6.28318530718 * xi2;

    vec3 sampleDir = vec3(
        r * cos(phi),
        r * sin(phi),
        sqrt(max(1.0 - xi1, 0.0))
    );

    vec3 up = abs(normal.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent = normalize(cross(up, normal));
    vec3 bitangent = cross(normal, tangent);

    return tangent * sampleDir.x + bitangent * sampleDir.y + normal * sampleDir.z;
}

float DoScreenSpaceGlobalIllumination(
    vec3 viewPos, vec3 normalM, float z0, float linearZ0, float dither,
    out vec3 giColor
) {
    giColor = vec3(0.0);

    if (z0 < 0.56 || z0 > 0.9999) return 0.0;

    #if RT_SUNLIGHT_QUALITY == 1
        const int samples = 2;
        const int steps = 6;
    #elif RT_SUNLIGHT_QUALITY == 2
        const int samples = 3;
        const int steps = 8;
    #else
        const int samples = 4;
        const int steps = 12;
    #endif

    float radius = RT_GI_RADIUS;
    float invSteps = 1.0 / float(steps);
    float thicknessThreshold = radius * 0.15 * invSteps;
    float totalWeight = 0.0;
    vec3 totalGI = vec3(0.0);

    for (int i = 0; i < samples; i++) {
        float xi1 = fract(dither + float(i) * 0.618033988);
        float xi2 = fract(dither * 1.414 + float(i) * 0.381966);

        vec3 sampleDir = CosWeightedHemisphereDir(normalM, xi1, xi2);
        vec3 viewDir = mat3(gbufferModelView) * sampleDir;
        float viewDirLen = length(viewDir);
        if (viewDirLen < 0.001) continue;
        viewDir /= viewDirLen;

        vec3 rayStep = viewDir * (radius * invSteps);
        vec3 rayPos = viewPos + rayStep;

        for (int j = 1; j <= steps; j++) {
            vec4 projPos = gbufferProjection * vec4(rayPos, 1.0);
            vec3 screenPos = projPos.xyz / projPos.w * 0.5 + 0.5;

            if (clamp(screenPos.xy, vec2(0.0), vec2(1.0)) != screenPos.xy) break;

            float sampleDepth = texelFetch(depthtex0, ivec2(screenPos.xy * vec2(viewWidth, viewHeight)), 0).r;
            float sampleLinear = (2.0 * near) / (far + near - sampleDepth * farMinusNear);
            float rayLinear = (2.0 * near) / (far + near - screenPos.z * farMinusNear);

            float depthDiff = rayLinear - sampleLinear;

            if (depthDiff > 0.0 && depthDiff < thicknessThreshold) {
                vec3 hitColor = texelFetch(colortex0, ivec2(screenPos.xy * vec2(viewWidth, viewHeight)), 0).rgb;
                float dist = float(j) * invSteps;
                float falloff = 1.0 - dist * dist;
                totalGI += hitColor * falloff;
                totalWeight += falloff;
                break;
            }

            rayPos += rayStep;
        }
    }

    if (totalWeight > 0.0) {
        giColor = totalGI / totalWeight;
        giColor = min(giColor, vec3(2.0));
        return 1.0;
    }

    return 0.0;
}
