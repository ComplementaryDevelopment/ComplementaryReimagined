/*
    This file is specifically licensed with Mozilla Public License Version 2.0.
    You can get a copy from https://www.mozilla.org/MPL/2.0/
*/

float manualDeterminant(mat2 matrix) {
    return matrix[0].x * matrix[1].y - matrix[0].y * matrix[1].x;
}

mat2 inverseM(mat2 m) {
    mat2 adj;
    adj[0][0] = m[1][1];
    adj[0][1] = -m[0][1];
    adj[1][0] = -m[1][0];
    adj[1][1] = m[0][0];
    return adj / manualDeterminant(m);
}

vec4 textureAF(sampler2D texSampler, vec2 uv) {
    vec2 spriteDimensions = vec2(spriteBounds.z - spriteBounds.x, spriteBounds.w - spriteBounds.y);

    mat2 J = inverse(mat2(dFdx(uv), dFdy(uv)));          // dFdxy: pixel footprint in texture space
    J = transpose(J)*J;                                  // quadratic form
    float d = manualDeterminant(J), t = J[0][0]+J[1][1], // find ellipse: eigenvalues, max eigenvector
          D = sqrt(abs(t*t-4.0*d)),                      // abs() fix a bug: in weird view angles 0 can be slightly negative
          V = (t-D)/2.0, v = (t+D)/2.0,                  // eigenvalues
          M = 1.0/sqrt(V), m = 1./sqrt(v);               // = 1./radii^2
    vec2 A = M * normalize(vec2(-J[0][1], J[0][0]-V));   // max eigenvector = main axis

    float lod;
    if (M/m > 16.0) {
        lod = log2(M / 16.0 * viewHeight);
    } else {
        lod = log2(m * viewHeight);
    }

    float samplesDiv2 = ANISOTROPIC_FILTER / 2.0;
    vec2 ADivSamples = A / ANISOTROPIC_FILTER;

    vec4 filteredColor = vec4(0.0);
    vec4 spriteBoundsM = mix(spriteBounds, vec4(midCoord, midCoord), 0.0001); // Fixes some mods causing issues with cutout blocks
    for (float i = -samplesDiv2 + 0.5; i < samplesDiv2; i++) {
        vec2 sampleUV = uv + ADivSamples * i;
        sampleUV = clamp(sampleUV, spriteBoundsM.xy, spriteBoundsM.zw);
        vec4 colorSample = texture2DLod(texSampler, sampleUV, lod);

        filteredColor.rgb += colorSample.rgb * colorSample.a;
        filteredColor.a += colorSample.a;
    }
    filteredColor.rgb /= filteredColor.a;
    filteredColor.a /= ANISOTROPIC_FILTER;

    return filteredColor;
}