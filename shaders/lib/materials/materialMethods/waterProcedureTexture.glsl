float random (in float x) { return fract(sin(x)*1e4);}
float random (in vec2 st) {return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* 43758.5453123);}
vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec3 voronoi( in vec2 x, float rnd ) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    // first pass: regular voronoi
    vec2 mg, mr;
    float md = 8.0;
    for (int j=-1; j<=1; j++ ) {
        for (int i=-1; i<=1; i++ ) {
            vec2 g = vec2(float(i),float(j));
            vec2 o = random2( n + g )*rnd;
            o = 0.5 + 0.5*sin( frameTimeCounter + 6.2831*o );
            vec2 r = g + o - f;
            float d = dot(r,r);

            if( d<md ) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }

    // second pass: distance to borders
    md = 8.0;
    for (int j=-2; j<=2; j++ ) {
        for (int i=-2; i<=2; i++ ) {
            vec2 g = mg + vec2(float(i),float(j));
            vec2 o = random2(n + g)*rnd;
            o = 0.5 + 0.5*sin( frameTimeCounter + 6.2831*o );
            vec2 r = g + o - f;

            if( dot(mr-r,mr-r)>0.00001 )
            md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
        }
    }
    return vec3( md, mr );
}

vec3 waterMaskFunc(vec2 uv, const float water_scroll_speed) {
    const float foam_speed = 0.05;
    const float water_warp = 0.005;
    const vec3 water_color = vec3(0.22, 0.22, 0.22);

    //pixelated coord to created pixelated visual
    uv = (uv-.5)*.25+.5;
    uv = floor(uv *128.0)/128.0;

    float d = dot(uv-0.5,uv-0.5);
    vec3 c = voronoi(5.0*uv, pow(d,.6) );

    vec2 water_pos = vec2(frameTimeCounter) * water_scroll_speed;
    vec3 foamNoise = texture2D(noisetex, uv + vec2(frameTimeCounter)*foam_speed).xyz;

    vec3 result = vec3(0.0);
    // borders
    vec3 waterMask = mix(vec3(1.00), vec3(0.0), smoothstep( 0.04, 0.06, c.x ));
    vec3 foam = waterMask * vec3(foamNoise.y - 0.55);
    foam = clamp(foam, vec3(0.02), vec3(1.0));

    //not regular structure water
    float water_sample = floor(texture2D(noisetex, uv * 0.25 + foamNoise.xz * water_warp + water_pos).r * 16) /16;
    vec3 water = mix(water_color, vec3(0.001), water_sample);

    // small particles in water
    // Grid
    vec2 st = uv;
    st *= vec2(100.0,100.);
    vec2 ipos = floor(st);  // integer
    vec2 vel = vec2(frameTimeCounter); // time
    vel *= vec2(-1.,0.); // direction
    vel *= (step(1.0, mod(ipos.y,5.024))-0.5)*2.; // Oposite directions
    vel *= vec2(-1.,0.); // direction
    vel *= random(ipos.y); // random speed

    //Creating particles
    vec3 pixelParticle = vec3(1.0);
    pixelParticle *= random(floor(vec2(st.x*0.32, st.y)+vel));
    float mixFactor = clamp((sin(frameTimeCounter*0.1) + 1.0)*0.5, 0.005, 0.15);
    pixelParticle = smoothstep(0.0,mixFactor,pixelParticle);
    pixelParticle = (1.0 - pixelParticle) *  (foamNoise.y - 0.55);
    pixelParticle = clamp(pixelParticle, vec3(0.02), vec3(1.0));

    result = foam * 2.0 + pixelParticle * 2.0 + water;

    return result;
}