////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

#ifdef BLOOM_FOG
	flat in vec3 upVec, sunVec;
#endif

//Uniforms//
uniform int frameCounter;

uniform float viewWidth, viewHeight;
uniform float darknessFactor;

uniform float frameTimeCounter;

uniform sampler2D colortex0;
uniform sampler2D noisetex;

#ifdef BLOOM
	#ifndef LIGHT_COLORING
		uniform sampler2D colortex3;
	#else
		uniform sampler2D colortex8;
	#endif
#endif

#ifdef BLOOM_FOG
	uniform int isEyeInWater;

	#ifdef NETHER
		uniform float far;
	#endif
#endif

#ifdef BLOOM_FOG
	uniform vec3 cameraPosition;

	uniform mat4 gbufferProjectionInverse;
	
	uniform sampler2D depthtex0;
#endif

//Pipeline Constants//

//Common Variables//
float pw = 1.0 / viewWidth;
float ph = 1.0 / viewHeight;

#ifdef BLOOM_FOG
	float SdotU = dot(sunVec, upVec);
	float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
#endif

//Common Functions//
void DoBSLTonemap(inout vec3 color) {
	color = T_EXPOSURE * color;
	color = color / pow(pow(color, vec3(TM_WHITE_CURVE)) + 1.0, vec3(1.0 / TM_WHITE_CURVE));
	color = pow(color, mix(vec3(T_LOWER_CURVE), vec3(T_UPPER_CURVE), sqrt(color)));
	
	color = pow(color, vec3(1.0 / 2.2));
}

void DoBSLColorSaturation(inout vec3 color) {
	float grayVibrance = (color.r + color.g + color.b) / 3.0;
	float graySaturation = grayVibrance;
	if (T_SATURATION < 1.00) graySaturation = dot(color, vec3(0.299, 0.587, 0.114));

	float mn = min(color.r, min(color.g, color.b));
	float mx = max(color.r, max(color.g, color.b));
	float sat = (1.0 - (mx - mn)) * (1.0 - mx) * grayVibrance * 5.0;
	vec3 lightness = vec3((mn + mx) * 0.5);

	color = mix(color, mix(color, lightness, 1.0 - T_VIBRANCE), sat);
	color = mix(color, lightness, (1.0 - lightness) * (2.0 - T_VIBRANCE) / 2.0 * abs(T_VIBRANCE - 1.0));
	color = color * T_SATURATION - graySaturation * (T_SATURATION - 1.0);
}

vec3 GetBloomTile(float lod, vec2 coord, vec2 offset, vec2 ditherAdd) {
	float scale = exp2(lod);
	vec2 bloomCoord = coord / scale + offset;
	bloomCoord += ditherAdd;
	bloomCoord = clamp(bloomCoord, offset, 1.0 / scale + offset);

	#ifndef LIGHT_COLORING
		vec3 bloom = texture2D(colortex3, bloomCoord).rgb;
	#else
		vec3 bloom = texture2D(colortex8, bloomCoord).rgb;
	#endif
	bloom *= bloom;
	bloom *= bloom;
	return bloom * 128.0;
}

void DoBloom(inout vec3 color, vec2 coord, float dither, float lViewPos) {
	vec2 rescale = 1.0 / vec2(1920.0, 1080.0);
	vec2 ditherAdd = vec2(0.0);
	float ditherM = dither - 0.5;
	if (rescale.x > pw) ditherAdd.x += ditherM * pw;
	if (rescale.y > ph) ditherAdd.y += ditherM * ph;

	vec3 blur1 = GetBloomTile(2.0, coord, vec2(0.0      , 0.0   ), ditherAdd);
	vec3 blur2 = GetBloomTile(3.0, coord, vec2(0.0      , 0.26  ), ditherAdd);
	vec3 blur3 = GetBloomTile(4.0, coord, vec2(0.135    , 0.26  ), ditherAdd);
	vec3 blur4 = GetBloomTile(5.0, coord, vec2(0.2075   , 0.26  ), ditherAdd);
	vec3 blur5 = GetBloomTile(6.0, coord, vec2(0.135    , 0.3325), ditherAdd);
	vec3 blur6 = GetBloomTile(7.0, coord, vec2(0.160625 , 0.3325), ditherAdd);
	vec3 blur7 = GetBloomTile(8.0, coord, vec2(0.1784375, 0.3325), ditherAdd);

	vec3 blur = (blur1 + blur2 + blur3 + blur4 + blur5 + blur6 + blur7) * 0.14;

	float bloomStrength = BLOOM_STRENGTH + 0.2 * darknessFactor;

	#if defined BLOOM_FOG && defined NETHER
		float netherBloom = lViewPos / max(far, 160.0);
		netherBloom *= netherBloom;
		netherBloom *= netherBloom;
		netherBloom = 1.0 - exp(-8.0 * netherBloom);
		bloomStrength = mix(bloomStrength, bloomStrength * 3.0, netherBloom);
	#endif

	color = mix(color, blur, bloomStrength);
}

//Includes//
#ifdef BLOOM_FOG
	#include "/lib/atmospherics/fog/bloomFog.glsl"
#endif

#ifdef BLOOM
	#include "/lib/util/dither.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef BLOOM_FOG
		float z0 = texture2D(depthtex0, texCoord).r;

		vec4 screenPos = vec4(texCoord, z0, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;
		float lViewPos = length(viewPos.xyz);

		color /= GetBloomFog(lViewPos);
	#else
		float lViewPos = 0.0;
	#endif

	float dither = texture2D(noisetex, texCoord * vec2(viewWidth, viewHeight) / 128.0).b;
	#ifdef TAA
		dither = fract(dither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	#ifdef BLOOM
		DoBloom(color, texCoord, dither, lViewPos);
	#endif

	#ifdef COLORGRADING
		color =
			pow(color.r, GR_RC) * vec3(GR_RR, GR_RG, GR_RB) +
			pow(color.g, GR_GC) * vec3(GR_GR, GR_GG, GR_GB) +
			pow(color.b, GR_BC) * vec3(GR_BR, GR_BG, GR_BB);
		color *= 0.01;
	#endif

	DoBSLTonemap(color);
	
	DoBSLColorSaturation(color);

	#ifdef VIGNETTE_R
		vec2 texCoordMin = texCoord.xy - 0.5;
		float vignette = 1.0 - dot(texCoordMin, texCoordMin) * (1.0 - GetLuminance(color));
		color *= vignette;
	#endif

	float filmGrain = dither;
	color += vec3((filmGrain - 0.25) / 128.0);

    #ifndef LIGHT_COLORING
    /* DRAWBUFFERS:3 */
    #else
    /* DRAWBUFFERS:8 */
    #endif
	gl_FragData[0] = vec4(color, 1.0);
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

#ifdef BLOOM_FOG
	flat out vec3 upVec, sunVec;
#endif

//Uniforms//

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	gl_Position = ftransform();

	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
		
	#ifdef BLOOM_FOG
		upVec = normalize(gbufferModelView[1].xyz);
		sunVec = GetSunVector();
	#endif
}

#endif
