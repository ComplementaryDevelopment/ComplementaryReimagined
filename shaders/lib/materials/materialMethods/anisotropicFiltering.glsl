/*
    This file is specifically licensed with Mozilla Public License Version 2.0.
    You can get a copy from https://www.mozilla.org/MPL/2.0/
*/

float manualDeterminant(mat2 matrix) {
    return matrix[0].x * matrix[1].y - matrix[0].y * matrix[1].x;
}

mat2 inverseM(mat2 m) {
    #if MC_VERSION >= 11700
        return inverse(m);
    #else
        mat2 adj;
        adj[0][0] = m[1][1];
        adj[0][1] = -m[0][1];
        adj[1][0] = -m[1][0];
        adj[1][1] = m[0][0];
        return adj / manualDeterminant(m);
    #endif
}

vec4 textureAF(sampler2D texSampler, vec2 uv) {
    vec2 spriteDimensions = vec2(spriteBounds.z - spriteBounds.x, spriteBounds.w - spriteBounds.y);

    mat2 J = inverseM(mat2(dFdx(uv), dFdy(uv)));
    J = transpose(J)*J;
    float d = manualDeterminant(J), t = J[0][0]+J[1][1],
          D = sqrt(abs(t*t-4.001*d)), // using 4.001 instead of 4.0 fixes a rare texture glitch with square texture atlas
          V = (t-D)/2.0, v = (t+D)/2.0,
          M = 1.0/sqrt(V), m = 1./sqrt(v);
    vec2 A = M * normalize(vec2(-J[0][1], J[0][0]-V));

    float lod = 0.0;
    #if ANISOTROPIC_FILTER >= 8 && defined GBUFFERS_TERRAIN
        // Fix257062 - Checking if absMidCoordPos is fine or else miplevel will be broken. This can be an issue for flowing lava.
        if (absMidCoordPos.x > 0.0001 && absMidCoordPos.y > 0.0001)
        // Excluding cutout blocks for better looks
        if (texture2DLod(texSampler, uv, 10000.0).a == 1.0)
            lod = miplevel * 0.4;
    #endif

    float samplesDiv2 = ANISOTROPIC_FILTER / 2.0;
    vec2 ADivSamples = A / ANISOTROPIC_FILTER;

    vec4 filteredColor = vec4(0.0);
    float totalModifiedAlpha = 0.0;
    vec4 spriteBoundsM = mix(spriteBounds, vec4(midCoord, midCoord), 0.0001); // Fixes some mods causing issues with cutout blocks
    for (float i = -samplesDiv2 + 0.5; i < samplesDiv2; i++) {
        vec2 sampleUV = uv + ADivSamples * i;
        sampleUV = clamp(sampleUV, spriteBoundsM.xy, spriteBoundsM.zw);
        vec4 colorSample = texture2DLod(texSampler, sampleUV, lod);
        
        #if !defined POM || !defined POM_ALLOW_CUTOUT
            float modifiedAlpha = colorSample.a;
        #else
            // To avoid NaNs because we don't discard low alpha if POM_ALLOW_CUTOUT is enabled (see 6WIR4HT23)
            float modifiedAlpha = max(colorSample.a, 0.00001);
        #endif

        totalModifiedAlpha += modifiedAlpha;
        filteredColor.rgb += colorSample.rgb * modifiedAlpha;
        filteredColor.a += colorSample.a;
    }
    filteredColor.rgb /= totalModifiedAlpha;
    filteredColor.a /= ANISOTROPIC_FILTER;

    return filteredColor;
}