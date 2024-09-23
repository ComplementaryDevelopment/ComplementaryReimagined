/*----------------------------------------------------------------------------------------------
        _____                                                                    _____
        ( ___ )                                                                  ( ___ )
        |   |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|   |
        |   | ██╗   ██╗███╗   ██╗██╗███████╗ ██████╗ ██████╗ ███╗   ███╗███████╗ |   |
        |   | ██║   ██║████╗  ██║██║██╔════╝██╔═══██╗██╔══██╗████╗ ████║██╔════╝ |   |
        |   | ██║   ██║██╔██╗ ██║██║█████╗  ██║   ██║██████╔╝██╔████╔██║███████╗ |   |
        |   | ██║   ██║██║╚██╗██║██║██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║╚════██║ |   |
        |   | ╚██████╔╝██║ ╚████║██║██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████║ |   |
        |   |  ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝ |   |
        |___|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|___|
        (_____)                              (thanks to isuewo and SpacEagle17)  (_____)

---------------------------------------------------------------------------------------------*/

uniform int blockEntityId;
uniform int currentRenderedItemId;
uniform int entityId;
uniform int frameCounter;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int heldItemId;
uniform int heldItemId2;
uniform int isEyeInWater;
uniform int moonPhase;
uniform int worldTime;
uniform int worldDay;

uniform float aspectRatio;
uniform float blindness;
uniform float darknessFactor;
uniform float darknessLightFactor;
uniform float maxBlindnessDarkness;
uniform float eyeAltitude;
uniform float frameTime;
uniform float frameTimeCounter;
uniform float far;
uniform float near;
uniform float nightVision;
uniform float rainStrength;
uniform float screenBrightness;
uniform float viewHeight;
uniform float viewWidth;
uniform float wetness;
uniform float sunAngle;
uniform float playerMood;

uniform ivec2 atlasSize;
uniform ivec2 eyeBrightness;

uniform vec3 cameraPosition;
uniform vec3 fogColor;
uniform vec3 previousCameraPosition;
uniform vec3 skyColor;
uniform vec3 relativeEyePosition;

uniform vec4 entityColor;
uniform vec4 lightningBoltPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform sampler2D normals;
uniform sampler2D noisetex;
uniform sampler2D specular;
uniform sampler2D tex;

uniform ivec3 cameraPositionInt;
uniform ivec3 previousCameraPositionInt;
uniform vec3 cameraPositionFract;
uniform vec3 previousCameraPositionFract;

#if SHADOW_QUALITY > -1 || defined LIGHTSHAFTS_ACTIVE || defined FF_BLOCKLIGHT
    uniform sampler2D shadowcolor0;
    uniform sampler2D shadowcolor1;

    uniform sampler2DShadow shadowtex1;

    #ifdef COMPOSITE
        uniform sampler2D shadowtex0;
    #else
        uniform sampler2DShadow shadowtex0;
    #endif
#endif

#if !defined DH_TERRAIN && !defined DH_WATER
    uniform mat4 gbufferProjection;
    uniform mat4 gbufferProjectionInverse;
#endif

#ifdef DISTANT_HORIZONS
    uniform int dhRenderDistance;

    uniform mat4 dhProjection;
    uniform mat4 dhProjectionInverse;
    
    uniform sampler2D dhDepthTex;
    uniform sampler2D dhDepthTex1;
#endif

#if COLORED_LIGHTING_INTERNAL > 0
    uniform usampler3D voxel_sampler;
    uniform sampler3D floodfill_sampler;
    uniform sampler3D floodfill_sampler_copy;
#endif

#ifdef PUDDLE_VOXELIZATION
    uniform usampler2D puddle_sampler;
#endif

/*-----------------------------------------------------------------------------
  ___ _   _ ___ _____ ___  __  __   _   _ _  _ ___ ___ ___  ___ __  __ ___
 / __| | | / __|_   _/ _ \|  \/  | | | | | \| |_ _| __/ _ \| _ \  \/  / __|
| (__| |_| \__ \ | || (_) | |\/| | | |_| | .` || || _| (_) |   / |\/| \__ \
 \___|\___/|___/ |_| \___/|_|  |_|  \___/|_|\_|___|_| \___/|_|_\_|  |_|___/

-----------------------------------------------------------------------------*/

uniform float framemod8;
uniform float isEyeInCave;
uniform float inDry;
uniform float inRainy;
uniform float inSnowy;
uniform float velocity;
uniform float starter;
uniform float frameTimeSmooth;
uniform float eyeBrightnessM;
uniform float eyeBrightnessM2;
uniform float rainFactor;
uniform float inBasaltDeltas;
uniform float inCrimsonForest;
uniform float inNetherWastes;
uniform float inSoulValley;
uniform float inWarpedForest;

uniform vec3 skyColorSmooth;
