/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

flat in vec3 upVec, sunVec;

#ifdef LIGHTSHAFTS_ACTIVE
    flat in float vlFactor;
#endif

//Pipeline Constants//

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
float GetLinearDepth(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

//Includes//
#include "/lib/atmospherics/fog/waterFog.glsl"
#include "/lib/atmospherics/fog/caveFactor.glsl"

#if defined PBR_REFLECTIONS || WATER_REFLECT_QUALITY > 0 && WORLD_SPACE_REFLECTIONS_INTERNAL > 0
    #include "/lib/materials/materialMethods/reflectionBlurFilter.glsl"
#endif

#ifdef BLOOM_FOG_COMPOSITE1
    #include "/lib/atmospherics/fog/bloomFog.glsl"
#endif

#ifdef LIGHTSHAFTS_ACTIVE
    #ifdef END
        #include "/lib/atmospherics/enderBeams.glsl"
    #endif
    #include "/lib/atmospherics/volumetricLight.glsl"
#endif

#if WATER_MAT_QUALITY >= 3 || defined NETHER_STORM || defined COLORED_LIGHT_FOG
    #include "/lib/util/spaceConversion.glsl"
#endif

#if WATER_MAT_QUALITY >= 3
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

#ifdef COLORED_LIGHT_FOG
    #include "/lib/voxelization/lightVoxelization.glsl"
    #include "/lib/atmospherics/fog/coloredLightFog.glsl"
#endif

//Program//
void main() {
    vec3 color = texelFetch(colortex0, texelCoord, 0).rgb;
    float z0 = texelFetch(depthtex0, texelCoord, 0).r;
    float z1 = texelFetch(depthtex1, texelCoord, 0).r;

    vec4 screenPos = vec4(texCoord, z0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
    viewPos /= viewPos.w;
    float lViewPos = length(viewPos.xyz);

    #if defined DISTANT_HORIZONS && !defined OVERWORLD
        float z0DH = texelFetch(dhDepthTex, texelCoord, 0).r;
        vec4 screenPosDH = vec4(texCoord, z0DH, 1.0);
        vec4 viewPosDH = dhProjectionInverse * (screenPosDH * 2.0 - 1.0);
        viewPosDH /= viewPosDH.w;
        lViewPos = min(lViewPos, length(viewPosDH.xyz));
    #endif

    float dither = texture2DLod(noisetex, texCoord * view / 128.0, 0.0).b;
    #ifdef TAA
        dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
    #endif

    /* TM5723: The "1.0 - translucentMult" trick is done because of the default color attachment
    value being vec3(0.0). This makes it vec3(1.0) to avoid issues especially on improved glass */
    vec3 translucentMult = 1.0 - texelFetch(colortex3, texelCoord, 0).rgb; //TM5723
    vec4 volumetricEffect = vec4(0.0);

    vec2 texCoordM = texCoord;
    #if WATER_MAT_QUALITY >= 3
        texCoordM = DoRefraction(color, z0, z1, viewPos.xyz, lViewPos);
    #endif

    #if defined PBR_REFLECTIONS || WATER_REFLECT_QUALITY > 0 && WORLD_SPACE_REFLECTIONS_INTERNAL > 0
        if (z0 < 1.0) {
            vec4 compositeReflection = texture2D(colortex7, texCoord);
            float fresnelM = pow2(texture2D(colortex4, texCoord).a); // including attenuation through fog and clouds
            if (abs(fresnelM - 0.5) < 0.5) { // 0.0 fresnel doesnt need ref calculations, and 1.0 fresnel basically means error
                if (z0 == z1 || z0 <= 0.56) { // Solids
                    #ifdef PBR_REFLECTIONS
                        if (fresnelM > 0.00001) {
                            compositeReflection = sampleBlurFilteredReflection(compositeReflection, dither, z0);

                            compositeReflection.rgb = max(compositeReflection.rgb, vec3(0.0)); // We seem to have some negative values for some reason
                            
                            // This physically doesn't make sense but fits Minecraft
                            const float texturePreservation = 0.7;
                            compositeReflection.rgb = mix(compositeReflection.rgb, max(color, compositeReflection.rgb), texturePreservation);

                            color = mix(color, compositeReflection.rgb, fresnelM);
                        }
                    #endif
                }
                #if WORLD_SPACE_REFLECTIONS_INTERNAL > 0
                    else { // Translucents
                        vec4 ssrReflection = texture2D(colortex8, texCoordM);
                        color = max(color - ssrReflection.rgb, vec3(0.0));

                        compositeReflection.rgb *= fresnelM;
                        compositeReflection = mix(compositeReflection, ssrReflection, float(ssrReflection.a > 0.999));
                        vec3 combinedRef = mix(ssrReflection.rgb, compositeReflection.rgb, compositeReflection.a);

                        color += combinedRef;
                    }
                #endif
            }
        }
    #endif

    vec4 screenPos1 = vec4(texCoord, z1, 1.0);
    vec4 viewPos1 = gbufferProjectionInverse * (screenPos1 * 2.0 - 1.0);
    viewPos1 /= viewPos1.w;
    float lViewPos1 = length(viewPos1.xyz);

    #if defined DISTANT_HORIZONS && !defined OVERWORLD
        float z1DH = texelFetch(dhDepthTex1, texelCoord, 0).r;
        vec4 screenPos1DH = vec4(texCoord, z1DH, 1.0);
        vec4 viewPos1DH = dhProjectionInverse * (screenPos1DH * 2.0 - 1.0);
        viewPos1DH /= viewPos1DH.w;
        lViewPos1 = min(lViewPos1, length(viewPos1DH.xyz));
    #endif

    #if defined LIGHTSHAFTS_ACTIVE || RAINBOWS > 0 && defined OVERWORLD
        vec3 nViewPos = normalize(viewPos1.xyz);
        float VdotL = dot(nViewPos, lightVec);
    #endif

    #if defined NETHER_STORM || defined COLORED_LIGHT_FOG
        vec3 playerPos = ViewToPlayer(viewPos1.xyz);
        vec3 nPlayerPos = normalize(playerPos);
    #endif

    #if RAINBOWS > 0 && defined OVERWORLD
        if (isEyeInWater == 0) color += GetRainbow(translucentMult, z0, z1, lViewPos, lViewPos1, VdotL, dither);
    #endif

    #ifdef LIGHTSHAFTS_ACTIVE
        float vlFactorM = vlFactor;
        float VdotU = dot(nViewPos, upVec);

        volumetricEffect = GetVolumetricLight(color, vlFactorM, translucentMult, lViewPos, lViewPos1, nViewPos, VdotL, VdotU, texCoord, z0, z1, dither);
    #endif

    #ifdef NETHER_STORM
        volumetricEffect = GetNetherStorm(color, translucentMult, nPlayerPos, playerPos, lViewPos, lViewPos1, dither);
    #endif

    #ifdef ATM_COLOR_MULTS
        volumetricEffect.rgb *= GetAtmColorMult();
    #endif
    #ifdef MOON_PHASE_INF_ATMOSPHERE
        volumetricEffect.rgb *= moonPhaseInfluence;
    #endif

    #ifdef NETHER_STORM
        color = mix(color, volumetricEffect.rgb, volumetricEffect.a);
    #endif

    #ifdef COLORED_LIGHT_FOG
        vec3 lightFog = GetColoredLightFog(nPlayerPos, translucentMult, lViewPos, lViewPos1, dither);
        float lightFogMult = COLORED_LIGHT_FOG_I;
        //if (heldItemId == 40000 && heldItemId2 != 40000) lightFogMult = 0.0; // Hold spider eye to disable light fog

        #ifdef OVERWORLD
            lightFogMult *= 0.2 + 0.6 * mix(1.0, 1.0 - sunFactor * invRainFactor, eyeBrightnessM);
        #endif
    #endif

    if (isEyeInWater == 1) {
        if (z0 == 1.0) color.rgb = waterFogColor;

        vec3 underwaterMult = vec3(0.80, 0.87, 0.97);
        color.rgb *= underwaterMult * 0.85;
        volumetricEffect.rgb *= pow2(underwaterMult * 0.71);

        #ifdef COLORED_LIGHT_FOG
            lightFog *= underwaterMult;
        #endif
    } else if (isEyeInWater == 2) {
        if (z1 == 1.0) color.rgb = fogColor * 5.0;

        volumetricEffect.rgb *= 0.0;
        #ifdef COLORED_LIGHT_FOG
            lightFog *= 0.0;
        #endif
    }

    #ifdef COLORED_LIGHT_FOG
        color /= 1.0 + pow2(GetLuminance(lightFog)) * lightFogMult * 2.0;
        color += lightFog * lightFogMult * 0.5;
    #endif

    color = pow(color, vec3(2.2));

    #ifdef LIGHTSHAFTS_ACTIVE
        #ifdef END
            volumetricEffect.rgb *= volumetricEffect.rgb;
        #endif

        color += volumetricEffect.rgb;
    #endif

    #ifdef BLOOM_FOG_COMPOSITE1
        color *= GetBloomFog(lViewPos); // Reminder: Bloom Fog can move between composite1-2-3
    #endif

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0);

    // supposed to be #if defined LIGHTSHAFTS_ACTIVE && (LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 || defined END)
    #if LIGHTSHAFT_QUALI_DEFINE > 0 && LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 && defined OVERWORLD || defined END
        #if LENSFLARE_MODE > 0 || defined ENTITY_TAA_NOISY_CLOUD_FIX
            if (viewWidth + viewHeight - gl_FragCoord.x - gl_FragCoord.y > 1.5)
                vlFactorM = texelFetch(colortex5, texelCoord, 0).a;
        #endif

        /* DRAWBUFFERS:05 */
        gl_FragData[1] = vec4(0.0, 0.0, 0.0, vlFactorM);
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
            vlFactor = texelFetch(colortex5, ivec2(viewWidth-1, viewHeight-1), 0).a;
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
