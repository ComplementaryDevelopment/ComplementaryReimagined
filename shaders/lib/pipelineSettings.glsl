/*
const int colortex0Format = R11F_G11F_B10F; //main color
const int colortex1Format = RGBA8;			//smoothnessD & materialMask & skyLightFactor
const int colortex2Format = RGBA16;		    //taa
const int colortex3Format = RGBA8;		    //(cloud/water map on deferred) | translucentMult & bloom & final color // can replace colortex8
const int colortex4Format = R8;				//volumetric cloud linear depth & volumetric light factor
const int colortex5Format = RGBA8_SNORM;    //normalM & scene image for water reflections

const int colortex6Format = R16;		    //previous depth
const int colortex7Format = RGBA16F;		//(cloud/water map on gbuffers) | temporal filter

const int colortex8Format = RGBA8;          //light source info but replaces colortex3 to work as colorimg3
*/
const bool colortex0Clear = true;
const bool colortex1Clear = true;
const bool colortex2Clear = false;
#ifndef LIGHT_COLORING
const bool colortex3Clear = true;
#else
const bool colortex3Clear = false;
#endif
const bool colortex4Clear = false;
const bool colortex5Clear = false;

const bool colortex6Clear = false;
const bool colortex7Clear = false;

const bool colortex8Clear = false;
//

const int noiseTextureResolution = 128;

const bool shadowHardwareFiltering = true;
const float shadowDistanceRenderMul = 1.0;
const float entityShadowDistanceMul = 0.125; // Iris feature

const float drynessHalflife = 300.0;
const float wetnessHalflife = 300.0;

const float ambientOcclusionLevel = 1.0;