// Distance Func
// Primitives(https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm)
inline float sdSphere(float3 pos, float radius){
    return length(pos) - radius;
}

inline float sdBox(float3 pos, float3 size){
    float3 d = abs(pos) - size;
    return length(max(d, .0)) 
        + min(max(d.x, max(d.y, d.z)), .0);
}

inline float sdRoundBox(float3 pos, float3 size, float roundness){
    float3 d = abs(pos) - size;
    return length(max(d, .0)) - roundness
        + min(max(d.x, max(d.y, d.z)), .0);
}

inline float sdTorus(float3 pos, float radius, float thickness){
    float2 q = float2(length(pos.xz) - radius, pos.y);
    return length(q) - thickness;
}

//inline float sdCappedTorus(float3 pos){
//    float2 sc = float2(_CappedTorusX, _CappedTorusY);
//    pos.x = abs(pos.x);
//    float k = (sc.y * pos.x > sc.x * pos.y) ? dot(pos.xy, sc) : length(pos.xy);
//    return sqrt(dot(pos, pos) + _CappedTorusRadius * _CappedTorusRadius - 2. * _CappedTorusRadius * k) - _CappedTorusThickness;
//}

//inline float sdLink(float3 pos){
//    float3 q = float3(pos.x, max(abs(pos.y) - _LinkLE, .0), pos.z);
//    return length(float2(length(q.xy) - _LinkRadius, q.z)) - _LinkThickness;
//}
//
//inline float sdCylinder(float3 pos){
//    float3 size = float3(_CylinderPosX, _CylinderPosZ, _CylinderRadius);
//    return length(pos.xz - size.xy) - size.z;
//}
//
//inline float sdCappedCylinder(float3 pos){
//    float2 d = abs(float2(length(pos.xz), pos.y)) - float2(_CappedCylinderHeight, _CappedTorusRadius);
//    return min(max(d.x, d.y), .0) + length(max(d, .0));
//}
//
//inline float sdRoundedCylinder(float3 pos){
//    float2 d = float2(length(pos.xz) - 2. * _RoundedCylinderRadius + _RoundedCylinderRoundness, abs(pos.y) - _RoundedCylinderHeight);
//    return min(max(d.x, d.y), .0) + length(max(d, .0)) - _RoundedCylinderRoundness;
//}
//
//inline float sdCone(float3 pos){
//    float2 c = normalize(float2(_ConeX, _ConeRadius));
//    float q = length(pos.xy);
//    return dot(c, float2(q, pos.z));
//}
//
//inline float sdCappedCone(float3 pos){
//    float2 q = float2(length(pos.xz), pos.y);
//
//    float2 k1 = float2(_CappedConeThickness, _CappedConeHeight);
//    float2 k2 = float2(_CappedConeThickness - _CappedConeRadius, 2. * _CappedConeHeight);
//    float2 ca = float2(q.x - min(q.x, (q.y < .0) ? _CappedConeRadius : _CappedConeThickness), abs(q.y) - _CappedConeHeight);
//    float2 cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot(k2, k2), .0, 1.);
//    float s = (cb.x < .0 && ca.y < .0) ? -1. : 1.;
//    return s * sqrt(min(dot(ca, ca), dot(cb, cb)));
//}
//
//inline float sdRoundCone(float3 pos){
//    float2 q = float2(length(pos.xz), pos.y);
//
//    float b = (_RoundConeRadius - _RoundConeThickness) / _RoundConeHeight;
//    float a = sqrt(1. - b * b);
//    float k = dot(q, float2(-b, a));
//
//    if(k < .0) return length(q) - _RoundConeRadius;
//    if(k > a * _RoundConeHeight) return length(q - float2(.0, _RoundConeHeight)) - _RoundConeThickness;
//
//    return dot(q, float2(a, b)) - _RoundConeRadius;
//}
//
inline float sdPlane(float3 pos, float3 dir)
{
    return dot(pos, dir);
}
//
//// 動かない
//inline float sdQuad(float3 pos){
//    float3 a = _QuadA.xyz;
//    float3 b = _QuadB.xyz;
//    float3 c = _QuadC.xyz;
//    float3 d = _QuadD.xyz;
//
//    float3 ba = b - a; float3 pa = pos - a;
//    float3 cb = c - b; float3 pb = pos - b;
//    float3 dc = d - c; float3 pc = pos - c;
//    float3 ad = a - d; float3 pd = pos - d;
//    float3 nor = cross( ba, ad );
//
//return sqrt(
//    (sign(dot(cross(ba, nor), pa)) +
//     sign(dot(cross(cb, nor), pb)) +
//     sign(dot(cross(dc, nor), pc)) +
//     sign(dot(cross(ad, nor), pd)) < 3.)
//     ?
//     min( min( min(
//     dot(ba * clamp(dot(ba, pa) / dot(ba, ba), .0, 1.) - pa),
//     dot(cb * clamp(dot(cb, pb) / dot(cb, cb), .0, 1.) - pb)),
//     dot(dc * clamp(dot(dc, pc) / dot(dc, dc), .0, 1.) - pc)),
//     dot(ad * clamp(dot(ad, pd) / dot(ad, ad), .0, 1.) - pd))
//     :
//     dot(nor, pa) * dot(nor, pa) / dot(nor, nor));
//}
//
//inline float dHexPrism(float3 pos){
//    float2 h = float2(_HexagonX, _HexagonY);
//    pos = abs(pos);
//    return max(pos.z - h.y, max((pos.x * .866025 + pos.y * .5), pos.y) - h.x);
//}

inline float sdHexPrism(float3 pos, float2 h){
    pos = abs(pos);
    return max(pos.z - h.y, max((pos.x * .866025 + pos.y * .5), pos.y) - h.x);
}

//inline float sdTriangle(float3 pos){
//    float2 h = float2(_TriangleX, _TriangleY);
//    float3 q = abs(pos);
//    return max(q.z - h.y, max(q.x * .866025 + pos.y * .5, -pos.y) -h.x * .5);
//}
//
//inline float sdOcta(float3 pos){
//    float s = _OctahedronSize;
//    pos = abs(pos);
//    float m = pos.x + pos.y + pos.z - s;
//    float3 q;
//    if(3. * pos.x < m ) q = pos.xyz;
//    else if( 3. * pos.y < m ) q = pos.yzx;
//    else if( 3. * pos.z < m ) q = pos.zxy;
//    else return m * .57735027;
//
//    float k = clamp(.5 *(q.z - q.y + s), 0., s); 
//    return length(float3(q.x, q.y - s + k, q.z - k)); 
//}
//
//inline float sdCapsule(float3 pos){
//    float3 a = _CapsuleVec3A.xyz;
//    float3 b = _CapsuleVec3B.xyz;
//    float3 pa = pos - a;
//    float3 ba = b - a;
//
//    float h = clamp(dot(pa, ba) / dot(ba, ba), .0, 1.);
//    return length(pa - ba * h) - _CapsuleRadius;
//}