Shader "Unlit/TestRaymarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _diffuse("Diffuse", color) = (1, 1, 1, 1)
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
                float3 oPos : TEXCOORD1;
            };

            static float EPS = .001;
            static uint MarchingIteration = 256;
            float4 _LightColor0;

            float4 _diffuse;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            // math
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


            float3 rotate(float3 pos, float3 axis, float angle){
                //float3 axis = float3(_AxisX, _AxisY, _AxisZ);
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.oPos = v.vertex.xyz;
                return o;
            }

            float dSphere(float3 p){
                float radius = .5;
                return length(p) - radius;
            }

            float dPlane(float3 pos){
                return pos.y;
            }

            float dBox(float3 pos, float size){
                pos = abs(pos) - float3(size, size, size);
                return max(max(pos.x, pos.y), pos.z);
            }

            float map(float3 p){
                return dBox(p, .3);
            }

            float3 getNormal(float3 raypos){
                float2 eps = float2(EPS, 0);
                return normalize(float3(
                    map(raypos + eps.xy.xyy) - map(raypos - eps.xy.xyy),
                    map(raypos + eps.xy.yxy) - map(raypos - eps.xy.yxy),
                    map(raypos + eps.xy.yyx) - map(raypos - eps.xy.yyx)
                ));
            }

            float3 lambert(float3 diffuse, float3 normal){
                float3 lightDir = normalize(mul(unity_WorldToObject, _WorldSpaceLightPos0));
                return diffuse * _LightColor0.rgb * max(0, dot(normal, lightDir)) + float3(.1, .1, .1);

            }

            float3 rayMarching(float3 p){
                float3 col = float3(.0, .0, .0);
                //float3 ro = float3(0, 0, -3);
                 float3 ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                // float fov = 2.5;
                float3 rd = normalize(p - ro);
                float3 ray = ro;
                float distance;
                float3 normal;

                // ループ回数
                uint k = 0;
                bool isCollided = false;
                for(uint j = 0; j < MarchingIteration; j++){
                    distance = map(ray);
                    if(distance < EPS){
                        isCollided = true;
                        normal = getNormal(ray);
                        break; 
                    }
                    k = j;
                    ray += distance * rd;
                }


                // Ambient Occulusion
                col += (float)k / MarchingIteration;
                 
                 if(isCollided){
                    // Lambert
                    col += lambert(_diffuse, normal);
                 }else{
                     discard;
                 }

                return col;
            }

            fixed4 frag (v2f i) : SV_Target
            {
//                float2 p = 2 * i.uv - 1.;
                fixed4 col = float4(rayMarching(i.oPos), 1.);
                return col;
            }
            ENDCG
        }
    }
}
