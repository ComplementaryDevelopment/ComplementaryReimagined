// Jitter offset from Chocapic13
uniform float framemod8;
uniform float velocity;

vec2 jitterOffsets[8] = vec2[8](
						vec2( 0.125,-0.375),
						vec2(-0.125, 0.375),
						vec2( 0.625, 0.125),
						vec2( 0.375,-0.625),
						vec2(-0.625, 0.625),
						vec2(-0.875,-0.125),
						vec2( 0.375,-0.875),
						vec2( 0.875, 0.875)
						);
							   
vec2 TAAJitter(vec2 coord, float w) {
	vec2 offset = jitterOffsets[int(framemod8)] * (w / vec2(viewWidth, viewHeight));
	offset *= max0(1.0 - velocity * 400.0) * 0.125;
	return coord + offset;
}