Shader "Unlit/FructalGradation"
{
    Properties
    {
        [IntRange]_Size("Size", range(1, 10)) = 1
        _Color ("Color", color) = (1, 1, 1, 1)
        _Color2("Sub Color", color) = (1, 1, 1, 1)

        [Toggle] _Gradation("Gradation", float) = 0
        _Degress("Degress", Range(0, 360)) = 0
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            static const float PI = 3.14159265;
            static const float toRad = PI / 180;
            static const float EPS = .0001;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            int _Size;
            fixed4 _Color;
            fixed4 _Color2;
            float _Degress;


// ------ Noise Func ------

            float random(float2 p){
                return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
            }

// ------

// ------ math ------

            float2 rotate(float2 pos, float angle){
                float2 a = normalize(angle);
                float s = sin(angle);
                float c = cos(angle);
                return float2(pos.x * c - pos.y * s,
                               pos.x * s + pos.y * c);
            }

            float3 rotate(float3 pos, float angle){
                float3 a = normalize(angle);
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

            float opUnion(float d1, float d2)
            {
                return min(d1, d2);
            }

            float2 opUnion(float2 d1, float2 d2)
            {
                return d1.x < d2.x ? d1 : d2;
            }

            float opSubstract(float d1, float d2)
            {
                return max(d1, -d2);
            }
            
            float opIntersect(float d1, float d2)
            {
                return max(d1, d2);
            }
            
            float3 opRepeat(float3 pos, float3 interval)
            {
                return mod(pos, interval * 2.) - interval;
            }
            
            float3 opRepeat(float3 pos, float interval)
            {
                return opRepeat(pos, float3(interval, interval, interval));
            }

// ------

// ------ Distancce Func ------

            float dCircle(float2 pos, float radius){
                return length(pos) - radius;
            }

            float dEllipse(float2 pos, float2 radius, float size){
                return length(pos / radius) - size;
            }

            float dRectangle(float2 pos, float2 size){
                return max(abs(pos.x) - size.x, abs(pos.y) - size.y);
            }

            float dRhombus(float2 pos, float size){
                return abs(pos.x) + abs(pos.y) - size;
            }

            float dPolygon(float2 pos, int n, float size){
                float a = atan2(pos.x, pos.y) + PI;
                float r = 2 * PI / n;
                return cos(floor(.5 + a / r) * r - a) * length(pos) - size;
            }

            float dRing(float2 pos, float size, float w){
                return abs(length(pos) - size) + w;
            }

            float dStar(float2 pos, int n, float t, float size){
                float a = 2 * PI / float(n) / 2;
                float c = cos(a);
                float s = sin(a);
                float2 r = mul(pos, float2x2(c, -s, s, c));
                return (dPolygon(pos, n, size) - dPolygon(r, n, size) * t) / (1 - t);
            }

            float dHeart(float2 pos, float size){
                pos.x = 1.2 * pos.x - sign(pos.x) * pos.y * .55;
                return length(pos) - size;
            }

// ------


            float time;

            float map(float2 uv){
                for(uint j = 0; j < _Size; j++){
                    uv = frac(uv) * 2 - 1;
                }
//                float circle = dCircle(uv, .2);
//                float ellipse = dEllipse(uv, float2((_SinTime.w + 1) * .5, (_CosTime.w + 1) * .5), _SinTime.w + 1);
//                float rect = dRectangle(uv, float2((_SinTime.w + 1) * .25, _CosTime.w + 1 * .25));
//                float rhombus = dRhombus(uv, _SinTime.w + 1);
//                float polygon = dPolygon(uv, 7, (_SinTime.w + 1) * .5);
//                float ring = dRing(uv, .5, _SinTime.w * .4);
                float star = dStar(uv, 5, .5, .1);
                float heart = dHeart(uv, .1);

                time = (sin(_Time.y * 1.5) + 1) * .5;
                float canvas = lerp(heart, star, time);
                return canvas;
            }


// ------ by @uzimaru0000 ------

            float ratio(float2 pos) {
                float offs = (sqrt(2) - 1) * abs(sin(2 * _Degress * toRad)) + 1;
                return (pos.x * sin(_Degress * toRad) + pos.y * cos(_Degress * toRad)) / offs;
            }

            fixed4 gradient(float p) {
                return lerp(_Color, _Color2, p + time);
            }

// ------

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            #pragma multi_compile _GRADATION_ON
            fixed4 frag (v2f i) : SV_Target
            {
                float2 st = frac(i.uv) * 2. -1.;

                fixed4 col = smoothstep(.5, .51, map(i.uv));

                if(col.r >= 1. && col.g >= 1. && col.b >= 1. ){
                    discard;
                }

                #ifdef _GRADATION_ON
                col = gradient(ratio(st));
                #else
                col = lerp(_Color, _Color2, time);
                #endif

                return col;
            }
            ENDCG
        }
    }
}
