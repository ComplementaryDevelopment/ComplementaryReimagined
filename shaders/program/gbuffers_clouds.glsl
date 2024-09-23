/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

#if CLOUD_STYLE_DEFINE == 50
// We use CLOUD_STYLE_DEFINE instead of CLOUD_STYLE in this file because Optifine can't use generated defines for pipeline stuff
    in vec2 texCoord;

    flat in vec3 upVec, sunVec;

    in vec4 glColor;
#endif

//Pipeline Constants//

//Common Variables//
#if CLOUD_STYLE_DEFINE == 50
    float SdotU = dot(sunVec, upVec);
    float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
    float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
    float sunVisibility2 = sunVisibility * sunVisibility;
#endif

//Common Functions//

//Includes//
#if CLOUD_STYLE_DEFINE == 50
    #include "/lib/colors/skyColors.glsl"
    #include "/lib/util/spaceConversion.glsl"

    #if defined TAA && defined BORDER_FOG
        #include "/lib/antialiasing/jitter.glsl"
    #endif

    #ifdef ATM_COLOR_MULTS
        #include "/lib/colors/colorMultipliers.glsl"
    #endif
    #ifdef MOON_PHASE_INF_ATMOSPHERE
        #include "/lib/colors/moonPhaseInfluence.glsl"
    #endif

    #ifdef COLOR_CODED_PROGRAMS
        #include "/lib/misc/colorCodedPrograms.glsl"
    #endif
#endif

//Program//
void main() {
    #if CLOUD_STYLE_DEFINE != 50
        discard;
    #else
        vec4 color = texture2D(tex, texCoord) * glColor;

        vec4 translucentMult = vec4(mix(vec3(0.666), color.rgb * (1.0 - pow2(pow2(color.a))), color.a), 1.0);

        #ifdef OVERWORLD
            vec3 cloudLight = mix(vec3(0.8, 1.6, 1.5) * sqrt1(nightFactor), mix(dayDownSkyColor, dayMiddleSkyColor, 0.1), sunFactor);
            color.rgb *= sqrt(cloudLight) * (1.2 + 0.4 * noonFactor * invRainFactor);

            #if CLOUD_R != 100 || CLOUD_G != 100 || CLOUD_B != 100
                color.rgb *= vec3(CLOUD_R, CLOUD_G, CLOUD_B) * 0.01;
            #endif
            #ifdef ATM_COLOR_MULTS
                color.rgb *= sqrt(GetAtmColorMult()); // C72380KD - Reduced atmColorMult impact on things
            #endif
            #ifdef MOON_PHASE_INF_ATMOSPHERE
                color.rgb *= moonPhaseInfluence;
            #endif
        #endif

        #if defined BORDER_FOG && !defined DREAM_TWEAKED_BORDERFOG
            vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
            #ifdef TAA
                vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
            #else
                vec3 viewPos = ScreenToView(screenPos);
            #endif
            vec3 playerPos = ViewToPlayer(viewPos);

            float xzMaxDistance = max(abs(playerPos.x), abs(playerPos.z));
            float cloudDistance = 375.0;
            cloudDistance = clamp((cloudDistance - xzMaxDistance) / cloudDistance, 0.0, 1.0);
            color.a *= clamp01(cloudDistance * 3.0);
        #endif

        #ifdef COLOR_CODED_PROGRAMS
            ColorCodeProgram(color, -1);
        #endif

        /* DRAWBUFFERS:063 */
        gl_FragData[0] = color;
        gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
        gl_FragData[2] = vec4(1.0 - translucentMult.rgb, translucentMult.a);
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

#if CLOUD_STYLE_DEFINE == 50
    out vec2 texCoord;

    flat out vec3 upVec, sunVec;

    out vec4 glColor;
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//
#if CLOUD_STYLE_DEFINE == 50
    #ifdef TAA
        #include "/lib/antialiasing/jitter.glsl"
    #endif
#endif

//Program//
void main() {
    #if CLOUD_STYLE_DEFINE != 50
        gl_Position = vec4(-1.0);
    #else
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        glColor = gl_Color;

        upVec = normalize(gbufferModelView[1].xyz);
        sunVec = GetSunVector();

        vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
        gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

        #ifdef TAA
            gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
        #endif
    #endif
}

#endif
