const float regularEdge = 20.0;
const float extraEdgeMult = 3.0;

// Previous frame reprojection from Chocapic13
vec2 Reprojection(vec3 pos, vec3 cameraOffset) {
	pos = pos * 2.0 - 1.0;

	vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0);
	viewPosPrev /= viewPosPrev.w;
	viewPosPrev = gbufferModelViewInverse * viewPosPrev;

	vec4 previousPosition = viewPosPrev + vec4(cameraOffset, 0.0);
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
}

ivec2 neighbourhoodOffsets[8] = ivec2[8](
	ivec2(-1, -1),
	ivec2( 0, -1),
	ivec2( 1, -1),
	ivec2(-1,  0),
	ivec2( 1,  0),
	ivec2(-1,  1),
	ivec2( 0,  1),
	ivec2( 1,  1)
);

void NeighbourhoodClamping(vec3 color, inout vec3 tempColor, float depth, inout float edge) {
	vec3 minclr = color, maxclr = color;

	for (int i = 0; i < 8; i++) {
		ivec2 texelCoordM = texelCoord + neighbourhoodOffsets[i];

		float depthCheck = texelFetch(depthtex1, texelCoordM, 0).r;
		if (abs(GetLinearDepth(depthCheck) - GetLinearDepth(depth)) > 0.09) {
			edge = regularEdge;

			if (int(texelFetch(colortex1, texelCoordM, 0).g * 255.1) == 253) // Reduced Edge TAA
				edge *= extraEdgeMult;
		}

		#ifndef LIGHT_COLORING
			vec3 clr = texelFetch(colortex3, texelCoordM, 0).rgb;
		#else
			vec3 clr = texelFetch(colortex8, texelCoordM, 0).rgb;
		#endif
		minclr = min(minclr, clr); maxclr = max(maxclr, clr);
	}

	tempColor = clamp(tempColor, minclr, maxclr);
}

void DoTAA(inout vec3 color, inout vec3 temp, float depth) {
	int materialMask = int(texelFetch(colortex1, texelCoord, 0).g * 255.1);

	if (materialMask == 254) return; // No SSAO, No TAA

	#ifndef TEMPORAL_FILTER
		depth = texelFetch(depthtex1, texelCoord, 0).r;
	#endif

	#ifdef CUSTOM_PBR
		if (depth <= 0.56) return; // materialMask might be occupied, so we do the check manually
	#endif

	vec3 coord = vec3(texCoord, depth);
	vec3 cameraOffset = cameraPosition - previousCameraPosition;
	vec2 prvCoord = Reprojection(coord, cameraOffset);
	
	vec2 view = vec2(viewWidth, viewHeight);
	vec3 tempColor = texture2D(colortex2, prvCoord).rgb;
	if (tempColor == vec3(0.0)) { // Fixes the first frame
		temp = color;
		return;
	}

	float edge = 0.0;
	NeighbourhoodClamping(color, tempColor, depth, edge);

	if (materialMask == 253) // Reduced Edge TAA
		edge *= extraEdgeMult;
	
	vec2 velocity = (texCoord - prvCoord.xy) * view;
	float blendFactor = float(prvCoord.x > 0.0 && prvCoord.x < 1.0 &&
	                          prvCoord.y > 0.0 && prvCoord.y < 1.0);
	//float blendMinimum = 0.6;
	//float blendVariable = 0.5;
	//float blendConstant = 0.4;
	float blendMinimum = 0.3;
	float blendVariable = 0.25;
	float blendConstant = 0.65;
	float velocityFactor = dot(velocity, velocity) * 10.0;
	blendFactor *= max(exp(-velocityFactor) * blendVariable + blendConstant - length(cameraOffset) * edge, blendMinimum);
	
	color = mix(color, tempColor, blendFactor);
	temp = color;

	//if (edge > 0.05) color.rgb = vec3(1.0, 0.0, 1.0);
}