vec2 worldOutlineOffset[8] = vec2[8] (
    vec2(-1.0, 1.0),
    vec2( 0,   1.0),
    vec2( 1.0, 1.0),
    vec2( 1.0, 0),
    vec2(-WORLD_OUTLINE_THICKNESS, WORLD_OUTLINE_THICKNESS),
    vec2( 0,                       WORLD_OUTLINE_THICKNESS),
    vec2( WORLD_OUTLINE_THICKNESS, WORLD_OUTLINE_THICKNESS),
    vec2( WORLD_OUTLINE_THICKNESS, 0)
);

void DoWorldOutline(inout vec3 color, float linearZ0) {
	vec2 scale = vec2(1.0 / view);

	float outlines[2] = float[2] (0.0, 0.0);
	float outlined = 1.0;
	float z = linearZ0 * far;
	float totalz = 0.0;
	float maxz = 0.0;
	float sampleza = 0.0;
	float samplezb = 0.0;

	#if WORLD_OUTLINE_THICKNESS == 0
		int sampleCount = 1;
	#else
		int sampleCount = 2;
	#endif

	for (int k = 0; k < sampleCount; k++) {
		for (int i = 0; i < 4; i++) {
			vec2 offset = scale * worldOutlineOffset[i * (1+k)];
			float depthCheckP = GetLinearDepth(texture2D(depthtex0, texCoord + offset).r) * far;
			float depthCheckN = GetLinearDepth(texture2D(depthtex0, texCoord - offset).r) * far;

			outlined *= clamp(1.0 - ((depthCheckP + depthCheckN) - z * 2.0) * 32.0 / z, 0.0, 1.0);

			if (k == 0) {
				maxz = max(maxz, max(depthCheckP, depthCheckN));
				totalz += depthCheckP + depthCheckN;
			}
		}

		float outlinea = 1.0 - clamp((z * 8.0 - totalz) * 64.0 / z, 0.0, 1.0) * clamp(1.0 - ((z * 8.0 - totalz) * 32.0 - 1.0) / z, 0.0, 1.0);
		float outlineb = clamp(1.0 + 8.0 * (z - maxz) / z, 0.0, 1.0);
		float outlinec = clamp(1.0 + 64.0 * (z - maxz) / z, 0.0, 1.0);
		
		outlines[k] = (0.35 * (outlinea * outlineb) + 0.65) * (0.75 * (1.0 - outlined) * outlinec + 1.0);
		outlines[k] -= 1.0;
	}

	float outline = outlines[0] + outlines[1] * 0.1;

    if (outline < 0.0) outline = -outline * 0.25;

	color += min(color * outline * 2.5, vec3(outline));
}