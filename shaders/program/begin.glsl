/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

#ifdef COMPUTE_SHADER

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);

#ifdef FRAME_DATA_WRITE

//Common Variables//
vec3 upVec = GetUpVector();
vec3 sunVec = GetSunVector();

float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;

//Includes//
#include "/lib/colors/lightAndAmbientColors.glsl"
#include "/lib/colors/skyColors.glsl"

#ifdef OVERWORLD
    void GetDeferred1LightColor(out vec3 lightColorV) {
        #define LAAC_DEFERRED1
        #include "/lib/colors/overworldLightColors.glsl"
        #undef LAAC_DEFERRED1
        lightColorV = lightColor;
    }

    void GetComposite1LightColors(out vec3 lightColorV, out vec3 ambientColorV) {
        #define LAAC_COMPOSITE1
        #include "/lib/colors/overworldLightColors.glsl"
        #undef LAAC_COMPOSITE1
        lightColorV = lightColor;
        ambientColorV = ambientColor;
    }
#endif

//Program//
void main() {
    fdTime = vec4(timeAngle, noonFactorRaw, noonFactor, nightFactor);
    fdSunVec = vec4(sunVec, 0.0);
    fdUpVec = vec4(upVec, 0.0);
    fdEastVec = vec4(GetEastVector(), 0.0);
    fdNorthVec = vec4(GetNorthVector(), 0.0);
    fdUnderwaterColorM1 = vec4(underwaterColorM1, 0.0);

    #ifdef OVERWORLD
        fdLightColor = vec4(lightColor, 0.0);
        fdAmbientColor = vec4(ambientColor, 0.0);
        fdHighlightColor = vec4(HIGHLIGHT_COLOR, 0.0);

        vec3 lightColorV, ambientColorV;
        GetDeferred1LightColor(lightColorV);
        fdLightColorD1 = vec4(lightColorV, 0.0);
        GetComposite1LightColors(lightColorV, ambientColorV);
        fdLightColorC1 = vec4(lightColorV, 0.0);
        fdAmbientColorC1 = vec4(ambientColorV, 0.0);

        fdDayUpSkyColor = vec4(dayUpSkyColor, 0.0);
        fdDayMiddleSkyColor = vec4(dayMiddleSkyColor, 0.0);
        fdDayDownSkyColor = vec4(dayDownSkyColor, 0.0);
        fdNightUpSkyColor = vec4(nightUpSkyColor, 0.0);
        fdNightMiddleSkyColor = vec4(nightMiddleSkyColor, 0.0);
        fdNightDownSkyColor = vec4(nightDownSkyColor, 0.0);
    #endif
}

#else

void main() {}

#endif

#endif
