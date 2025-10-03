/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

flat in vec3 upVec, sunVec, eastVec;

#if defined LIGHTSHAFTS_ACTIVE && (LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 || defined END)
    flat in float vlFactor;
#endif

//Pipeline Constants//
const bool colortex0MipmapEnabled = true;

//Common Variables//
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;
float farMinusNear = far - near;

vec2 view = vec2(viewWidth, viewHeight);

#ifdef OVERWORLD
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
    vec3 lightVec = sunVec;
#endif

#if defined LIGHTSHAFTS_ACTIVE && (LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 || defined END)
#else
    float vlFactor = 0.0;
#endif

//Common Functions//
float GetLinearDepth(float depth) {
    return (2.0 * near) / (far + near - depth * farMinusNear);
}

#if SSAO_QUALI > 0
    vec2 OffsetDist(float x, int s) {
        float n = fract(x * 1.414) * 3.1415;
        return pow2(vec2(cos(n), sin(n)) * x / s);
    }

    float DoAmbientOcclusion(float z0, float linearZ0, float dither) {
        if (z0 < 0.56) return 1.0;
        float ao = 0.0;

        #if SSAO_QUALI == 2
            int samples = 4;
            float scm = 0.4;
        #elif SSAO_QUALI == 3
            int samples = 12;
            float scm = 0.6;
        #endif

        #define SSAO_I_FACTOR 0.004

        float sampleDepth = 0.0, angle = 0.0, dist = 0.0;
        float fovScale = gbufferProjection[1][1];
        float distScale = max(farMinusNear * linearZ0 + near, 3.0);
        vec2 scale = vec2(scm / aspectRatio, scm) * fovScale / distScale;

        for (int i = 1; i <= samples; i++) {
            vec2 offset = OffsetDist(i + dither, samples) * scale;
            if (i % 2 == 0) offset.y = -offset.y;

            vec2 coord1 = texCoord + offset;
            vec2 coord2 = texCoord - offset;

            sampleDepth = GetLinearDepth(texture2D(depthtex0, coord1).r);
            float aosample = farMinusNear * (linearZ0 - sampleDepth) * 2.0;
            angle = clamp(0.5 - aosample, 0.0, 1.0);
            dist = clamp(0.5 * aosample - 1.0, 0.0, 1.0);

            sampleDepth = GetLinearDepth(texture2D(depthtex0, coord2).r);
            aosample = farMinusNear * (linearZ0 - sampleDepth) * 2.0;
            angle += clamp(0.5 - aosample, 0.0, 1.0);
            dist += clamp(0.5 * aosample - 1.0, 0.0, 1.0);

            ao += clamp(angle + dist, 0.0, 1.0);
        }
        ao /= samples;

        #define SSAO_IM SSAO_I * SSAO_I_FACTOR
        return pow(ao, SSAO_IM);
    }
#endif

//Includes//
#include "/lib/util/spaceConversion.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/fog/mainFog.glsl"
#include "/lib/colors/skyColors.glsl"
#include "/lib/colors/lightAndAmbientColors.glsl"

#if AURORA_STYLE > 0
    #include "/lib/atmospherics/auroraBorealis.glsl"
#endif

#if NIGHT_NEBULAE == 1
    #include "/lib/atmospherics/nightNebula.glsl"
#endif

#ifdef VL_CLOUDS_ACTIVE
    #include "/lib/atmospherics/clouds/mainClouds.glsl"
#endif

#ifdef END
    #include "/lib/atmospherics/enderStars.glsl"
#endif

#ifdef WORLD_OUTLINE
    #include "/lib/misc/worldOutline.glsl"
#endif

#ifdef DARK_OUTLINE
    #include "/lib/misc/darkOutline.glsl"
#endif

#ifdef ATM_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif
#ifdef MOON_PHASE_INF_ATMOSPHERE
    #include "/lib/colors/moonPhaseInfluence.glsl"
#endif

#ifdef DISTANT_LIGHT_BOKEH
    #include "/lib/misc/distantLightBokeh.glsl"
#endif

//Program//
void main() {
    vec4 color = vec4(texelFetch(colortex0, texelCoord, 0).rgb, 1.0);
    float z0 = texelFetch(depthtex0, texelCoord, 0).r;

    vec4 screenPos = vec4(texCoord, z0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
    viewPos /= viewPos.w;
    float lViewPos = length(viewPos);
    vec3 nViewPos = normalize(viewPos.xyz);
    vec3 playerPos = ViewToPlayer(viewPos.xyz);

    float dither = texture2DLod(noisetex, texCoord * vec2(viewWidth, viewHeight) / 128.0, 0.0).b;
    #ifdef TAA
        dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
    #endif

    #ifdef ATM_COLOR_MULTS
        atmColorMult = GetAtmColorMult();
        sqrtAtmColorMult = sqrt(atmColorMult);
    #endif

    float VdotU = dot(nViewPos, upVec);
    float VdotS = dot(nViewPos, sunVec);
    float skyFade = 0.0;
    vec3 waterRefColor = vec3(0.0);
    vec3 auroraBorealis = vec3(0.0);
    vec3 nightNebula = vec3(0.0);

    vec3 normalM = vec3(0);
    float fresnelM = 0.0;

    if (z0 < 1.0) {
        #ifdef DISTANT_LIGHT_BOKEH
            int dlbo = 1;
            vec3 dlbColor = color.rgb;
            dlbColor += texelFetch(colortex0, texelCoord + ivec2( 0, dlbo), 0).rgb;
            dlbColor += texelFetch(colortex0, texelCoord + ivec2( 0,-dlbo), 0).rgb;
            dlbColor += texelFetch(colortex0, texelCoord + ivec2( dlbo, 0), 0).rgb;
            dlbColor += texelFetch(colortex0, texelCoord + ivec2(-dlbo, 0), 0).rgb;
            dlbColor = max(color.rgb, dlbColor * 0.2);
            float dlbMix = GetDistantLightBokehMix(lViewPos);
            color.rgb = mix(color.rgb, dlbColor, dlbMix);
        #endif

        #if SSAO_QUALI > 0 || defined WORLD_OUTLINE
            float linearZ0 = GetLinearDepth(z0);
        #endif

        #if SSAO_QUALI > 0
            float ssao = DoAmbientOcclusion(z0, linearZ0, dither);
        #else
            float ssao = 1.0;
        #endif

        vec3 texture6 = texelFetch(colortex6, texelCoord, 0).rgb;
        bool entityOrHand = z0 < 0.56;
        int materialMaskInt = int(texture6.g * 255.1);
        float intenseFresnel = 0.0;
        float smoothnessD = texture6.r;
        vec3 reflectColor = vec3(1.0);

        #include "/lib/materials/materialHandling/deferredMaterials.glsl"

        #ifdef WORLD_OUTLINE
            #ifndef WORLD_OUTLINE_ON_ENTITIES
                if (!entityOrHand)
            #endif
            DoWorldOutline(color.rgb, linearZ0);
        #endif

        #ifdef DARK_OUTLINE
            DoDarkOutline(color.rgb, z0);
        #endif

        color.rgb *= ssao;

        #ifdef PBR_REFLECTIONS
            vec3 texture4 = texelFetch(colortex4, texelCoord, 0).rgb;
            normalM = mat3(gbufferModelView) * texture4;
            float fresnel = clamp(1.0 + dot(normalM, nViewPos), 0.0, 1.0);

            #if WORLD_SPACE_REFLECTIONS_INTERNAL == -1
                // Way steeper fresnel falloff on SSR-only mode to hide SSR limitation and gain performance
                float fresnelFactor = (1.0 - smoothnessD) * 0.7;
                fresnelM = max(fresnel - fresnelFactor, 0.0) / (1.0 - fresnelFactor);
            #else
                fresnelM = fresnel * 0.7 + 0.3;
            #endif

            fresnelM = mix(pow2(fresnelM), fresnelM * 0.75 + 0.25, intenseFresnel);
            fresnelM = fresnelM * sqrt1(smoothnessD) - dither * 0.01;
        #endif

        waterRefColor = color.rgb;

        DoFog(color, skyFade, lViewPos, playerPos, VdotU, VdotS, dither);
    } else { // Sky
        #ifdef DISTANT_HORIZONS
            float z0DH = texelFetch(dhDepthTex, texelCoord, 0).r;
            if (z0DH < 1.0) { // Distant Horizons Chunks
                vec4 screenPosDH = vec4(texCoord, z0DH, 1.0);
                vec4 viewPosDH = dhProjectionInverse * (screenPosDH * 2.0 - 1.0);
                viewPosDH /= viewPosDH.w;
                lViewPos = length(viewPosDH.xyz);
                playerPos = ViewToPlayer(viewPosDH.xyz);
                waterRefColor = color.rgb;
                
                DoFog(color, skyFade, lViewPos, playerPos, VdotU, VdotS, dither);
            } else { // Start of Actual Sky
        #endif

        skyFade = 1.0;

        #ifdef OVERWORLD
            #if AURORA_STYLE > 0
                auroraBorealis = GetAuroraBorealis(viewPos.xyz, VdotU, dither);
                color.rgb += auroraBorealis;
            #endif
            #if NIGHT_NEBULAE == 1
                nightNebula += GetNightNebula(viewPos.xyz, VdotU, VdotS);
                color.rgb += nightNebula;
            #endif
        #endif
        #ifdef NETHER
            color.rgb = netherColor * (1.0 - maxBlindnessDarkness);

            #ifdef ATM_COLOR_MULTS
                color.rgb *= atmColorMult;
            #endif
        #endif
        #ifdef END
            color.rgb = endSkyColor;
            color.rgb += GetEnderStars(viewPos.xyz, VdotU);
            color.rgb *= 1.0 - maxBlindnessDarkness;

            #ifdef ATM_COLOR_MULTS
                color.rgb *= atmColorMult;
            #endif
        #endif

        #ifdef DISTANT_HORIZONS
        } // End of Actual Sky
        #endif
    }

    float cloudLinearDepth = 1.0;
    vec4 clouds = vec4(0.0);

    #ifdef VL_CLOUDS_ACTIVE
        float cloudZCheck = 0.56;

        if (z0 > cloudZCheck) {
            clouds = GetClouds(cloudLinearDepth, skyFade, vec3(0.0), playerPos,
                               lViewPos, VdotS, VdotU, dither, auroraBorealis, nightNebula);

            color = mix(color, vec4(clouds.rgb, 0.0), clouds.a);
        }
    #endif

    #ifdef SKY_EFFECT_REFLECTION
        waterRefColor = mix(waterRefColor, clouds.rgb, clouds.a);
    #endif
    waterRefColor = sqrt(waterRefColor) * 0.5;

    #if defined LIGHTSHAFTS_ACTIVE && (LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 || defined END)
        if (viewWidth + viewHeight - gl_FragCoord.x - gl_FragCoord.y < 1.5)
            cloudLinearDepth = vlFactor;
    #endif

    #if defined OVERWORLD && defined ATMOSPHERIC_FOG && (defined SPECIAL_BIOME_WEATHER || RAIN_STYLE == 2)
        if (isEyeInWater == 0) {
            float altitudeFactorRaw = GetAtmFogAltitudeFactor(playerPos.y + cameraPosition.y);
            vec3 atmFogColor = GetAtmFogColor(altitudeFactorRaw, VdotS);

            #if RAIN_STYLE == 2
                float factor = 1.0;
            #else
                float factor = max(inSnowy, inDry);
            #endif

            color = mix(color, vec4(atmFogColor, 0.0), 0.5 * rainFactor * factor * sqrt1(skyFade));
        }
    #endif

    /*DRAWBUFFERS:05*/
    gl_FragData[0] = vec4(color.rgb, 1.0);
    gl_FragData[1] = vec4(waterRefColor, cloudLinearDepth);

    // same check as #ifdef PBR_REFLECTIONS but for Optifine to understand:
    #if BLOCK_REFLECT_QUALITY >= 2 && RP_MODE >= 1
        /*DRAWBUFFERS:054*/
        gl_FragData[2] = vec4(mat3(gbufferModelViewInverse) * normalM, sqrt(fresnelM * color.a));
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

flat out vec3 upVec, sunVec, eastVec;

#if defined LIGHTSHAFTS_ACTIVE && (LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 || defined END)
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
    eastVec = normalize(gbufferModelView[0].xyz);

    #if defined LIGHTSHAFTS_ACTIVE && (LIGHTSHAFT_BEHAVIOUR == 1 && SHADOW_QUALITY >= 1 || defined END)
        vlFactor = texelFetch(colortex5, ivec2(viewWidth-1, viewHeight-1), 0).a;

        #ifdef END
            if (frameCounter % int(0.06666 / frameTimeSmooth + 0.5) == 0) { // Change speed is not too different above 10 fps

                #if MC_VERSION >= 12106
                    bool isEnderDragonDead = !heavyFog;
                #else
                    vec2 absCamPosXZ = abs(cameraPosition.xz);
                    float maxCamPosXZ = max(absCamPosXZ.x, absCamPosXZ.y);
                    bool isEnderDragonDead = gl_Fog.start / far > 0.5 || maxCamPosXZ > 350.0;
                #endif

                if (isEnderDragonDead) vlFactor = max(vlFactor - OSIEBCA*2, 0.0);
                else                   vlFactor = min(vlFactor + OSIEBCA*2, 1.0);
            }
        #endif
    #endif
}

#endif
