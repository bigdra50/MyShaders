#define _Iteration 99

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

// math 
const float PI = 3.1415926;
const float EPS = .00001;
float sphereRadius = 1.;

float dSphere(vec3 pos){
	return length(pos) - sphereRadius;
}

float map(vec3 currentPos){
	return dSphere(currentPos);
}

struct Ray{
	vec3 pos;
	vec3 dir;
};

vec4 raymarch(vec2 pos){
	vec3 col = vec3(.0);

	// camera
	vec3 camPos = vec3(.0, .0, -4.);
	vec3 camDir = vec3(.0, .0, 1.);
	vec3 camUp = vec3(.0, 1., .0);
	vec3 camSide = cross(camDir, camUp);
	float targetDepth = 1.;

	Ray ray;
	ray.pos = camPos;
	ray.dir = normalize(camSide * pos.x + camUp * pos.y + camDir * targetDepth);

	// レイとオブジェクト間の最短距離
	float distance = .0;
	// レイに継ぎ足す長さ
	float rayLen = .0;
	bool isHit = false;
	float alpha = 1.;

	for(int j = 0; j < _Iteration; j++){
		distance = map(ray.pos);
		if(isHit = distance < EPS){
			break;
		}
		rayLen += distance;
		ray.pos = camPos + rayLen * ray.dir;
	}

	col = isHit ? vec3(1) : vec3(0);
	return vec4(col, alpha); 

}


void main(){
	// 正規化
	vec2 pos = (gl_FragCoord.xy * 2. - resolution) / max(resolution.x, resolution.y);

	gl_FragColor = raymarch(pos);
}

