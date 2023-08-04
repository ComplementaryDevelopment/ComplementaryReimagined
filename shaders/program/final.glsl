////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

//Uniforms//
uniform float viewWidth, viewHeight;

#ifndef LIGHT_COLORING
	uniform sampler2D colortex3;
#else
	uniform sampler2D colortex3; /*test*//*test*//*test*//*test*/
	uniform sampler2D colortex8;
#endif

#ifdef UNDERWATER_DISTORTION
	uniform int isEyeInWater;

	uniform float frameTimeCounter;
#endif

//Pipeline Constants//
#include "/lib/pipelineSettings.glsl"

//Common Variables//

//Common Functions//
#if IMAGE_SHARPENING > 0
	vec2 viewD = 1.0 / vec2(viewWidth, viewHeight);

	vec2 sharpenOffsets[4] = vec2[4](
		vec2( viewD.x,  0.0),
		vec2( 0.0,  viewD.x),
		vec2(-viewD.x,  0.0),
		vec2( 0.0, -viewD.x)
	);

	void SharpenImage(inout vec3 color, vec2 texCoordM) {
		float mult = 0.0125 * IMAGE_SHARPENING;
		color *= 1.0 + 0.05 * IMAGE_SHARPENING;

		for (int i = 0; i < 4; i++) {
			#ifndef LIGHT_COLORING
				color -= texture2D(colortex3, texCoordM + sharpenOffsets[i]).rgb * mult;
			#else
				color -= texture2D(colortex8, texCoordM + sharpenOffsets[i]).rgb * mult;
			#endif
		}
	}
#endif

//Includes//
#ifdef MC_ANISOTROPIC_FILTERING
	#include "/lib/util/textRendering.glsl"

	void beginTextM(int textSize, vec2 offset) {
		beginText(ivec2(vec2(viewWidth, viewHeight) * texCoord) / textSize, ivec2(0 + offset.x, viewHeight / textSize - offset.y));
		text.bgCol = vec4(0.0);
	}
#endif

//Program//
void main() {
	vec2 texCoordM = texCoord;

	#ifdef UNDERWATER_DISTORTION
		if (isEyeInWater == 1)
			texCoordM += WATER_REFRACTION_INTENSITY * 0.00035 * sin((texCoord.x + texCoord.y) * 25.0 + frameTimeCounter * 3.0);
	#endif

	#ifndef LIGHT_COLORING
		vec3 color = texture2D(colortex3, texCoordM).rgb;
	#else
		vec3 color = texture2D(colortex8, texCoordM).rgb;
	#endif

	#if CHROMA_ABERRATION > 0
		vec2 scale = vec2(1.0, viewHeight / viewWidth);
		vec2 aberration = (texCoordM - 0.5) * (2.0 / vec2(viewWidth, viewHeight)) * scale * CHROMA_ABERRATION;
		#ifndef LIGHT_COLORING
			color.rb = vec2(texture2D(colortex3, texCoordM + aberration).r, texture2D(colortex3, texCoordM - aberration).b);
		#else
			color.rb = vec2(texture2D(colortex8, texCoordM + aberration).r, texture2D(colortex8, texCoordM - aberration).b);
		#endif
	#endif

	#if IMAGE_SHARPENING > 0
		SharpenImage(color, texCoordM);
	#endif

	#ifdef LIGHT_COLORING
		if (max(texCoordM.x, texCoordM.y) < 0.25) color = texture2D(colortex3, texCoordM * 4.0).rgb;
	#endif

	#ifdef MC_ANISOTROPIC_FILTERING
		color.rgb = mix(color.rgb, vec3(0.0), 0.75);

		beginTextM(8, vec2(6, 10));
		text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
		printString((_I, _m, _p, _o, _r, _t, _a, _n, _t, _space, _I, _s, _s, _u, _e, _space));
		endText(color.rgb);

		beginTextM(4, vec2(15, 30));
		printLine();
		text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);
		printString((
			_P, _l, _e, _a, _s, _e, _space, _g, _o, _space, _t, _o, _space,
			_E, _S, _C, _space, _minus, _space, _O, _p, _t, _i, _o, _n, _s, _space, _minus, _space
		));
		printLine();
		printString((
			_V, _i, _d, _e, _o, _space, _S, _e, _t, _t, _i, _n, _g, _s, _space, _minus, _space,
			_Q, _u, _a, _l, _i, _t, _y, _space, _minus, _space
		));
		printLine();
		printString((
			_a, _n, _d, _space, _d, _i, _s, _a, _b, _l, _e, _space,
			_A, _n, _i, _s, _o, _t, _r, _o, _p, _i, _c, _space, _F, _i, _l, _t, _e, _r, _i, _n, _g, _dot
		));
		endText(color.rgb);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

//Uniforms//

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	gl_Position = ftransform();
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif
