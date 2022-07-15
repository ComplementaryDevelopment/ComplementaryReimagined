#ifdef NETHER
    color.rgb /= max(GetLuminance(texture2DLod(texture, texCoord, 100.0).rgb) * 2.5, 0.001);

    vec3 worldPos = playerPos + cameraPosition;
    vec2 lavaPos = (floor(worldPos.xz * 16.0) + worldPos.y * 32.0) * 0.000666;
    vec2 wind = vec2(frameTimeCounter * 0.012, 0.0);

    float sample = texture2D(noisetex, lavaPos + wind).g;
    sample = sample - 0.5;
    sample *= 0.1;
    color.rgb = pow(color.rgb, vec3(1.0 + sample));
#endif
noDirectionalShading = true;
lmCoordM = vec2(0.0);
emission = color.g * 6.0;
color.rgb *= vec3(1.25, vec2(0.9));