/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

in vec3 sunVec;

#ifdef END
    in float vlFactor;
#endif

//Pipeline Constants//

//Common Variables//
vec3 upVec = normalize(gbufferModelView[1].xyz);
vec3 eastVec = normalize(gbufferModelView[0].xyz);
vec3 northVec = normalize(gbufferModelView[2].xyz);
#ifdef OVERWORLD
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
    vec3 lightVec = sunVec;
#endif
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;
float farMinusNear = far - near;
float z0;
float z1;

vec2 view = vec2(viewWidth, viewHeight);

//Common Functions//
float GetLinearDepth(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

//Includes//
#include "/lib/util/spaceConversion.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/fog/mainFog.glsl"
#include "/lib/colors/skyColors.glsl"
#include "/lib/colors/lightAndAmbientColors.glsl"
#include "/lib/materials/materialMethods/reflections.glsl"

#ifdef ATM_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif

//Program//
void main() {
    ivec2 texelCoord = ivec2(texCoord * view);
    vec4 color = texelFetch(colortex0, texelCoord, 0);
    vec4 texture4 = texelFetch(colortex4, texelCoord, 0);
    
    z0 = texelFetch(depthtex0, texelCoord, 0).r;
    z1 = texelFetch(depthtex1, texelCoord, 0).r;

    #ifdef ATM_COLOR_MULTS
        atmColorMult = GetAtmColorMult();
        sqrtAtmColorMult = sqrt(atmColorMult);
    #endif

    vec4 reflectOutput = vec4(0.0);
    if (
        z0 < 1.0
        #if WORLD_SPACE_REFLECTIONS_INTERNAL == -1 || WATER_REFLECT_QUALITY <= 0
            && z0 == z1
        #endif
    ) {
        vec3 texture6 = texelFetch(colortex6, texelCoord, 0).rgb;
        vec3 texture8 = texelFetch(colortex8, texelCoord, 0).rgb;
        vec3 normalM = mat3(gbufferModelView) * texture4.rgb;
        vec4 screenPos = vec4(texCoord, z0, 1.0);
        vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;
        float lViewPos = length(viewPos);
        vec3 nViewPos = normalize(viewPos.xyz);
        vec3 playerPos = ViewToPlayer(viewPos.xyz);
        bool entityOrHand = z0 < 0.56;

        float dither = texture2DLod(noisetex, gl_FragCoord.xy / 128.0, 0.0).b;
        #if defined TAA || defined PBR_REFLECTIONS
            dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
        #endif

        int materialMaskInt = int(texture6.g * 255.1);
        float skyLightFactor = texture6.b;
        float smoothnessD = texture6.r;
        float fresnelM = texture4.a;
        float intenseFresnel = 0.0;
        float ssao = 1.0;
        vec3 reflectColor = vec3(1.0);

        #include "/lib/materials/materialHandling/deferredMaterials.glsl"

        float fresnel = clamp(1.0 + dot(normalM, nViewPos), 0.0, 1.0);

        if (fresnelM > 0.0) {
            #ifdef TAA
                float noiseMult = 0.3;
            #else
                float noiseMult = 0.3;
            #endif
            #ifdef PBR_REFLECTIONS
                bool opaqueSurface = z0 == z1;
                float minBlendFactor = 0.035 + 0.09 * pow2(pow2(pow2(smoothnessD)));

                if (entityOrHand) {
                    noiseMult *= 0.125;
                    minBlendFactor = 0.125;
                    if (!opaqueSurface) reflectColor = vec3(0.0);
                }
            #endif
            noiseMult *= pow2(1.0 - smoothnessD);

            vec2 roughCoord = gl_FragCoord.xy / 128.0;
            vec3 roughNoise = vec3(
                texture2DLod(noisetex, roughCoord, 0.0).r,
                texture2DLod(noisetex, roughCoord + 0.09375, 0.0).r,
                texture2DLod(noisetex, roughCoord + 0.1875, 0.0).r
            );
            roughNoise = fract(roughNoise + vec3(dither, dither * goldenRatio, dither * pow2(goldenRatio)));
            roughNoise = noiseMult * (roughNoise - vec3(0.5));

            vec3 refNormal = normalM + roughNoise;

            vec4 reflection = GetReflection(refNormal, viewPos.xyz, nViewPos, playerPos, lViewPos, z0,
                                            depthtex1, dither, skyLightFactor, fresnel,
                                            smoothnessD, vec3(0.0), vec3(0.0), vec3(0.0), 0.0);
            
            reflection.rgb *= reflectColor;
            reflectOutput = reflection;

            #ifdef PBR_REFLECTIONS
                if (opaqueSurface) {
                    refDist = min(refDist, far - lViewPos);
                    vec4 virtualRefPos = vec4(viewPos.xyz + refDist * nViewPos, 1.0);
                    vec4 playerVirtualRefPos = gbufferModelViewInverse * virtualRefPos; // note: don't need to do perspective division with model view matrix
                    vec4 virtualPrevRefPos = playerVirtualRefPos;
                    virtualPrevRefPos.xyz -= previousCameraPosition - cameraPosition;
                    virtualPrevRefPos = gbufferPreviousProjection * (gbufferPreviousModelView * virtualPrevRefPos);
                    virtualPrevRefPos.xyz = 0.5 * virtualPrevRefPos.xyz / virtualPrevRefPos.w + 0.5;
                    virtualPrevRefPos.z = min(1, virtualPrevRefPos.z);
                    if (virtualPrevRefPos.xyz == clamp01(virtualPrevRefPos.xyz)) {
                        vec4 prevPos = gbufferProjection * (
                            gbufferModelView * vec4(
                                playerPos + (cameraPosition - previousCameraPosition) +
                                gbufferModelViewInverse[3].xyz - transpose(mat3(gbufferPreviousModelView)) * gbufferPreviousModelView[3].xyz
                                , 1.0
                            )
                        );
                        prevPos.xyz = 0.5 * prevPos.xyz / prevPos.w + 0.5;
                        virtualPrevRefPos.xy *= view;
                        virtualPrevRefPos.xy = (
                            smoothstep(0, 1, smoothstep(0, 1, fract(virtualPrevRefPos.xy - 0.5))) +
                            floor(virtualPrevRefPos.xy - 0.5) +
                            0.5
                        ) / view;

                        float linearZ1 = GetLinearDepth(z1);
                        vec2 pixelMovement = view * (prevPos.xy - texCoord);
                        vec3 prevNormalM = mat3(gbufferModelView) * texture2D(colortex1, virtualPrevRefPos.xy).rgb;

                        vec4 prevRefCurrentPosHeuristic = playerVirtualRefPos;
                        prevRefCurrentPosHeuristic.xyz += normalize(previousCameraPosition - cameraPosition - playerVirtualRefPos.xyz) * refDist;
                        prevRefCurrentPosHeuristic = gbufferProjection * (gbufferModelView * prevRefCurrentPosHeuristic);
                        prevRefCurrentPosHeuristic.xyz = 0.5 * prevRefCurrentPosHeuristic.xyz / prevRefCurrentPosHeuristic.w + 0.5;

                        vec4 prevRef = texture2D(colortex7, virtualPrevRefPos.xy);
                        float prevValid = exp(
                            - 0.03 * length(view * (virtualPrevRefPos.xy - texCoord))
                            - min(0.75, 10.0 * sqrt(length(cameraPosition - previousCameraPosition)))
                            - 0.003 * length(pixelMovement)
                            - 12.0 * length(normalM - prevNormalM)
                            - abs(prevRef.a - linearZ1) * far / 1.0
                            - 10 * length(prevRefCurrentPosHeuristic.xy - clamp01(prevRefCurrentPosHeuristic.xy))
                        );

                        reflectOutput.rgb = mix(prevRef.rgb, reflectOutput.rgb, min1(minBlendFactor / prevValid));
                        reflectOutput.a = linearZ1;
                    }
                }
            #endif
        }
    }

    /* DRAWBUFFERS:7 */
    gl_FragData[0] = reflectOutput;

    // same check as #ifdef PBR_REFLECTIONS but for Optifine to understand:
    #if BLOCK_REFLECT_QUALITY >= 2 && RP_MODE >= 1
        /* DRAWBUFFERS:71 */
        gl_FragData[1] = vec4(texture4.rgb, 1.0);
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

out vec3 sunVec;

#ifdef END
    out float vlFactor;
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();
    
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    sunVec = GetSunVector();

    #ifdef END
        vlFactor = texelFetch(colortex5, ivec2(viewWidth-1, viewHeight-1), 0).a;
    #endif
}

#endif
