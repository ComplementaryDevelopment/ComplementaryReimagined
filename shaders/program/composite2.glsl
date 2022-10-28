////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

#ifdef MOTION_BLURRING
    noperspective in vec2 texCoord;

    #ifdef BLOOM_FOG
        flat in vec3 upVec, sunVec;
    #endif
#endif

//Uniforms//
uniform sampler2D colortex0;

#ifdef MOTION_BLURRING
    uniform float viewWidth, viewHeight, aspectRatio;

    uniform vec3 cameraPosition, previousCameraPosition;

    uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse;
    uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;

    uniform sampler2D depthtex1;

    #ifdef BLOOM_FOG
        uniform int isEyeInWater;

        uniform sampler2D depthtex0;
    #endif
#endif

//Pipeline Constants//

//Common Variables//
#if defined MOTION_BLURRING && defined BLOOM_FOG
	float SdotU = dot(sunVec, upVec);
	float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
#endif

//Common Functions//
#ifdef MOTION_BLURRING
    vec3 MotionBlur(vec3 color, float z, float dither) {
        if (z > 0.56) {
            float mbwg = 0.0;
            vec2 doublePixel = 2.0 / vec2(viewWidth, viewHeight);
            vec3 mblur = vec3(0.0);
            
            vec4 currentPosition = vec4(texCoord, z, 1.0) * 2.0 - 1.0;
            
            vec4 viewPos = gbufferProjectionInverse * currentPosition;
            viewPos = gbufferModelViewInverse * viewPos;
            viewPos /= viewPos.w;
            
            vec3 cameraOffset = cameraPosition - previousCameraPosition;
            
            vec4 previousPosition = viewPos + vec4(cameraOffset, 0.0);
            previousPosition = gbufferPreviousModelView * previousPosition;
            previousPosition = gbufferPreviousProjection * previousPosition;
            previousPosition /= previousPosition.w;

            vec2 velocity = (currentPosition - previousPosition).xy;
            velocity = velocity / (1.0 + length(velocity)) * MOTION_BLURRING_STRENGTH * 0.02;
            
            vec2 coord = texCoord - velocity * (3.5 + dither);
            for (int i = 0; i < 9; i++, coord += velocity) {
                vec2 coordb = clamp(coord, doublePixel, 1.0 - doublePixel);
                mblur += texture2DLod(colortex0, coordb, 0).rgb;
                mbwg += 1.0;
            }
            mblur /= mbwg;

            return mblur;
        } else return color;
    }
#endif

//Includes//
#ifdef MOTION_BLURRING
	#include "/lib/util/dither.glsl"

    #ifdef BLOOM_FOG
	    #include "/lib/atmospherics/fog/bloomFog.glsl"
    #endif
#endif

//Program//
void main() {
    vec3 color = texelFetch(colortex0, texelCoord, 0).rgb;

    #ifdef MOTION_BLURRING
		float z = texture2D(depthtex1, texCoord).x;
		float dither = Bayer64(gl_FragCoord.xy);

		color = MotionBlur(color, z, dither);

        #ifdef BLOOM_FOG
	        float z0 = texelFetch(depthtex0, texelCoord, 0).r;

            vec4 screenPos = vec4(texCoord, z0, 1.0);
            vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
            viewPos /= viewPos.w;
            float lViewPos = length(viewPos.xyz);

            color *= GetBloomFog(lViewPos); // Reminder: Bloom Fog moves between composite and composite2 depending on Motion Blur
        #endif
    #endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

#ifdef MOTION_BLURRING
    noperspective out vec2 texCoord;

    #ifdef BLOOM_FOG
        flat out vec3 upVec, sunVec;
    #endif
#endif

//Uniforms//

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	gl_Position = ftransform();
    
    #ifdef MOTION_BLURRING
	    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        #ifdef BLOOM_FOG
            upVec = normalize(gbufferModelView[1].xyz);
            sunVec = GetSunVector();
        #endif
    #endif
}

#endif
