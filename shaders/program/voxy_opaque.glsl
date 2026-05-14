/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

#define VOXY_PATCH
#define texture2DLod textureLod
#define texture2D texture

mat4 gbufferModelView = vxModelView;
mat4 gbufferModelViewInverse = vxModelViewInv;
mat4 gbufferPreviousModelView = vxModelViewPrev;
mat4 gbufferProjection = vxProj;
mat4 gbufferProjectionInverse = vxProjInv;
mat4 gbufferPreviousProjection = vxProjPrev;

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

//Pipeline//
layout(location = 0) out vec4 gbufferData0;
layout(location = 1) out vec4 gbufferData6;

//Common Variables//
vec3 sunVec = GetSunVector();
vec3 upVec = normalize(gbufferModelView[1].xyz);
vec3 eastVec = normalize(gbufferModelView[0].xyz);
vec3 northVec = normalize(gbufferModelView[2].xyz);

float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;

int mat;
float NdotU;
float NdotUmax0;
vec2 lmCoord;
vec2 lmCoordM;
vec3 normal;
vec4 glColor;

#ifdef OVERWORLD
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
    vec3 lightVec = sunVec;
#endif

//Common Functions//
void DoFoliageColorTweaks(inout vec3 color, inout vec3 shadowMult, inout float snowMinNdotU, vec3 viewPos, vec3 nViewPos, float lViewPos, float dither) {
    #ifdef SNOWY_WORLD
        if (glColor.g - glColor.b > 0.01)
            snowMinNdotU = min(pow2(pow2(max0(color.g * 2.0 - color.r - color.b))) * 5.0, 0.1);
        else
            snowMinNdotU = min(pow2(pow2(max0(color.g * 2.0 - color.r - color.b))) * 3.0, 0.1) * 0.25;
    #endif
}

//Includes//
#include "/lib/util/spaceConversion.glsl"
#include "/lib/util/dither.glsl"

#ifdef ATM_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif

#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif

#define GBUFFERS_TERRAIN
    #include "/lib/lighting/mainLighting.glsl"
#undef GBUFFERS_TERRAIN

#ifdef SNOWY_WORLD
    #include "/lib/materials/materialMethods/snowyWorld.glsl"
#endif

#ifdef DISTANT_LIGHT_BOKEH
    #include "/lib/misc/distantLightBokeh.glsl"
#endif

//Program//
void voxy_emitFragment(VoxyFragmentParameters parameters) {
    // Prepare
        mat = int(parameters.customId);
        lmCoord = clamp((parameters.lightMap - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
        lmCoordM = lmCoord;
        normal = upVec;
        switch (uint(parameters.face) >> 1u) {
            case 0u:
            normal = vxModelView[1].xyz;
            break;
            case 1u:
            normal = vxModelView[2].xyz;
            break;
            case 2u:
            normal = vxModelView[0].xyz;
            break;
        }
        if ((parameters.face & 1) == 0) {
            normal = -normal;
        }
        NdotU = dot(normal, upVec);
        NdotUmax0 = max(NdotU, 0.0);
        glColor = parameters.tinting;
    //
    vec4 color = parameters.sampledColour * vec4(glColor.rgb, 1.0);

    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    #ifdef TAA
        vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
    #else
        vec3 viewPos = ScreenToView(screenPos);
    #endif
    float lViewPos = length(viewPos);
    vec3 nViewPos = normalize(viewPos);
    vec3 playerPos = mat3(vxModelViewInv) * viewPos + vxModelViewInv[3].xyz;

    float dither = Bayer64(gl_FragCoord.xy);
    #ifdef TAA
        dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
    #endif

    int subsurfaceMode = 0;
    bool noSmoothLighting = false, noDirectionalShading = false, noVanillaAO = false, centerShadowBias = false, noGeneratedNormals = false, doTileRandomisation = true;
    float smoothnessD = 0.0, materialMask = 0.0;
    float smoothnessG = 0.0, highlightMult = 1.0, emission = 0.0, noiseFactor = 1.0, snowFactor = 1.0, snowMinNdotU = 0.0, noPuddles = 0.0;
    vec3 geoNormal = normal, normalM = normal, shadowMult = vec3(1.0);
    vec3 worldGeoNormal = normalize(mat3(vxModelViewInv) * normal);

    // Praying to god these don't cause massive issues
    vec2 atlasSize = vec2(999999999.0);
    vec2 midCoord = vec2(999999999.0);
    vec2 signMidCoordPos = vec2(999999999.0);
    vec2 absMidCoordPos = vec2(999999999.0);
    vec2 texCoord = vec2(999999999.0);

    #include "/lib/materials/materialHandling/terrainMaterials.glsl"

    #ifdef SNOWY_WORLD
        DoSnowyWorld(color, smoothnessG, highlightMult, smoothnessD, emission,
                     playerPos, lmCoord, snowFactor, snowMinNdotU, NdotU, subsurfaceMode);
    #endif

    DoLighting(color, shadowMult, playerPos, viewPos, lViewPos, geoNormal, normalM, dither,
               worldGeoNormal, lmCoordM, noSmoothLighting, noDirectionalShading, noVanillaAO,
               centerShadowBias, subsurfaceMode, smoothnessG, highlightMult, emission);

    float skyLightFactor = GetSkyLightFactor(lmCoordM, shadowMult);

    #ifdef IRIS_FEATURE_FADE_VARIABLE
        skyLightFactor *= 0.5;
    #endif

    gbufferData0 = color;
    gbufferData6 = vec4(smoothnessD, materialMask, skyLightFactor, 1.0);
}

#endif