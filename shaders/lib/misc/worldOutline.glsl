float WOO = 1.0;
float WOS = 1.0;

vec2 worldOutlineOffset[4] = vec2[4] (
    vec2(-WOO, WOO),
    vec2( 0,   WOO),
    vec2( WOO, WOO),
    vec2( WOO, 0)
);

void DoWorldOutline(inout vec3 color, float linearZ0) {
    vec2 scale = vec2(WOS) / view;

	float outlined = 1.0;
	float z = linearZ0 * far;
	float totalz = 0.0;
	float maxz = 0.0;
	float sampleza = 0.0;
	float samplezb = 0.0;

    for (int i = 0; i < 4; i++) {
        vec2 offsetCoordP = texCoord + worldOutlineOffset[i] * scale;
        vec2 offsetCoordN = texCoord - worldOutlineOffset[i] * scale;
	    float depthCheckP = GetLinearDepth(texture2D(depthtex0, offsetCoordP).r) * far;
	    float depthCheckN = GetLinearDepth(texture2D(depthtex0, offsetCoordN).r) * far;

		maxz = max(maxz, max(depthCheckP, depthCheckN));

		outlined *= clamp(1.0 - ((depthCheckP + depthCheckN) - z * 2.0) * 32.0 / z, 0.0, 1.0);

		totalz += depthCheckP + depthCheckN;
	}

	float outlinea = 1.0 - clamp((z * 8.0 - totalz) * 64.0 / z, 0.0, 1.0) * clamp(1.0 - ((z * 8.0 - totalz) * 32.0 - 1.0) / z, 0.0, 1.0);
	float outlineb = clamp(1.0 + 8.0 * (z - maxz) / z, 0.0, 1.0);
	float outlinec = clamp(1.0 + 64.0 * (z - maxz) / z, 0.0, 1.0);
	float outline = (0.35 * (outlinea * outlineb) + 0.65) * (0.75 * (1.0 - outlined) * outlinec + 1.0);

    outline -= 1.0;
    if (outline < 0.0) outline = -outline * 0.25;
    outline *= 2.0;
	color += min(color.rgb * outline * 2.5, vec3(outline));
}