/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

flat in int mat;

in vec2 lmCoord;

flat in vec3 upVec, sunVec, northVec, eastVec;
in vec3 normal;
in vec3 playerPos;
in vec3 viewVector;

in vec4 glColor;

//Pipeline Constants//

//Common Variables//
float NdotU = dot(normal, upVec);
float NdotUmax0 = max(NdotU, 0.0);
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;

vec2 lmCoordM = lmCoord;

mat4 gbufferProjection = dhProjection;
mat4 gbufferProjectionInverse = dhProjectionInverse;

#ifdef OVERWORLD
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
    vec3 lightVec = sunVec;
#endif

#if WATER_STYLE >= 2 || RAIN_PUDDLES >= 1 && WATER_STYLE == 1 && WATER_MAT_QUALITY >= 2 || defined GENERATED_NORMALS || defined CUSTOM_PBR
    mat3 tbnMatrix = mat3(
        eastVec.x, northVec.x, normal.x,
        eastVec.y, northVec.y, normal.y,
        eastVec.z, northVec.z, normal.z
    );
#endif

//Common Functions//

//Includes//
#include "/lib/util/dither.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/mainLighting.glsl"
#include "/lib/atmospherics/fog/mainFog.glsl"

#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif

#ifdef OVERWORLD
    #include "/lib/atmospherics/sky.glsl"
#endif

#if WATER_REFLECT_QUALITY >= 0
    #if defined SKY_EFFECT_REFLECTION && defined OVERWORLD
        #if AURORA_STYLE > 0
            #include "/lib/atmospherics/auroraBorealis.glsl"
        #endif

        #ifdef NIGHT_NEBULA
            #include "/lib/atmospherics/nightNebula.glsl"
        #else
            #include "/lib/atmospherics/stars.glsl"
        #endif

        #ifdef VL_CLOUDS_ACTIVE 
            #include "/lib/atmospherics/clouds/mainClouds.glsl"
        #endif
    #endif

    #include "/lib/materials/materialMethods/reflections.glsl"
#endif

#ifdef ATM_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif
#ifdef MOON_PHASE_INF_ATMOSPHERE
    #include "/lib/colors/moonPhaseInfluence.glsl"
#endif

//Program//
void main() {
    vec4 colorP = vec4(vec3(0.85), glColor.a);
    vec4 color = glColor;

    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    if (texture2D(depthtex1, screenPos.xy).r < 1.0) discard;
    float lViewPos = length(playerPos);

    float dither = Bayer64(gl_FragCoord.xy);
    #ifdef TAA
        dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
    #endif

    #ifdef ATM_COLOR_MULTS
        atmColorMult = GetAtmColorMult();
        sqrtAtmColorMult = sqrt(atmColorMult);
    #endif

    #ifdef VL_CLOUDS_ACTIVE
        float cloudLinearDepth = texelFetch(gaux1, texelCoord, 0).r;

        if (pow2(cloudLinearDepth + OSIEBCA * dither) * renderDistance < min(lViewPos, renderDistance)) discard;
    #endif

    #ifdef TAA
        vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
    #else
        vec3 viewPos = ScreenToView(screenPos);
    #endif
    vec3 nViewPos = normalize(viewPos);
    float VdotU = dot(nViewPos, upVec);
    float VdotS = dot(nViewPos, sunVec);

    bool noSmoothLighting = false, noDirectionalShading = false, noVanillaAO = false, centerShadowBias = false;
    int subsurfaceMode = 0;
    float smoothnessG = 0.0, highlightMult = 0.0, emission = 0.0, materialMask = 0.0, reflectMult = 0.0;
    vec3 normalM = normal, geoNormal = normal, shadowMult = vec3(1.0);
    vec3 worldGeoNormal = normalize(ViewToPlayer(geoNormal * 10000.0));
    float fresnel = clamp(1.0 + dot(normalM, nViewPos), 0.0, 1.0);

    if (mat == DH_BLOCK_WATER) {
        #include "/lib/materials/specificMaterials/translucents/water.glsl"
    }

    float lengthCylinder = max(length(playerPos.xz), abs(playerPos.y) * 2.0);
    color.a *= smoothstep(far * 0.5, far * 0.7, lengthCylinder);

    DoLighting(color, shadowMult, playerPos, viewPos, lViewPos, geoNormal, normalM,
               worldGeoNormal, lmCoordM, noSmoothLighting, noDirectionalShading, noVanillaAO,
               centerShadowBias, subsurfaceMode, smoothnessG, highlightMult, emission);

    // Reflections
    #if WATER_REFLECT_QUALITY >= 0
        #ifdef LIGHT_COLOR_MULTS
            highlightColor *= lightColorMult;
        #endif
        #ifdef MOON_PHASE_INF_REFLECTION
            highlightColor *= pow2(moonPhaseInfluence);
        #endif

        float fresnelM = (pow3(fresnel) * 0.85 + 0.15) * reflectMult;

        float skyLightFactor = pow2(max(lmCoordM.y - 0.7, 0.0) * 3.33333);
        #if SHADOW_QUALITY > -1 && WATER_REFLECT_QUALITY >= 2 && WATER_MAT_QUALITY >= 2
            skyLightFactor = max(skyLightFactor, min1(dot(shadowMult, shadowMult)));
        #endif

        vec4 reflection = GetReflection(normalM, viewPos.xyz, nViewPos, playerPos, lViewPos, -1.0,
                                        depthtex1, dither, skyLightFactor, fresnel,
                                        smoothnessG, geoNormal, color.rgb, shadowMult, highlightMult);

        color.rgb = mix(color.rgb, reflection.rgb, fresnelM);
    #endif
    ////

    float sky = 0.0;
    DoFog(color.rgb, sky, lViewPos, playerPos, VdotU, VdotS, dither);
    color.a *= 1.0 - sky;

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

flat out int mat;

out vec2 lmCoord;

flat out vec3 upVec, sunVec, northVec, eastVec;
out vec3 normal;
out vec3 playerPos;
out vec3 viewVector;

out vec4 glColor;

//Attributes//
attribute vec4 at_tangent;

//Common Variables//

//Common Functions//

//Includes//
#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif

//Program//
void main() {
    gl_Position = ftransform();
    #ifdef TAA
        gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    #endif

    mat = dhMaterialId;

    lmCoord  = GetLightMapCoordinates();
    
    normal = normalize(gl_NormalMatrix * gl_Normal);
    upVec = normalize(gbufferModelView[1].xyz);
    eastVec = normalize(gbufferModelView[0].xyz);
    northVec = normalize(gbufferModelView[2].xyz);
    sunVec = GetSunVector();

    playerPos = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz;

    mat3 tbnMatrix = mat3(
        eastVec.x, northVec.x, normal.x,
        eastVec.y, northVec.y, normal.y,
        eastVec.z, northVec.z, normal.z
    );

    viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;

    glColor = gl_Color;
}

#endif