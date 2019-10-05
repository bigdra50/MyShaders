Shader "Unlit/LearnGeometry"
{
    Properties
    {
        [IntRange]_Count("Count", range(1, 30)) = 1
        _Color("Color", color) = (1, 1, 1, 1)
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
            #pragma geometry geom
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            struct v2g
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                float color : COLOR;
            };

            static const float PI = 3.1415926535;
            float4 _Color;
            int _Count;


// ------------------- Noise ---------------------------

            float random(float p){
                return frac(sin(p) * 43758.5453);
            }

            float random(float2 p){
                return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
            }

            float2 random2(float2 st){
                st = fixed2( dot(st,fixed2(127.1,311.7)),
                               dot(st,fixed2(269.5,183.3)) );
                return -1.0 + 2.0*frac(sin(st)*43758.5453123);
            }



            float blockNoise(float2 st){
                float2 p = floor(st);
                return random(p);
            }

            float valueNoise(fixed2 st)
            {
                fixed2 p = floor(st);
                fixed2 f = frac(st);

                float v00 = random(p + fixed2(0, 0));
                float v01 = random(p + fixed2(0, 1));
                float v10 = random(p + fixed2(1, 0));
                float v11 = random(p + fixed2(1, 1));

                fixed2 sm = smoothstep(0.0, 1.0, f);

                float v0010 = lerp(v00, v10, sm.x);
                float v0111 = lerp(v01, v11, sm.x);

                return lerp(v0010, v0111, sm.y);
            }

            float perlinNoise(fixed2 st) 
            {
                fixed2 p = floor(st);
                fixed2 f = frac(st);
                fixed2 u = f*f*(3.0-2.0*f);

                float v00 = random2(p+fixed2(0,0));
                float v10 = random2(p+fixed2(1,0));
                float v01 = random2(p+fixed2(0,1));
                float v11 = random2(p+fixed2(1,1));

                return lerp( lerp( dot( v00, f - fixed2(0,0) ), dot( v10, f - fixed2(1,0) ), u.x ),
                             lerp( dot( v01, f - fixed2(0,1) ), dot( v11, f - fixed2(1,1) ), u.x ), 
                             u.y)+0.5f;
            }

            float fBm (float2 st) 
            {
                float f = 0;
                float2 q = st;

                f += 0.5000*perlinNoise( q ); q = q*2.01;
                 f += 0.2500*perlinNoise( q ); q = q*2.02;
                f += 0.1250*perlinNoise( q ); q = q*2.03;
                f += 0.0625*perlinNoise( q ); q = q*2.01;

                return f;
            }

// -----------------------------------------------------

// -------------------------- Math --------------------

            float2 rotate(float2 pos, float angle){
                angle = angle * PI / 180.;
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

            float2 opRepeat(float2 pos, float2 interval){
                return mod(pos, interval *2.) - interval;
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

            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                o.normal = v.normal;
                return o;
            }

            [maxvertexcount(90)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> OutputStream)
            {
                g2f o = (g2f)0;

                float3 edgeA = IN[1].vertex - IN[0].vertex;
                float3 edgeB = IN[2].vertex - IN[0].vertex;
                float3 normal = normalize(cross(edgeA, edgeB));

                for(int i = 0; i < _Count; i++){
                    [unroll]
                    for(int j = 0; j < 3; j++){
                        o.vertex = UnityObjectToClipPos(IN[j].vertex);
                        o.vertex = UnityObjectToClipPos(float4(rotate(IN[j].vertex.xyz, i ), 1.));
                        o.uv = IN[j].uv;
                        o.normal = IN[j].normal;
                        o.color = float4(1, 1, 1, 1);
                        OutputStream.Append(o);
                    }
                    OutputStream.RestartStrip();
                }

            }


            fixed4 frag (g2f i) : SV_Target
            {
                return _Color;
            }
            ENDCG
        }
    }
}
