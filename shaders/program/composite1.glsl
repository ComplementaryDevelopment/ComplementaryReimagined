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

//Pipeline Stuff//
#define ALLOW_REFRACTION
#define SMOOTHNESS_AFFECTED_REF_BLUR

#if defined MC_OS_MAC && (defined DISTANT_HORIZONS || defined VOXY)
    // Remove the uses of colortex6 to stay below the 8 sampler limit of macos
    #undef IRIS_FEATURE_FADE_VARIABLE
    #undef ALLOW_REFRACTION
    #undef SMOOTHNESS_AFFECTED_REF_BLUR
#endif

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
#endif

//Common Functions//
float GetLinearDepth(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

//Includes//
#include "/lib/atmospherics/fog/waterFog.glsl"
#include "/lib/atmospherics/fog/caveFactor.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/colors/lightAndAmbientColors.glsl"

#if defined PBR_REFLECTIONS || WATER_REFLECT_QUALITY > 0 && WORLD_SPACE_REFLECTIONS_INTERNAL > 0
    #include "/lib/materials/materialMethods/reflectionBlurFilter.glsl"
#endif

#ifdef BLOOM_FOG_COMPOSITE1
    #include "/lib/atmospherics/fog/bloomFog.glsl"
#endif

#ifdef LIGHTSHAFTS_ACTIVE
    #include "/lib/lighting/shadowSampling.glsl"
    #ifdef END
        #include "/lib/atmospherics/volumetricLight/enderBeams.glsl"
    #endif
    #include "/lib/atmospherics/volumetricLight/volumetricLight.glsl"
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

    #if defined DISTANT_HORIZONS || defined VOXY
        #ifdef DISTANT_HORIZONS
            float z0lod = texelFetch(dhDepthTex, texelCoord, 0).r;
            vec4 screenPosLod = vec4(texCoord, z0lod, 1.0);
            vec4 viewPosLod = dhProjectionInverse * (screenPosLod * 2.0 - 1.0);
        #elif defined VOXY
            float z0lod = texelFetch(vxDepthTexTrans, texelCoord, 0).r;
            vec4 screenPosLod = vec4(texCoord, z0lod, 1.0);
            vec4 viewPosLod = vxProjInv * (screenPosLod * 2.0 - 1.0);
        #endif
        viewPosLod /= viewPosLod.w;
        lViewPos = min(lViewPos, length(viewPosLod.xyz));
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
    #if WATER_MAT_QUALITY >= 3 && defined ALLOW_REFRACTION
        texCoordM = DoRefraction(color, z0, z1, viewPos.xyz, lViewPos);
    #endif

    #if defined PBR_REFLECTIONS || WATER_REFLECT_QUALITY > 0 && WORLD_SPACE_REFLECTIONS_INTERNAL > 0
        if (z0 < 1.0) {
            vec4 compositeReflection = texture2D(colortex7, texCoord);

            // Partial fix for half resolution WSR-only reflections having a lot of sky gaps
            #if WORLD_SPACE_REF_MODE == 1
                if (REFLECTION_RES < 0.6) {
                    vec2 refOffsets[4] = vec2[4](
                        vec2( 1.0, 1.0),
                        vec2(-1.0, 1.0),
                        vec2( 1.0,-1.0),
                        vec2(-1.0,-1.0)
                    );

                    for (int i = 0; i < 4; i++) {
                        vec4 compositeRefSample = texture2D(colortex7, texCoord + refOffsets[i] * 1.5 / view);
                        if (compositeRefSample.a > compositeReflection.a * 1.01) compositeReflection = compositeRefSample;
                    }
                }
            #endif

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

    float z1lod = 1.0;
    #if defined DISTANT_HORIZONS || defined VOXY
        #ifdef DISTANT_HORIZONS
            z1lod = texelFetch(dhDepthTex1, texelCoord, 0).r;
            vec4 screenPos1Lod = vec4(texCoord, z1lod, 1.0);
            vec4 viewPos1Lod = dhProjectionInverse * (screenPos1Lod * 2.0 - 1.0);
        #elif defined VOXY
            z1lod = texelFetch(vxDepthTexOpaque, texelCoord, 0).r;
            vec4 screenPos1Lod = vec4(texCoord, z1lod, 1.0);
            vec4 viewPos1Lod = vxProjInv * (screenPos1Lod * 2.0 - 1.0);
        #endif
        viewPos1Lod /= viewPos1Lod.w;
        lViewPos1 = min(lViewPos1, length(viewPos1Lod.xyz));
    #endif

    #if defined LIGHTSHAFTS_ACTIVE || RAINBOWS > 0 && defined OVERWORLD
        vec3 nViewPos = normalize(viewPos1.xyz);
        float VdotL = dot(nViewPos, lightVec);
        float VdotU = dot(nViewPos, upVec);
    #endif

    #if defined NETHER_STORM || defined COLORED_LIGHT_FOG
        vec3 playerPos = ViewToPlayer(viewPos1.xyz);
        vec3 nPlayerPos = normalize(playerPos);
    #endif

    #if RAINBOWS > 0 && defined OVERWORLD
        color += GetRainbow(translucentMult, nViewPos, z0, z1, lViewPos, lViewPos1, VdotL, VdotU, dither);
    #endif

    #ifdef LIGHTSHAFTS_ACTIVE
        float vlFactorM = vlFactor;

        volumetricEffect = GetVolumetricLight(vlFactorM, translucentMult, lViewPos, lViewPos1, nViewPos, VdotL, VdotU, z0, z1, z1lod, dither);
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

        #ifdef OVERWORLD
            lightFogMult *= 0.2 + 0.6 * mix(1.0, 1.0 - sunFactor * invRainFactor, eyeBrightnessM);
        #endif
    #else
        vec3 lightFog = vec3(0.0);
    #endif

    if (isEyeInWater == 1) {
        if (z0 == 1.0) color.rgb = waterFogColor;

        vec3 underwaterMult = vec3(0.80, 0.87, 0.97);
        color.rgb *= underwaterMult * 0.85;
        volumetricEffect.rgb *= pow2(underwaterMult * 0.55);

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

        lightFog = lightFog * lightFogMult * 0.5;
        #ifdef TAA // Fix banding
            lightFog = max(vec3(0.0), lightFog + (dither - 0.5) * 0.02);
        #endif
        color += lightFog;
    #endif

    #ifdef IMPROVED_RAIN
        vec4 rainData = texelFetch(colortex12, texelCoord, 0);
        if (rainData.r > 0.0) {
            float rainDistance = rainData.r * 100.0;
            if (rainDistance < lViewPos1) {
                bool isSnow = rainData.g == 0.0;
                float blocklight = rainData.b;

                vec3 rainColor = isSnow ? vec3(1.0, 1.0, 1.0) : vec3(0.925, 0.96, 1.0);
                rainColor *= blocklightCol * 2.0 * blocklight + (ambientColor + 0.2 * lightColor) * (0.6 + 0.3 * sunFactor);

                vec3 rainMix = vec3(rainData.a);
                if (rainDistance > lViewPos) rainMix *= pow2(DoReducedLuminanceCorrection(translucentMult, 0.25));

                rainColor += lightFog * (1.0 + 4.0 * rainData.g) + color.rgb * rainData.g * 0.25;

                color = mix(color, rainColor, rainMix);
            }
        }
    #endif

    color = pow(color, vec3(2.2));

    #ifdef LIGHTSHAFTS_ACTIVE
        #if defined END && defined TAA // Fix banding
            volumetricEffect.rgb = max(vec3(0.0), volumetricEffect.rgb + (dither - 0.5) * 0.02);
        #endif
        // We add volumetric effect AFTER the "pow color by 2.2" line to get nicer blending
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
