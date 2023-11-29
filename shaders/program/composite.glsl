////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

flat in vec3 upVec, sunVec;

#ifdef LIGHTSHAFTS_ACTIVE
    flat in float vlFactor;
#endif

//Uniforms//
uniform int isEyeInWater;

uniform float far, near;
uniform float viewWidth, viewHeight;

uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#if defined LIGHTSHAFTS_ACTIVE || WATER_QUALITY >= 3 || defined NETHER_STORM || RAINBOWS > 0
    uniform float frameTimeCounter;

    uniform mat4 gbufferProjection;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;

    uniform sampler2D noisetex;
#endif

#if defined LIGHTSHAFTS_ACTIVE || defined NETHER_STORM || RAINBOWS > 0
    uniform int frameCounter;

    #ifndef LIGHT_COLORING
        uniform sampler2D colortex3;
    #else
        uniform sampler2D colortex8;
    #endif
#endif

#ifdef LIGHTSHAFTS_ACTIVE
    //uniform float viewWidth, viewHeight;
    uniform float blindness;
    uniform float darknessFactor;
    uniform float frameTime;
    uniform float frameTimeSmooth;

    uniform ivec2 eyeBrightness;

    uniform vec3 skyColor;

    uniform sampler2D shadowtex0;
    uniform sampler2DShadow shadowtex1;
    uniform sampler2D shadowcolor1;
#endif

#if WATER_QUALITY >= 3
    uniform sampler2D colortex6;
#endif

#if defined LIGHTSHAFTS_ACTIVE && defined LENSFLARE || RAINBOWS > 0 && defined OVERWORLD
    uniform sampler2D colortex4;
#endif

#if RAINBOWS == 1
    uniform float wetness;
    uniform float inRainy;
#endif

//Pipeline Constants//
//const bool colortex0MipmapEnabled = true;

//Common Variables//
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;

vec2 view = vec2(viewWidth, viewHeight);

#ifdef OVERWORLD
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
    vec3 lightVec = sunVec;
#endif

#ifdef LIGHTSHAFTS_ACTIVE
    float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
    float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
    float shadowTime = shadowTimeVar2 * shadowTimeVar2;
    float vlTime = min(abs(SdotU) - 0.05, 0.15) / 0.15;
#endif

//Common Functions//

//Includes//
#include "/lib/atmospherics/fog/waterFog.glsl"

#ifdef BLOOM_FOG_COMPOSITE
    #include "/lib/atmospherics/fog/bloomFog.glsl"
#endif

#ifdef LIGHTSHAFTS_ACTIVE
    #ifdef END
        #include "/lib/atmospherics/enderBeams.glsl"
    #endif
    #include "/lib/atmospherics/volumetricLight.glsl"
#endif

#if WATER_QUALITY >= 3 || defined NETHER_STORM
    #include "/lib/util/spaceConversion.glsl"
#endif

#if WATER_QUALITY >= 3
    #include "/lib/materials/materialMethods/refraction.glsl"
#endif

#ifdef NETHER_STORM
    #include "/lib/atmospherics/netherStorm.glsl"
#endif

#ifdef ATM_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif
#ifdef MOON_PHASE_INF_ATMOSPHERE
    #include "/lib/colors/moonPhaseInfluence.glsl"
#endif

#if RAINBOWS > 0 && defined OVERWORLD
    #include "/lib/atmospherics/rainbow.glsl"
#endif

//Program//
void main() {
    vec3 color = texelFetch(colortex0, texelCoord, 0).rgb;
    float z0 = texelFetch(depthtex0, texelCoord, 0).r;
    float z1 = texelFetch(depthtex1, texelCoord, 0).r;

    #if defined LIGHTSHAFTS_ACTIVE || WATER_QUALITY >= 3 || defined BLOOM_FOG_COMPOSITE || defined NETHER_STORM || RAINBOWS > 0 && defined OVERWORLD
        vec4 screenPos = vec4(texCoord, z0, 1.0);
        vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;
        float lViewPos = length(viewPos.xyz);
    #endif

    #if WATER_QUALITY >= 3
        DoRefraction(color, z0, z1, viewPos.xyz, lViewPos);
    #endif

    vec4 volumetricEffect = vec4(0.0);

    #if defined LIGHTSHAFTS_ACTIVE || defined NETHER_STORM || RAINBOWS > 0 && defined OVERWORLD
        /* The "1.0 - translucentMult" trick is done because of the default color attachment
        value being vec3(0.0). This makes it vec3(1.0) to avoid issues especially on improved glass */
        #ifndef LIGHT_COLORING
            vec3 translucentMult = 1.0 - texelFetch(colortex3, texelCoord, 0).rgb;
        #else
            vec3 translucentMult = 1.0 - texelFetch(colortex8, texelCoord, 0).rgb;
        #endif

        float dither = texture2D(noisetex, texCoord * view / 128.0).b;
        #ifdef TAA
            dither = fract(dither + 1.61803398875 * mod(float(frameCounter), 3600.0));
        #endif

        vec4 screenPos1 = vec4(texCoord, z1, 1.0);
        vec4 viewPos1 = gbufferProjectionInverse * (screenPos1 * 2.0 - 1.0);
        viewPos1 /= viewPos1.w;
        float lViewPos1 = length(viewPos1.xyz);
    #endif

    #if defined LIGHTSHAFTS_ACTIVE || RAINBOWS > 0 && defined OVERWORLD
        vec3 nViewPos = normalize(viewPos.xyz);
        float VdotL = dot(nViewPos, lightVec);
    #endif

    #ifdef LIGHTSHAFTS_ACTIVE
        float vlFactorM = vlFactor;

        float VdotU = dot(nViewPos, upVec);

        volumetricEffect = GetVolumetricLight(color, vlFactorM, translucentMult, lViewPos1, nViewPos, VdotL, VdotU, texCoord, z0, z1, dither);
    #endif

    #ifdef NETHER_STORM
        vec3 playerPos = ViewToPlayer(viewPos.xyz);

        volumetricEffect = GetNetherStorm(color, translucentMult, playerPos, viewPos.xyz, lViewPos, lViewPos1, dither);
    #endif

    #ifdef ATM_COLOR_MULTS
        volumetricEffect.rgb *= GetAtmColorMult();
    #endif
    #ifdef MOON_PHASE_INF_ATMOSPHERE
        volumetricEffect.rgb *= moonPhaseInfluence;
    #endif

    #ifdef NETHER_STORM
        if (isEyeInWater == 0) color = mix(color, volumetricEffect.rgb, volumetricEffect.a);
    #endif

    #if RAINBOWS > 0 && defined OVERWORLD
        if (isEyeInWater == 0) color += GetRainbow(translucentMult, z0, z1, lViewPos, lViewPos1, VdotL, dither);
    #endif

    if (isEyeInWater == 1) {
        if (z0 == 1.0) color.rgb = waterFogColor;

        vec3 underwaterMult = vec3(0.80, 0.87, 0.97);
        color.rgb *= underwaterMult * 0.85;
        volumetricEffect.rgb *= pow2(underwaterMult * 0.71);
    } else {
        if (isEyeInWater == 2) {
            if (z1 == 1.0) color.rgb = fogColor * 5.0;

            volumetricEffect.rgb *= 0.0;
        }
    }

    color = pow(color, vec3(2.2));

    #ifdef LIGHTSHAFTS_ACTIVE
        #ifdef END
            volumetricEffect.rgb *= volumetricEffect.rgb;
        #endif

        color += volumetricEffect.rgb;
    #endif

    #ifdef BLOOM_FOG_COMPOSITE
        color *= GetBloomFog(lViewPos); // Reminder: Bloom Fog can move between composite1-2-3
    #endif

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0);

    // a.k.a #if defined LIGHTSHAFTS_ACTIVE && (LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 || defined END)
    #if LIGHTSHAFT_QUALI_DEFINE > 0 && LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 && defined OVERWORLD && defined REALTIME_SHADOWS || defined END
        #ifdef LENSFLARE
            if (viewWidth + viewHeight - gl_FragCoord.x - gl_FragCoord.y > 1.5)
                vlFactorM = texelFetch(colortex4, texelCoord, 0).r;
        #endif

        /* DRAWBUFFERS:04 */
        gl_FragData[1] = vec4(vlFactorM, 0.0, 0.0, 1.0);
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

flat out vec3 upVec, sunVec;

#ifdef LIGHTSHAFTS_ACTIVE
    flat out float vlFactor;
#endif

//Uniforms//
#if defined LIGHTSHAFTS_ACTIVE && (LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 || defined END)
    uniform float viewWidth, viewHeight;

    uniform sampler2D colortex4;
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    upVec = normalize(gbufferModelView[1].xyz);
    sunVec = GetSunVector();

    #ifdef LIGHTSHAFTS_ACTIVE
        #if LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 || defined END
            vlFactor = texelFetch(colortex4, ivec2(viewWidth-1, viewHeight-1), 0).r;
        #else
            #if LIGHTSHAFT_BEHAVIOUR == 2
                vlFactor = 0.0;
            #elif LIGHTSHAFT_BEHAVIOUR == 3
                vlFactor = 1.0;
            #endif
        #endif
    #endif
}

#endif
