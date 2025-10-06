/*
const int colortex0Format = R11F_G11F_B10F; //main color
const int colortex1Format = RGB8_SNORM;     //half res normalM
const int colortex2Format = RGB16F;         //taa
const int colortex3Format = RGBA8;          //(cloud/water map on deferred/gbuffer) | translucentMult & bloom & final color
const int colortex4Format = RGBA8_SNORM;    //normalM & reflection strength
const int colortex5Format = RGBA8;          //scene image for water reflections & volumetric cloud linear depth & volumetric light factor
const int colortex6Format = RGB8;           //smoothnessD & materialMask & skyLightFactor
const int colortex7Format = RGBA16F;        //(cloud/water map on gbuffer) | reflection temporal image (rgb) & previous depth
const int colortex8Format = RGBA16F;        //SSR results for WSR, topmost translucent opacity
*/

const bool colortex0Clear = true;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = true;
const bool colortex4Clear = false;
const bool colortex5Clear = false;
const bool colortex6Clear = true;
const bool colortex7Clear = false;
const bool colortex8Clear = true;
//

const int noiseTextureResolution = 128;

const bool shadowHardwareFiltering = true;
const float shadowDistanceRenderMul = 1.0;
const float entityShadowDistanceMul = 0.125; // Iris feature

const float drynessHalflife = 300.0;
const float wetnessHalflife = 300.0;

const float ambientOcclusionLevel = 1.0;