/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

#if MOTION_BLUR_EFFECT == 1 && defined MOTION_BLUR_BLOOM_FOG_FIX
    flat in vec3 upVec, sunVec;
#endif

//Pipeline Constants//
const bool colortex0MipmapEnabled = true;

//Common Variables//
float weight[7] = float[7](1.0, 6.0, 15.0, 20.0, 15.0, 6.0, 1.0);

vec2 view = vec2(viewWidth, viewHeight);

#if MOTION_BLUR_EFFECT == 1 && defined MOTION_BLUR_BLOOM_FOG_FIX
    float SdotU = dot(sunVec, upVec);
    float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
#endif

//Common Functions//
vec3 BloomTile(float lod, vec2 offset, vec2 scaledCoord) {
    vec3 bloom = vec3(0.0);
    float scale = exp2(lod);
    vec2 coord = (scaledCoord - offset) * scale;
    float padding = 0.5 + 0.005 * scale;

    if (abs(coord.x - 0.5) < padding && abs(coord.y - 0.5) < padding) {
        for (int i = -3; i <= 3; i++) {
            for (int j = -3; j <= 3; j++) {
                float wg = weight[i + 3] * weight[j + 3];
                vec2 pixelOffset = vec2(i, j) / view;
                vec2 bloomCoord = (scaledCoord - offset + pixelOffset) * scale;
                bloom += texture2D(colortex0, bloomCoord).rgb * wg;
            }
        }
        bloom /= 4096.0;
    }

    return pow(bloom / 128.0, vec3(0.25));
}

//Includes//
#if MOTION_BLUR_EFFECT == 1
    #include "/lib/util/dither.glsl"

    #ifdef MOTION_BLUR_BLOOM_FOG_FIX
        #include "/lib/atmospherics/fog/bloomFog.glsl"
    #endif
#endif

//Program//
void main() {
    vec3 blur = vec3(0.0);

    #if BLOOM_ENABLED == 1
        vec2 scaledCoord = texCoord * max(vec2(viewWidth, viewHeight) / vec2(1920.0, 1080.0), vec2(1.0));

        #if defined OVERWORLD || defined END
            blur += BloomTile(2.0, vec2(0.0      , 0.0   ), scaledCoord);
            blur += BloomTile(3.0, vec2(0.0      , 0.26  ), scaledCoord);
            blur += BloomTile(4.0, vec2(0.135    , 0.26  ), scaledCoord);
            blur += BloomTile(5.0, vec2(0.2075   , 0.26  ), scaledCoord) * 0.8;
            blur += BloomTile(6.0, vec2(0.135    , 0.3325), scaledCoord) * 0.8;
            blur += BloomTile(7.0, vec2(0.160625 , 0.3325), scaledCoord) * 0.6;
            blur += BloomTile(8.0, vec2(0.1784375, 0.3325), scaledCoord) * 0.4;
        #else
            blur += BloomTile(2.0, vec2(0.0      , 0.0   ), scaledCoord);
            blur += BloomTile(3.0, vec2(0.0      , 0.26  ), scaledCoord);
            blur += BloomTile(4.0, vec2(0.135    , 0.26  ), scaledCoord);
            blur += BloomTile(5.0, vec2(0.2075   , 0.26  ), scaledCoord);
            blur += BloomTile(6.0, vec2(0.135    , 0.3325), scaledCoord);
            blur += BloomTile(7.0, vec2(0.160625 , 0.3325), scaledCoord);
            blur += BloomTile(8.0, vec2(0.1784375, 0.3325), scaledCoord) * 0.6;
        #endif
    #endif

    #if MOTION_BLUR_EFFECT == 1
        vec3 color = vec3(0.0);

        float z = texture2D(depthtex1, texCoord).x;
        float dither = Bayer64(gl_FragCoord.xy);

        if (z <= 0.56) {
            color = texelFetch(colortex0, texelCoord, 0).rgb;
        } else {
            float mbwg = 0.0;
            vec2 doublePixel = 2.0 / vec2(viewWidth, viewHeight);

            vec4 currentPosition = vec4(texCoord, z, 1.0) * 2.0 - 1.0;

            vec4 viewPos = gbufferProjectionInverse * currentPosition;
            viewPos = gbufferModelViewInverse * viewPos;
            viewPos /= viewPos.w;
            float lViewPos = length(viewPos.xyz);

            vec3 cameraOffset = cameraPosition - previousCameraPosition;

            vec4 previousPosition = viewPos + vec4(cameraOffset, 0.0);
            previousPosition = gbufferPreviousModelView * previousPosition;
            previousPosition = gbufferPreviousProjection * previousPosition;
            previousPosition /= previousPosition.w;

            vec2 velocity = (currentPosition - previousPosition).xy;
            velocity = velocity / (1.0 + length(velocity)) * MOTION_BLURRING_STRENGTH;

            #ifndef LOW_QUALITY_MOTION_BLUR
                int sampleCount = 9;
                velocity *= 0.02;
            #else
                int sampleCount = 3;
                velocity *= 0.06;
            #endif

            vec2 coord = texCoord - velocity * (float(sampleCount) / 2.0 - 1.0 + dither);
            for (int i = 0; i < sampleCount; i++, coord += velocity) {
                vec2 coordb = clamp(coord, doublePixel, 1.0 - doublePixel);
                vec3 sampleb = texture2DLod(colortex0, coordb, 0).rgb;
                
                #ifdef MOTION_BLUR_BLOOM_FOG_FIX
                    float z0 = texture2D(depthtex0, coordb).r;
                    vec4 screenPos = vec4(coordb, z0, 1.0);
                    vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
                    viewPos /= viewPos.w;
                    float lViewPos = length(viewPos.xyz);
                    // Remove bloom fog from mb samples or else we get edge artifacts
                    sampleb /= GetBloomFog(lViewPos);
                #endif

                color += sampleb;
                mbwg += 1.0;
            }
            color /= mbwg;
            
            #ifdef MOTION_BLUR_BLOOM_FOG_FIX
                // Reapply bloom fog because we removed it from our samples
                color *= GetBloomFog(lViewPos);
            #endif
        }
    #endif

    /* DRAWBUFFERS:3 */
    gl_FragData[0] = vec4(blur, 1.0);

    #if MOTION_BLUR_EFFECT == 1
        /* DRAWBUFFERS:30 */
        gl_FragData[1] = vec4(color, 1.0);
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

#if MOTION_BLUR_EFFECT == 1 && defined MOTION_BLUR_BLOOM_FOG_FIX
    flat out vec3 upVec, sunVec;
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();

    texCoord = gl_MultiTexCoord0.xy;

    #if MOTION_BLUR_EFFECT == 1 && defined MOTION_BLUR_BLOOM_FOG_FIX
        upVec = normalize(gbufferModelView[1].xyz);
        sunVec = GetSunVector();
    #endif
}

#endif
