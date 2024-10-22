/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

flat in int mat;

in vec2 texCoord;

flat in vec3 sunVec, upVec;

in vec4 position;
flat in vec4 glColor;

#ifdef CONNECTED_GLASS_EFFECT
    in vec2 signMidCoordPos;
    flat in vec2 absMidCoordPos;
#endif

//Pipeline Constants//

//Common Variables//
float SdotU = dot(sunVec, upVec);
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;

//Common Functions//
void DoNaturalShadowCalculation(inout vec4 color1, inout vec4 color2) {
    color1.rgb *= glColor.rgb;
    color1.rgb = mix(vec3(1.0), color1.rgb, pow(color1.a, (1.0 - color1.a) * 0.5) * 1.05);
    color1.rgb *= 1.0 - pow(color1.a, 64.0);
    color1.rgb *= 0.2; // Natural Strength

    color2.rgb = normalize(color1.rgb) * 0.5;
}

//Includes//
#ifdef CONNECTED_GLASS_EFFECT
    #include "/lib/materials/materialMethods/connectedGlass.glsl"
#endif

//Program//
void main() {
    vec4 color1 = texture2DLod(tex, texCoord, 0); // Shadow Color

    #if SHADOW_QUALITY >= 1
        vec4 color2 = color1; // Light Shaft Color

        color2.rgb *= 0.25; // Natural Strength

        #if defined LIGHTSHAFTS_ACTIVE && LIGHTSHAFT_BEHAVIOUR == 1 && defined OVERWORLD
            float positionYM = position.y;
        #endif

        if (mat < 32008) {
            if (mat < 32000) {
                #ifdef CONNECTED_GLASS_EFFECT
                    if (mat == 30008) { // Tinted Glass
                        DoSimpleConnectedGlass(color1);
                    }
                    if (mat >= 31000) { // Stained Glass, Stained Glass Pane
                        DoSimpleConnectedGlass(color1);
                    }
                #endif
                DoNaturalShadowCalculation(color1, color2);
            } else {
                if (mat == 32000) { // Water
                    vec3 worldPos = position.xyz + cameraPosition;

                    #if defined LIGHTSHAFTS_ACTIVE && LIGHTSHAFT_BEHAVIOUR == 1 && defined OVERWORLD
                        // For scene-aware light shafts to be more prone to get extreme near water
                        positionYM += 3.5;
                    #endif

                    // Water Caustics
                    #if WATER_CAUSTIC_STYLE < 3
                        #if MC_VERSION >= 11300
                            float wcl = GetLuminance(color1.rgb);
                            color1.rgb = color1.rgb * pow2(wcl) * 1.2;
                        #else
                            color1.rgb = mix(color1.rgb, vec3(GetLuminance(color1.rgb)), 0.88);
                            color1.rgb = pow2(color1.rgb) * vec3(2.5, 3.0, 3.0) * 0.96;
                        #endif
                    #else
                        #define WATER_SPEED_MULT_M WATER_SPEED_MULT * 0.035
                        vec2 causticWind = vec2(frameTimeCounter * WATER_SPEED_MULT_M, 0.0);
                        vec2 cPos1 = worldPos.xz * 0.10 - causticWind;
                        vec2 cPos2 = worldPos.xz * 0.05 + causticWind;

                        float cMult = 14.0;
                        float offset = 0.001;

                        float caustic = 0.0;
                        caustic += dot(texture2D(gaux4, cPos1 + vec2(offset, 0.0)).rg, vec2(cMult))
                                 - dot(texture2D(gaux4, cPos1 - vec2(offset, 0.0)).rg, vec2(cMult));
                        caustic += dot(texture2D(gaux4, cPos2 + vec2(0.0, offset)).rg, vec2(cMult))
                                 - dot(texture2D(gaux4, cPos2 - vec2(0.0, offset)).rg, vec2(cMult));
                        color1.rgb = vec3(max0(min1(caustic * 0.8 + 0.35)) * 0.65 + 0.35);

                        #if MC_VERSION < 11300
                            color1.rgb *= vec3(0.3, 0.45, 0.9);
                        #endif
                    #endif

                    #if MC_VERSION >= 11300
                        #if WATERCOLOR_MODE >= 2
                            color1.rgb *= glColor.rgb;
                        #else
                            color1.rgb *= vec3(0.3, 0.45, 0.9);
                        #endif
                    #endif
                    color1.rgb *= vec3(0.6, 0.8, 1.1);
                    ////

                    // Underwater Light Shafts
                    vec3 worldPosM = worldPos;

                    #if WATER_FOG_MULT > 100
                        #define WATER_FOG_MULT_M WATER_FOG_MULT * 0.01;
                        worldPosM *= WATER_FOG_MULT_M;
                    #endif

                    vec2 waterWind = vec2(syncedTime * 0.01, 0.0);
                    float waterNoise = texture2D(noisetex, worldPosM.xz * 0.012 - waterWind).g;
                        waterNoise += texture2D(noisetex, worldPosM.xz * 0.05 + waterWind).g;

                    float factor = max(2.5 - 0.025 * length(position.xz), 0.8333) * 1.3;
                    waterNoise = pow(waterNoise * 0.5, factor) * factor * 1.3;

                    #if MC_VERSION >= 11300 && WATERCOLOR_MODE >= 2
                        color2.rgb = normalize(sqrt1(glColor.rgb)) * vec3(0.24, 0.22, 0.26);
                    #else
                        color2.rgb = vec3(0.08, 0.12, 0.195);
                    #endif
                    color2.rgb *= waterNoise * (1.0 + sunVisibility - rainFactor);
                    ////

                    #ifdef UNDERWATERCOLOR_CHANGED
                        color1.rgb *= vec3(UNDERWATERCOLOR_RM, UNDERWATERCOLOR_GM, UNDERWATERCOLOR_BM);
                        color2.rgb *= vec3(UNDERWATERCOLOR_RM, UNDERWATERCOLOR_GM, UNDERWATERCOLOR_BM);
                    #endif
                } else /*if (mat == 32004)*/ { // Ice
                    color1.rgb *= color1.rgb;
                    color1.rgb *= color1.rgb;
                    color1.rgb = mix(vec3(1.0), color1.rgb, pow(color1.a, (1.0 - color1.a) * 0.5) * 1.05);
                    color1.rgb *= 1.0 - pow(color1.a, 64.0);
                    color1.rgb *= 0.28;

                    color2.rgb = normalize(pow(color1.rgb, vec3(0.25))) * 0.5;
                }
            }
        } else {
            if (mat < 32020) { // Glass, Glass Pane, Beacon (32008, 32012, 32016)
                #ifdef CONNECTED_GLASS_EFFECT
                    if (mat == 32008) { // Glass
                        DoSimpleConnectedGlass(color1);
                    }
                    if (mat == 32012) { // Glass Pane
                        DoSimpleConnectedGlass(color1);
                    }
                #endif
                if (color1.a > 0.5) color1 = vec4(0.0, 0.0, 0.0, 1.0);
                else color1 = vec4(vec3(0.2 * (1.0 - GLASS_OPACITY)), 1.0);
                color2.rgb = vec3(0.3);
            } else {
                DoNaturalShadowCalculation(color1, color2);
            }
        }
    #endif

    gl_FragData[0] = color1; // Shadow Color

    #if SHADOW_QUALITY >= 1
        #if defined LIGHTSHAFTS_ACTIVE && LIGHTSHAFT_BEHAVIOUR == 1 && defined OVERWORLD
            color2.a = 0.25 + max0(positionYM * 0.05); // consistencyMEJHRI7DG
        #endif

        gl_FragData[1] = color2; // Light Shaft Color
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

flat out int mat;

out vec2 texCoord;

flat out vec3 sunVec, upVec;

out vec4 position;
flat out vec4 glColor;

#ifdef CONNECTED_GLASS_EFFECT
    out vec2 signMidCoordPos;
    flat out vec2 absMidCoordPos;
#endif

//Pipeline Constants//
#if COLORED_LIGHTING_INTERNAL > 0
    #extension GL_ARB_shader_image_load_store : enable
#endif

//Attributes//
attribute vec4 mc_Entity;

#if defined PERPENDICULAR_TWEAKS || defined WAVING_ANYTHING_TERRAIN || defined WAVING_WATER_VERTEX || defined CONNECTED_GLASS_EFFECT
    attribute vec4 mc_midTexCoord;
#endif

#if COLORED_LIGHTING_INTERNAL > 0
    attribute vec3 at_midBlock;
#endif

//Common Variables//
vec2 lmCoord;

#if COLORED_LIGHTING_INTERNAL > 0
    uniform int renderStage;
    writeonly uniform uimage3D voxel_img;

    #ifdef PUDDLE_VOXELIZATION
        writeonly uniform uimage2D puddle_img;
    #endif
#endif

//Common Functions//

//Includes//
#include "/lib/util/spaceConversion.glsl"

#if defined WAVING_ANYTHING_TERRAIN || defined WAVING_WATER_VERTEX
    #include "/lib/materials/materialMethods/wavingBlocks.glsl"
#endif

#if COLORED_LIGHTING_INTERNAL > 0
    #include "/lib/misc/voxelization.glsl"

    #ifdef PUDDLE_VOXELIZATION
        #include "/lib/misc/puddleVoxelization.glsl"
    #endif
#endif

//Program//
void main() {
    texCoord = gl_MultiTexCoord0.xy;
    lmCoord = GetLightMapCoordinates();
    glColor = gl_Color;
    sunVec = GetSunVector();
    upVec = normalize(gbufferModelView[1].xyz);
    mat = int(mc_Entity.x + 0.5);

    position = shadowModelViewInverse * shadowProjectionInverse * ftransform();

    #if defined WAVING_ANYTHING_TERRAIN || defined WAVING_WATER_VERTEX
        DoWave(position.xyz, mat);
    #endif

    #ifdef CONNECTED_GLASS_EFFECT
        vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
        vec2 texMinMidCoord = texCoord - midCoord;
        signMidCoordPos = sign(texMinMidCoord);
        absMidCoordPos  = abs(texMinMidCoord);
    #endif

    #ifdef PERPENDICULAR_TWEAKS
        if (mat == 10005 || mat == 10017) { // Foliage
            #ifndef CONNECTED_GLASS_EFFECT
                vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
                vec2 texMinMidCoord = texCoord - midCoord;
            #endif
            if (texMinMidCoord.y < 0.0) {
                vec3 normal = gl_NormalMatrix * gl_Normal;
                position.xyz += normal * 0.35;
            }
        }
    #endif

    if (mat == 32000) { // Water
        position.y += 0.015 * max0(length(position.xyz) - 50.0);
    }

    #if COLORED_LIGHTING_INTERNAL > 0
        if (gl_VertexID % 4 == 0) {
            UpdateVoxelMap(mat);
            #ifdef PUDDLE_VOXELIZATION
                UpdatePuddleVoxelMap(mat);
            #endif
        }
    #endif

    gl_Position = shadowProjection * shadowModelView * position;

    float lVertexPos = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
    float distortFactor = lVertexPos * shadowMapBias + (1.0 - shadowMapBias);
    gl_Position.xy *= 1.0 / distortFactor;
    gl_Position.z = gl_Position.z * 0.2;
}

#endif
