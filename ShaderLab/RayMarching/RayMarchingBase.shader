Shader "Raymarching/RayMarchingBase"
{
    Properties
    {
        _Color ("Albedo", color) = (1, 1, 1, 1)

        [Header(Raymarching)]
        [IntRange] _Iteration("Marching Iteration", Range(0, 1080)) = 128
        [IntRange] _RepeatInterval("Repeat Interval", Range(1, 10)) = 1

        [Header(Rotation)]
        _AxisX("Axis X", Range(-1., 1.)) = .0
        _AxisY("Axis Y", Range(-1., 1.)) = .0
        _AxisZ("Axis Z", Range(-1., 1.)) = .0
        

        [Header(Sphere)]
        _Radius("Radius", Range(.0, 1.)) = .5
        _SphereX("Offset X", float) = .0
        _SphereY("Offset Y", float) = .0
        _SphereZ("Offset Z", float) = .0

        [Header(Box)]
        _BoxX("Size X", Range(.0, 1.)) = .1
        _BoxY("Size Y", Range(.0, 1.)) = .1
        _BoxZ("Size Z", Range(.0, 1.)) = .1

        [Header(Round Box)]
        _RoundBoxX("Size X", Range(.0, 1.)) = .1
        _RoundBoxY("Size Y", Range(.0, 1.)) = .1
        _RoundBoxZ("Size Z", Range(.0, 1.)) = .1
        _RoundBoxR("Roundness", Range(.0, 1.)) = .0 // 丸み具合
        
        [Header(Torus)]
        _TorusX("Radius", Range(.0, 1.)) = .3
        _TorusY("Thickness", Range(.0, 1.)) = .1

        [Header(Capped Torus)]
        _CappedTorusX("CappedTorus X", Range(.0, 1.)) = .5
        _CappedTorusY("CappedTorus Y", Range(.0, 1.)) = .1
        _CappedTorusRadius("Radius", Range(.0, 1.)) = .5
        _CappedTorusThickness("Thickness", Range(.0, 1.)) = .1

        [Header(Link)]
        _LinkLE("LinkLE", Range(.0, 1.)) = .2
        _LinkRadius("Radius", Range(.0, 1.)) = .25
        _LinkThickness("Thickness", Range(.0, 1.)) = .1

        [Header(Infinity Cylinder)]
        _CylinderPosX("Pos X", Range(-1., 1.)) = .0
        _CylinderPosZ("Pos Z", Range(-1., 1.)) = .0
        _CylinderRadius("Radius", Range(.0, 1.)) = .1

        [Header(Capped Cylinder)]
        _CappedCylinderHeight("Height", Range(.0, 1.)) = .1
        _CappedCylinderRadius("Radius", Range(.0, 1.)) = .1

        [Header(Rounded Cylinder)]
        _RoundedCylinderRadius("Radius", Range(.0, 1.)) = .1
        _RoundedCylinderRoundness("Roundness", Range(.0, 1.)) = .0
        _RoundedCylinderHeight("Height", Range(.0, 1.)) = .1

        [Header(Cone)]
        _ConeX("ConeX", Range(.0, 1.)) = .1
        _ConeRadius("Radius", Range(.0, 1.)) = .1

        [Header(Capped Cone)]
        _CappedConeHeight("Height", Range(.0, 1.)) = .3
        _CappedConeRadius("Radius", Range(.0, 1.)) = .3
        _CappedConeThickness("Thickness", Range(.0, 1.)) = .0

        [Header(Round Cone)]
        _RoundConeRadius("Radius", Range(.0, 1.)) = .1
        _RoundConeThickness("Thickness", Range(.0, 1.)) = .1
        _RoundConeHeight("Height", Range(.0, 1.)) = .1

        [Header(Plane)]
        _PlaneVector("Vector4", Vector) = (.1, .1, .1, .1)

        [Header(Quad)]
        _QuadA("A", Vector) = (.1, .1, .1, .0)
        _QuadB("B", Vector) = (.1, .1, .1, .0)
        _QuadC("C", Vector) = (.1, .1, .1, .0)
        _QuadD("D", Vector) = (.1, .1, .1, .0)

        [Header(Hexagonal Prism)]
        _HexagonX("X", Range(.0, 1.)) = .1
        _HexagonY("Y", Range(.0, 1.)) = .1


        [Header(Triangular Prism)]
        _TriangleX("X", Range(.0, 1.)) = .1
        _TriangleY("Y", Range(.0, 1.)) = .1

        [Header(Octahedron_not exact)]
        _OctahedronSize("Size", Range(.0, 1.)) = .1

        [Header(Capsule)]
        _CapsuleVec3A("A(Vec3)", Vector) = (.1, .1, .1, 0)
        _CapsuleVec3B("B(Vec3)", Vector) = (.1, .1, .1, 0)
        _CapsuleRadius("Radius", Range(.0, 1.)) = .1

//        [Header(Vertical Capsule)]
//
//        [Header(Ellipsoid)]
//
//        [Header(Octahedron)]
//
//        [Header(Triangle)]
//

    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                // float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 oPos : TEXCOORD1;
            };

            static float EPS = .0001;

            fixed4 _LightColor0;

            fixed4 _Color;

            uint _Iteration;
            uint _RepeatInterval;

            // Rotation
            float _AxisX;
            float _AxisY;
            float _AxisZ;

            // Sphere
            float _SphereX;
            float _SphereY;
            float _SphereZ;
            float _Radius;

            // Box
            float _BoxX;
            float _BoxY;
            float _BoxZ;

            // Round Box
            float _RoundBoxX;
            float _RoundBoxY;
            float _RoundBoxZ;
            float _RoundBoxR;

            // Torus
            float _TorusX;
            float _TorusY;

            // Capped Torus
            float _CappedTorusX;
            float _CappedTorusY;
            float _CappedTorusRadius;
            float _CappedTorusThickness;

            // Link
            float _LinkLE;
            float _LinkRadius;
            float _LinkThickness;

            // Cylinder
            float _CylinderPosX;
            float _CylinderPosZ;
            float _CylinderRadius;

            // Capped Cylinder
            float _CappedCylinderHeight;
            float _CappedCylinderRadius;

            // Rounded Cylinder
            float _RoundedCylinderRadius;
            float _RoundedCylinderRoundness;
            float _RoundedCylinderHeight;

            // Cone
            float _ConeX;
            float _ConeRadius;

            // Capped Cone
            float _CappedConeHeight;
            float _CappedConeRadius;
            float _CappedConeThickness;

            // Round Cone
            float _RoundConeHeight;
            float _RoundConeRadius;
            float _RoundConeThickness;

            // Plane
            float4 _PlaneVector;

            // Quad
            float4 _QuadA;
            float4 _QuadB;
            float4 _QuadC;
            float4 _QuadD;

            // Hexagonal Prism
            float _HexagonX;
            float _HexagonY;

            // Trianglar Prism
            float _TriangleX;
            float _TriangleY;

            // Octahedron
            float _OctahedronSize;

            // Capsule
            float4 _CapsuleVec3A;
            float4 _CapsuleVec3B;
            float _CapsuleRadius;

            // Math Func

            float random(float2 p){
                return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
            }

            float mod(float x, float y){
                return x - y * floor(x / y);
            }

            float2 mod(float2 x, float2 y){
                return x - y * floor(x / y);
            }

            float3 mod(float3 x, float3 y){
                return x - y * floor(x / y);
            }

            float4 mod(float4 x, float4 y){
                return x - y * floor(x / y);
            }

            float dot(float3 v){
                return dot(v, v);
            }

            // 和集合
            float opUnion(float d1, float d2){
                return min(d1, d2);
            }

            float2 opUnion(float2 d1, float2 d2){
                return d1.x < d2.x ? d1 : d2;
            }

            // 差集合
            float opSubstruct(float d1, float d2){
                return max(d1, -d2);
            }
            float2 opSubstruct(float2 d1, float2 d2){
                return d1.x < -d2.x ? d1 : d2;
            }

            // 積集合
            float opIntersect(float d1, float d2){
                return max(d1, d2);
            }

            float2 opIntersect(float2 d1, float2 d2){
                return d1.x > d2.x ? d1 : d2;
            }

            // 繰り返し
            float3 opRepeat(float3 pos, float3 interval){
                return mod(pos, interval * 2.) - interval;
            }

            float3 opRepeat(float3 pos, float interval){
                return opRepeat(pos, float3(interval, interval, interval));
            }


            float3 rotate(float3 pos, float angle){
                float3 axis = float3(_AxisX, _AxisY, _AxisZ);
                float3 a = normalize(axis);
                float s = sin(angle);
                float c = cos(angle);
                float r = 1. - c;
                float3x3 mat = float3x3(
                    a.x * a.x * r + c, a.y * a.x * r + a.z * s, a.z * a.x * r - a.y * s,
					a.x * a.y * r - a.z * s, a.y * a.y * r + c, a.z * a.y * r + a.x * s,
					a.x * a.z * r + a.y * s, a.y * a.z * r - a.x * s, a.z * a.z * r + c
				);
				return mul(mat, pos);
            }


            // Distance Func
            // Primitives(https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm)
            float dSphere(float3 pos){
                float offset = float3(_SphereX, _SphereY, _SphereZ);
                return length(pos + offset) - _Radius;
            }

            float dBox(float3 pos){
                float3 size = float3(_BoxX, _BoxY, _BoxZ);
                float3 d = abs(pos) - size;
                return length(max(d, .0)) 
                    + min(max(d.x, max(d.y, d.z)), .0);
            }

            float dRoundBox(float3 pos){
                float3 size = float3(_RoundBoxX, _RoundBoxY, _RoundBoxZ);
                float3 d = abs(pos) - size;
                return length(max(d, .0)) - _RoundBoxR
                    + min(max(d.x, max(d.y, d.z)), .0);
            }

            float dTorus(float3 pos){
                float2 t = float2(_TorusX, _TorusY);
                float2 q = float2(length(pos.xz) - t.x, pos.y);
                return length(q) - t.y;
            }

            float dCappedTorus(float3 pos){
                float2 sc = float2(_CappedTorusX, _CappedTorusY);
                pos.x = abs(pos.x);
                float k = (sc.y * pos.x > sc.x * pos.y) ? dot(pos.xy, sc) : length(pos.xy);
                return sqrt(dot(pos, pos) + _CappedTorusRadius * _CappedTorusRadius - 2. * _CappedTorusRadius * k) - _CappedTorusThickness;
            }

            float dLink(float3 pos){
                float3 q = float3(pos.x, max(abs(pos.y) - _LinkLE, .0), pos.z);
                return length(float2(length(q.xy) - _LinkRadius, q.z)) - _LinkThickness;
            }

            float dCylinder(float3 pos){
                float3 size = float3(_CylinderPosX, _CylinderPosZ, _CylinderRadius);
                return length(pos.xz - size.xy) - size.z;
            }

            float dCappedCylinder(float3 pos){
                float2 d = abs(float2(length(pos.xz), pos.y)) - float2(_CappedCylinderHeight, _CappedTorusRadius);
                return min(max(d.x, d.y), .0) + length(max(d, .0));
            }

            float dRoundedCylinder(float3 pos){
                float2 d = float2(length(pos.xz) - 2. * _RoundedCylinderRadius + _RoundedCylinderRoundness, abs(pos.y) - _RoundedCylinderHeight);
                return min(max(d.x, d.y), .0) + length(max(d, .0)) - _RoundedCylinderRoundness;
            }

            float dCone(float3 pos){
                float2 c = normalize(float2(_ConeX, _ConeRadius));
                float q = length(pos.xy);
                return dot(c, float2(q, pos.z));
            }

            float dCappedCone(float3 pos){
                float2 q = float2(length(pos.xz), pos.y);

                float2 k1 = float2(_CappedConeThickness, _CappedConeHeight);
                float2 k2 = float2(_CappedConeThickness - _CappedConeRadius, 2. * _CappedConeHeight);
                float2 ca = float2(q.x - min(q.x, (q.y < .0) ? _CappedConeRadius : _CappedConeThickness), abs(q.y) - _CappedConeHeight);
                float2 cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot(k2, k2), .0, 1.);
                float s = (cb.x < .0 && ca.y < .0) ? -1. : 1.;
                return s * sqrt(min(dot(ca, ca), dot(cb, cb)));
            }

            float dRoundCone(float3 pos){
                float2 q = float2(length(pos.xz), pos.y);

                float b = (_RoundConeRadius - _RoundConeThickness) / _RoundConeHeight;
                float a = sqrt(1. - b * b);
                float k = dot(q, float2(-b, a));

                if(k < .0) return length(q) - _RoundConeRadius;
                if(k > a * _RoundConeHeight) return length(q - float2(.0, _RoundConeHeight)) - _RoundConeThickness;

                return dot(q, float2(a, b)) - _RoundConeRadius;
            }

            // 動かない
            float dPlane(float3 pos){
                float4 n = normalize(_PlaneVector);
                return dot(pos, n.xyz) + n.w;
            }

            // 動かない
            float dQuad(float3 pos){
                float3 a = _QuadA.xyz;
                float3 b = _QuadB.xyz;
                float3 c = _QuadC.xyz;
                float3 d = _QuadD.xyz;

                float3 ba = b - a; float3 pa = pos - a;
                float3 cb = c - b; float3 pb = pos - b;
                float3 dc = d - c; float3 pc = pos - c;
                float3 ad = a - d; float3 pd = pos - d;
                float3 nor = cross( ba, ad );

            return sqrt(
                (sign(dot(cross(ba, nor), pa)) +
                 sign(dot(cross(cb, nor), pb)) +
                 sign(dot(cross(dc, nor), pc)) +
                 sign(dot(cross(ad, nor), pd)) < 3.)
                 ?
                 min( min( min(
                 dot(ba * clamp(dot(ba, pa) / dot(ba, ba), .0, 1.) - pa),
                 dot(cb * clamp(dot(cb, pb) / dot(cb, cb), .0, 1.) - pb)),
                 dot(dc * clamp(dot(dc, pc) / dot(dc, dc), .0, 1.) - pc)),
                 dot(ad * clamp(dot(ad, pd) / dot(ad, ad), .0, 1.) - pd))
                 :
                 dot(nor, pa) * dot(nor, pa) / dot(nor, nor));
            }

            float dHexPrism(float3 pos){
                float2 h = float2(_HexagonX, _HexagonY);
                pos = abs(pos);
                return max(pos.z - h.y, max((pos.x * .866025 + pos.y * .5), pos.y) - h.x);
            }

            float dTriangle(float3 pos){
                float2 h = float2(_TriangleX, _TriangleY);
                float3 q = abs(pos);
                return max(q.z - h.y, max(q.x * .866025 + pos.y * .5, -pos.y) -h.x * .5);
            }

            float dOcta(float3 pos){
                float s = _OctahedronSize;
                pos = abs(pos);
                float m = pos.x + pos.y + pos.z - s;
                float3 q;
                if(3. * pos.x < m ) q = pos.xyz;
                else if( 3. * pos.y < m ) q = pos.yzx;
                else if( 3. * pos.z < m ) q = pos.zxy;
                else return m * .57735027;

                float k = clamp(.5 *(q.z - q.y + s), 0., s); 
                return length(float3(q.x, q.y - s + k, q.z - k)); 
            }

            float dCapsule(float3 pos){
                float3 a = _CapsuleVec3A.xyz;
                float3 b = _CapsuleVec3B.xyz;
                float3 pa = pos - a;
                float3 ba = b - a;

                float h = clamp(dot(pa, ba) / dot(ba, ba), .0, 1.);
                return length(pa - ba * h) - _CapsuleRadius;
            }
            // ------------------------------------

            float map(float3 pos){
                return dHexPrism(rotate(pos, radians(_Time.w * 50.)));
            }

            float3 getNormal(float3 pos){
                return normalize(float3(
                    map(pos + float3(EPS, .0, .0)) - map(pos + float3(-EPS, .0, .0)),
                    map(pos + float3(.0, EPS, .0)) - map(pos + float3(.0, -EPS, .0)),
                    map(pos + float3(.0, .0, EPS)) - map(pos + float3(.0, .0, -EPS))
                ));
            }

            float3 lambert(float3 cameraPos, float3 rayDir, float depth){
                float3 normal = getNormal(cameraPos + rayDir * depth);
                float3 lightDir = normalize(mul(unity_WorldToObject, _WorldSpaceLightPos0).xyz);
                float NdotL = max(.0, dot(normal, lightDir));
                // float3 col = float3(1 + _SinTime.y * 1.25 / 2., 1. + _SinTime.z * 1.5 / 2., 1. + _SinTime.w * 2. / 2.);

                float3 rgb = _Color * _LightColor0.rgb * NdotL + fixed4(.3, .3, .3, 1.);
                return rgb;

            }

            float4 rayMarching(float3 oPos){
                float3 cameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 rayDir = normalize(oPos - cameraPos);
                float3 currentPos = cameraPos;
                bool isCollided = false;

                float dist, depth = .0;
                for(uint j = 0; j < _Iteration; j++){
                    float dist = map(currentPos);
                    depth += dist;
                    currentPos = cameraPos + depth * rayDir;
                    isCollided = EPS > dist;
                    if(abs(dist) < EPS) break;
                }

                fixed4 col = _Color;

                if(isCollided){
                    col.rgb *= lambert(cameraPos, rayDir, depth);
                }else{
                    discard;
                }

                return col;
            }
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.oPos = v.vertex.xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = rayMarching(i.oPos);

                return col;
            }
            ENDCG
        }
    }
}
