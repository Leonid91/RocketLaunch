// Constants
#define PI 3.1415
#define MOD2 vec2(3.07965, 7.4235)

const int KEY_SPACEBAR = 32;

// Time Scaling
#define time iTime*0.1

// Raymarching
float minPrimStepSize = 0.1 ;
const int primNumSamples = 100 ;

// Colours
const vec3 smokeCol = vec3(30./255., 31./255., 30./255.) ;
const vec3 sunCol = vec3(1.000,0.000,0.000) ;
const vec3 backCol = vec3(0.2, 0.2, 0.6) ;
const vec3 skyCol = vec3(0.306,0.545,0.694)/255. ;
const vec3 rocketCol = vec3(0.569,0.451,0.451) ;
const vec3 ambientCol = vec3(0.9) ;

// SmokeVals
const int octavesSmoke =  12 ;

vec2 rot2D(vec2 p, float angle) {
    angle = radians(angle);
    float s = sin(angle);
    float c = cos(angle);
    
    return p * mat2(c,s,-s,c);  
}

float hash(vec3 p)  // replace this by something better
{
    p  = fract( p*0.3183099+.1 );
	p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise( in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
	
    return mix(mix(mix( hash(p+vec3(0,0,0)), 
                        hash(p+vec3(1,0,0)),f.x),
                   mix( hash(p+vec3(0,1,0)), 
                        hash(p+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(p+vec3(0,0,1)), 
                        hash(p+vec3(1,0,1)),f.x),
                   mix( hash(p+vec3(0,1,1)), 
                        hash(p+vec3(1,1,1)),f.x),f.y),f.z);
}

vec3 smokeStart = vec3(5.0,-5.0,5.0) ;
vec3 smokeEnd = vec3(5.0,5.0,5.0) ;
float smokeThickness = 1.0 ;
float offset = 0.1 ;

float sampleSmoke(vec3 position) {
  float noiseVal = 0.0 ;
  float amplitude = 1.0 ;
  float freq = 4.5 ;
  float lac = 2.0 ;
  float scaling = 2.0 ;
  for (int i = 0 ; i < octavesSmoke ; ++i) {
    noiseVal += amplitude * noise(freq*position+vec3(0.0,time*200.0,3.0*time)) ;
    amplitude /= lac ;
    freq *= lac ;
  }
    
  vec3 smokeDir = normalize(smokeEnd-smokeStart) ;
  float dist = length((smokeStart - position) - (dot((smokeStart - position),smokeDir))*smokeDir) ;
  noiseVal *= exp(-2.5*dist) ;
  noiseVal -= offset ;
  noiseVal *= (1.0 - exp(-0.05 * length(smokeStart-position))) ;
  noiseVal = clamp(noiseVal,0.0,1.0) ;

  return scaling * noiseVal ;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

void rotate(const float a, inout vec2 v) {
    float cs = cos(a), ss = sin(a);
    vec2 u = v;
    v.x = u.x*cs + u.y*ss;
    v.y = u.x*-ss+ u.y*cs;
}

float pi = 3.1415 ;

float mBox(vec3 p, vec3 b) {
	return max(max(abs(p.x)-b.x,abs(p.y)-b.y),abs(p.z)-b.z);
}

vec2 frot(const float a, in vec2 v) {
    float cs = cos(a), ss = sin(a);
    vec2 u = v;
    v.x = u.x*cs + u.y*ss;
    v.y = u.x*-ss+ u.y*cs;
    return v;
}

void angularRepeat(const float a, inout vec2 v)
{
    float an = atan(v.y,v.x);
    float len = length(v);
    an = mod(an+a*.5,a)-a*.5;
    v = vec2(cos(an),sin(an))*len;
}


float dfRocketBody(vec3 p) {
    vec3 p2 = p;
    vec3 pWindow = p;

    angularRepeat(pi*.25,p2.zx);
    float d = p2.z;
    d = max(d, frot(pi*-.125, p2.yz+vec2(-.7,0)).y);
    d = max(d, frot(pi*-.25*.75, p2.yz+vec2(-0.95,0)).y);
    d = max(d, frot(pi*-.125*.5, p2.yz+vec2(-0.4,0)).y);
    d = max(d, frot(pi*.125*.25, p2.yz+vec2(+0.2,0)).y);
    d = max(d, frot(pi*.125*.8, p2.yz+vec2(.55,0)).y);
    d = max(d,-.8-p.x);
    d -= .5;
    
    vec3 pThruster = p2;
    pThruster -= vec3(-1.46,.0,.0);
    rotate(pi*-.2,pThruster.yz);
    d = min(d,mBox(pThruster,vec3(.1,.4,.27)));
    d = min(d,mBox(pThruster-vec3(-.09,.0,.0),vec3(.1,.3,.07)));
    
    
    pWindow -= vec3(.1,.0,.0);
    angularRepeat(pi*.25,pWindow.xy);
    pWindow -= vec3(.17,.0,.0);
    d = min(d,mBox(pWindow,vec3(.03,.2,.55)));
    
  	return d;
}

float dfRocketFins(vec3 p) {       
    
    vec3 pFins = p;
    angularRepeat(pi*.5,pFins.zx);
    pFins -= vec3(0.0,-1.0+cos(p.y+.2)*.5,.0);
    rotate(pi*.25,pFins.yz);
    float scale = 1.0-pFins.y*.5;
    float d =mBox(pFins,vec3(.17,.03,3.0)*scale)*.5;
    return d;
}

float dfRocket(vec3 p) {
    float proxy = mBox(p,vec3(2.5,.8,.8));
    if (proxy>1.0)
    	return proxy;
    return min(dfRocketBody(p),dfRocketFins(p));
}


float sampleSmokeCap(vec3 position) {
	return sdCapsule(position,smokeStart,smokeEnd,smokeThickness) ;  
}

float sampleRocketCCy(vec3 position) {
    return dfRocket(position-(smokeEnd+vec3(0.0,2.3,0.0))) ;
}

bool isIntersectingSmokeShape(vec3 position, float precis, out float dist) {
    dist = sampleSmokeCap(position) ;
    return dist < precis ;
}

bool isIntersectingRocket(vec3 position, float precis, out float dist) {
    dist = sampleRocketCCy(position) ;
    return dist < precis ;
}
                          
bool rayMarchTrans(vec3 startPos, vec3 direction, out float rayDist) {
    vec3 position = startPos ;
    bool intersected = false ;
    rayDist = 0.0 ;
    float delta = minPrimStepSize ;
    float precis = 0.0005 ;
    
    for (int i = 0 ; i < primNumSamples ; ++i) {
		if (isIntersectingSmokeShape(position,precis,delta)) {
            return true ;
        } else {
            precis = 0.00005 * rayDist ;
		    rayDist += delta ;
            position = (rayDist)*direction + startPos ;
        }
    }
    
    return false ;
}

bool rayMarchSolids(vec3 startPos, vec3 direction, out float rayDist) {
    vec3 position = startPos ;
    bool intersected = false ;
    rayDist = 0.0 ;
    float delta = minPrimStepSize ;
    float precis = 0.0005 ;
    
    for (int i = 0 ; i < primNumSamples ; ++i) {
		if (isIntersectingRocket(position,precis,delta)) {
            return true ;
        } else {
            precis = 0.0005 * rayDist ;
		    rayDist += delta ;
            position = (rayDist)*direction + startPos ;
        }
    }
    
    return false ;
}


const float extinctionCoeff = 13.0 ;
const float scatteringCoeff = 12.5 ;
const float secSmokeSampleSize = 0.2 ;
const int secSmokeNumSamples = 5 ;

float getIncidentSunlight(vec3 startPos, vec3 lightDir) {
    vec3 position = startPos ;
    vec3 stepVector = lightDir * secSmokeSampleSize ;
    float extinction = 1.0 ;
    float dist = 0.0 ;
    for (int i = 0 ; i < secSmokeNumSamples ; ++i) {
        if (!isIntersectingSmokeShape(position,0.005,dist))
            break ;
	    float density = sampleSmoke(position) ;
        extinction *= exp(-extinctionCoeff*density*secSmokeSampleSize) ;
        position += stepVector ;
    }
    return extinction ;
}

const float primSmokeSampleSize = 0.1 ;
const int primSmokeNumSamples = 50 ;

vec4 primaryRayMarchSmoke(vec3 startPos, vec3 direction, vec3 lightDir) {
    vec3 position = startPos ;
    vec3 stepVector = direction * primSmokeSampleSize ;
    float dist ;
    float extinction = 1.0 ;
    vec3 colour = vec3(0.0) ;
    for (int i = 0 ; i < primSmokeNumSamples ; ++i) {
        if (extinction < 0.05 || !isIntersectingSmokeShape(position,0.005,dist))
            break ;
     	float vertDistFromRocket = abs(position.y - smokeEnd.y) ;
        float deltaYDensityMod = (1.f-(vertDistFromRocket)/(smokeEnd.y-smokeStart.y));
		float density = sampleSmoke(position) * deltaYDensityMod * deltaYDensityMod;
        extinction *= exp(-extinctionCoeff*density*primSmokeSampleSize);
        vec3 scattering = primSmokeSampleSize * density * scatteringCoeff * (ambientCol +  sunCol * getIncidentSunlight(position, lightDir)) ;
        colour += scattering * extinction ;
        position += stepVector ;
    }
    
    return vec4(colour,extinction) ;    
}

vec3 calcSkyCol(in vec3 direction, in vec3 lightDir) {	
    float sunAmount = max( dot(direction, lightDir), 0.0 );
	float v = pow(1.0-max(direction.y,0.0),5.)*.5;
	vec3  sky = vec3(v*sunCol.x*0.4+skyCol.x, v*sunCol.y*0.4+skyCol.y, v*sunCol.z*0.4+skyCol.z);
	sky = sky + sunCol * pow(sunAmount, 6.5)*.12;
	sky = sky+ sunCol * min(pow(sunAmount, 1200.), .3)*.65;
	return sky;
}

// Taken from IQ : https://www.shadertoy.com/view/Xds3zN
vec3 calcRocketNormal( in vec3 pos ) {
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*sampleRocketCCy( pos + e.xyy ) + 
					  e.yyx*sampleRocketCCy( pos + e.yyx ) + 
					  e.yxy*sampleRocketCCy( pos + e.yxy ) + 
					  e.xxx*sampleRocketCCy( pos + e.xxx ));
}

vec4 calcRocketColour(in vec3 position,in vec3 direction, in vec3 lightDir) {	
	vec3 nor = calcRocketNormal(position) ;
    vec3 ref = reflect( direction, nor);
    vec3 col = vec3(0.0) ;
    // lighting        
	vec3  lig = lightDir ;
    float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
    float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
    float spe = pow(clamp( dot( ref, lig ), 0.0, 1.0 ),16.0);
        
    if (dfRocketBody(position)>dfRocketFins(position)) {
    	if (position.y<smokeEnd.y-0.85 || position.y>smokeEnd.y+1.34)
        	if (position.y>smokeEnd.y+3.41)
            	col = vec3(.1,.1,.1);
            else
                col = vec3(0.522,0.400,0.400);
        else {
        	col = vec3(.1,.1,.1);
        }
    }
    
	vec3 lin = vec3(0.0);
    lin += 4.30*dif*vec3(1.00,0.80,0.55);
	lin += 7.00*spe*vec3(1.00,0.90,0.70)*dif;
    lin += 2.00*amb ;
	col = col*lin;
    
    return vec4(col,0.0) ;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord.xy - iResolution.xy * .5) / iResolution.y;
    vec2  m = 2.*((iMouse.xy / iResolution.xy) - 0.5);
    
    texture(iChannel3, uv); 
    
    if (iMouse.xy == vec2(0)) {
       m.y = 0.0 ;   
    }
    
    vec3 dir = vec3(uv, 1.);
    dir.yz = rot2D(dir.yz,  90. * m.y);
    dir.xz = rot2D(dir.xz, 45.);
    dir = normalize(dir) ;
    
    vec3 cameraPos = vec3(0.0,7.0-iTime,3.0*offset) ;
    

   float lightElev = 10. * 3.14/180. ;
   float lightAzi = 90. * 3.14/180. + 20. ;
   vec3 lightDir = vec3(cos(lightAzi)*cos(lightElev),sin(lightElev),sin(lightAzi)*cos(lightElev));

    
    float rayDistTrans = 0.0 ;
    float rayDistSolid = 0.0 ;
    vec4 colour = vec4(vec3(0.0),1.0) ;
    bool isTransPresent = rayMarchTrans(cameraPos,dir,rayDistTrans) ;
    bool isSolidPresent = rayMarchSolids(cameraPos,dir,rayDistSolid) ;
    
    if (isTransPresent && isSolidPresent) {
        if (rayDistSolid < rayDistTrans) {
            colour = calcRocketColour(cameraPos+dir*rayDistSolid,dir,lightDir) ; 
        } else {
        	colour = primaryRayMarchSmoke(cameraPos+dir*rayDistTrans,dir,lightDir) ; 
            colour = vec4(mix(colour.rgb,calcRocketColour(cameraPos+dir*rayDistSolid,dir,lightDir).rgb,colour.a),1.0) ;
        }
    } else if (isTransPresent) {
        if(iTime > 0.3){
            colour = primaryRayMarchSmoke(cameraPos+dir*rayDistTrans,dir,lightDir) ;
        }
        
    } else if (isSolidPresent) {
        colour = calcRocketColour(cameraPos+dir*rayDistSolid,dir,lightDir) ;    
    }
    //vec3 skyCol = calcSkyCol(dir,lightDir) ;
    //colour.rgb = mix(colour.rgb,skyCol,colour.a) ;
    fragColor = vec4(colour.rgb,1.0) ;
}