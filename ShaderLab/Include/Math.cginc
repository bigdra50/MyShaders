inline float random(float2 seed){
    return frac(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453123);
}

inline float random(float3 seed){
    return frac(sin(dot(seed, float3(12.9898, 78.233, 56.7787))) * 43758.5453);
}

inline float2 random2D(float2 seed){
    seed = float2(dot(seed, float2(127.1, 311.7)), dot(seed, float2(269.5, 183.3)));
    return -1. + 2. * frac(sin(seed) * 43758.5453123);
}

inline float3 random3D(float3 seed){
    float x = random(seed);
    float y = random(float3(seed.y - 19.1, seed.z + 34.3, seed.x + 47.2));
    float z = random(float3(seed.z + 74.2, seed.x - 125.3, seed.y + 99.2));
    return float3(x, y, z);
}

inline float mod(float x, float y){
    return x - y * floor(x / y);
}

inline float2 mod(float2 x, float2 y){
    return x - y * floor(x / y);
}

inline float3 mod(float3 x, float3 y){
    return x - y * floor(x / y);
}

inline float4 mod(float4 x, float4 y){
    return x - y * floor(x / y);
}

inline float smoothMin(float d1, float d2, float k){
	float h = exp(-k * d1) + exp(-k * d2);
	return -log(h) / k;
}

inline float dot(float3 v){
    return dot(v, v);
}

// 和集合
inline float opUnion(float d1, float d2){
    return min(d1, d2);
}

inline float2 opUnion(float2 d1, float2 d2){
    return d1.x < d2.x ? d1 : d2;
}

// 差集合
inline float opSubstruct(float d1, float d2){
    return max(d1, -d2);
}
inline float2 opSubstruct(float2 d1, float2 d2){
    return d1.x < -d2.x ? d1 : d2;
}

// 積集合
inline float opIntersect(float d1, float d2){
    return max(d1, d2);
}

inline float2 opIntersect(float2 d1, float2 d2){
    return d1.x > d2.x ? d1 : d2;
}

// 繰り返し
inline float3 opRepeat(float3 pos, float3 interval){
    return mod(pos, interval * 2.) - interval;
}

inline float3 opRepeat(float3 pos, float interval){
    return opRepeat(pos, float3(interval, interval, interval));
}


inline float3 rotate(float3 pos, float angle, float3 axis){
    if(abs(axis.x) <= .00001 && abs(axis.y) <= .00001 && abs(axis.z) <= .00001) return pos;
    float3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1. - c;
    float3x3 mat = float3x3(
        a.x * a.x * r + c, a.y * a.x * r + a.z * s, a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s, a.y * a.y * r + c, a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s, a.y * a.z * r - a.x * s, a.z * a.z * r + c);

    return mul(mat, pos);
}
