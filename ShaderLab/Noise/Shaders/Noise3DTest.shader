Shader "Unlit/NoiseTest3D"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [KeywordEnum(Random, Value, Block, Perlin, Simplex, Curl, Cellular, fBm)] _Noise("Noise Type", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "./Noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            float3 noiseSelector(int n, float3 pos){
                return n == 0 ? random3D(pos):
                       n == 1 ? block3D(pos):
                       n == 2 ? value3D(pos):
                       n == 3 ? perlin3D(pos):
                       n == 4 ? simplex3D(pos):
                       n == 5 ? curl3D(pos):
                       n == 6 ? cellular3D(pos):
                       fBm3D(pos);
            }
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            #pragma multi_compile _NOISE_RANDOM _NOISE_BLOCK _NOISE_VALUE _NOISE_PERLIN _NOISE_SIMPLEX _NOISE_CURL _NOISE_FBM _NOISE_CELLULAR

            fixed4 frag (v2f i) : SV_Target
            {
                float4 col = 0;
                int noiseType = 0;
                #ifdef _NOISE_BLOCK
                    noiseType = 1;
                #elif _NOISE_VALUE
                    noiseType = 2;
                #elif _NOISE_PERLIN
                    noiseType = 3;
                #elif _NOISE_SIMPLEX
                    noiseType = 4;
                #elif _NOISE_CURL
                    noiseType = 5;
                #elif _NOISE_CELLULAR
                    noiseType = 6;
                #elif _NOISE_RANDOM
                    noiseType = 0;
                #else
                    noiseType = 100;
                #endif
                //col.rgb = simplex(i.uv)
                //col.rgb = simplex3d(i.worldPos * 8);
                //col.rgb = noiseSelector(noiseType, (i.worldPos + _Time.x) * 8);
                col.rgb = noiseSelector(noiseType, (i.worldPos));
                return col;
            }
            ENDCG
        }
    }
}
