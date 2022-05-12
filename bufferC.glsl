//Change if you have performance issues (Or a better GPU than me)
#define rend 1000.

//IQ's Noise
float pn( in vec3 p ) {
    vec3 ip = floor(p);
    p = fract(p);
    p *= p*(3.0-2.0*p);
    vec2 uv = (ip.xy+vec2(37.0,17.0)*ip.z) + p.xy;
    uv = textureLod( iChannel2, (uv+ 0.5)/256.0, 0.0 ).yx;
    return mix( uv.x, uv.y, p.z );
}

//Dave Hoskins' random function
vec2 rand(vec2 p) {
    vec3 p3;
    for(int i = 0; i < 4; i++) {
		p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    	p3 += dot(p3, p3.yzx+19.19);
    }
    vec2 ret = fract((p3.xx+p3.yz)*p3.zy);
    return ret*0.8+0.1;
}

float dotNoise(vec2 uv) {
	float col = 0.;
	vec2 loop;
	vec2 pos = rand(floor(uv+loop));
	float dist = length(fract(uv)-pos-loop)/3.;
	col = max(1.-dist*10., col);
	return col;
}

int tex = -2;
float stepping = 1.0;
vec3 col = vec3(0.0);
void setStep(float num) {
    if(num < stepping) {
    	stepping = num;
    }
    if(stepping < 0.1) {
    	stepping = 0.1;
    }
}

bool check(vec3 coord) {
    stepping = 999999999999999999999999.;
    coord.y += pn(vec3(coord.x/250., coord.z/250., 0.))*100.;
   	setStep(coord.y+39.);
    if(coord.y < -50.) {
    	tex = 0;
        return true;
    }
    float grass;
    if(coord.y < -40.) {
    	grass = dotNoise(coord.xz / 4.) * 10.;
        setStep(1.-grass+coord.y);
    }
    if(coord.y < -50. + grass) {
    	tex = 1;
        return true;
    }
    return false;
}
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.x;
    uv.x -= 0.5;
    uv.y -= iResolution.y/iResolution.x/2.0;
    col = vec3(0.0,0.7,1.0);
    vec3 rp = vec3(0., 50.-pn(vec3(0., 0.1*0.4, 0.))*100., 0.1*100.);
    vec3 rv = vec3(uv,0.5);
    rv = normalize(rv);
    float dist = 0.0;
    while(dist < rend && !check(rp)) {
        dist += stepping;
        rp += rv*stepping;
        float c = length(rv);
        if(c < 1.0) {
        	c = 1.0;
        }
    }
    float castdist = dist;
    dist = 0.0;
    if(tex == 0) {
        col = texture(iChannel0, vec2(rp.x/200.0, rp.z/200.0)).xyz;
    }
    
    if(tex == 1) {
        col = vec3(0.1, 0.8, 0.1);
    }
     
    rv = vec3(0.3, 1., 0.5);
   	rv = normalize(rv)/2.0;
    rp += rv*3.0;
    while(dist < rend/3.0 && !check(rp)) {
        dist += stepping;
        rp += rv*stepping;
    }
    if(dist < rend/3.0) {
    	col /= 2.0;
    }
    castdist *= castdist;
   	col = vec3(mix(col.x,0.0,castdist/(rend*rend)),mix(col.y,0.7,castdist/(rend*rend)),mix(col.z,1.0,castdist/(rend*rend)));
	fragColor = vec4(col,1.0);
}
