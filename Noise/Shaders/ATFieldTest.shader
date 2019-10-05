Shader "Bigdra/ATFieldTest"
{
    Properties
    {
        [HDR]_Color("Color", color) = (1, 1, 1, 1)
        [HDR]_SubColor("SubColor", color) = (1, 1, 1, 1)
        [IntRange]_N("n", Range(3, 10)) = 8
        _Destruction("Destruction Factor", Range(0, 1)) = 0
        _Pattern("Pattern Factor", float) = 2
        _PositionFactor("Position Factor", Vector) = (0, 1, 0, 0)
        [KeywordEnum(Random, Value, Block, Perlin, Simplex, Curl, Cellular, fBm)] _Noise("Noise Type", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Cull Off
        Blend SrcAlpha One
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "./Noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            static const float PI = 3.14159265;
            float4 _Color;
            float4 _SubColor;
            int _N;
            float _Destruction;
            float _Pattern;
            float4 _PositionFactor;


            
            float mod(float x, float y){
                return x - y * floor(x / y);
            }
            float2 mod(float2 x, float2 y){
                return x - y * floor(x / y);
            }
            float3 mod(float3 x, float3 y){
                return x - y * floor(x / y);
            }

            float3 rotate(float3 pos, float3 rotation){
                float3 a = normalize(rotation);
                float angle = length(rotation);
                if(abs(angle) < .001) return pos;
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

            float3 rgb2hsb(float3 col){
            float4 k = float4(.0, -1./3., 2./3., -1.);
            float4 p = lerp(float4(col.bg, k.wz),
                           float4(col.gb, k.xy),
                           step(col.b, col.g));
            float4 q = lerp(float4(p.xyw, col.r),
                           float4(col.r, p.yzx),
                           step(p.x, col.r));
            float d = q.x - min(q.w, q.y);
            float e = 1.e-10;
            return float3(abs(q.z + (q.w-q.y) / (6. * d + e)),
                          d / (q.x + e),
                          q.x);
            }
            
            float3 hsb2rgb(float3 col){
                // mapped x(.0 - 1.) to the hue(.0 - 1.)
                // and the y (.0 - 1.) to the brightness 
                float3 rgb = clamp(abs(mod(col.x * 6. + float3(.0, 4., 2.),
                                            6.) - 3.) - 1., 
                                   .0, 
                                   1.);
                rgb = rgb * rgb * (3. - 2. * rgb);
                return col.z * lerp(float3(1., 1., 1.), rgb, col.y);
             }
            
            
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

            appdata vert (appdata v)
            {
                return v;
            }

            #pragma multi_compile _NOISE_RANDOM _NOISE_BLOCK _NOISE_VALUE _NOISE_PERLIN _NOISE_SIMPLEX _NOISE_CURL _NOISE_FBM _NOISE_CELLULAR

            [maxvertexcount(3)]
            void geom(triangle appdata IN[3], inout TriangleStream<g2f> stream){
                float3 center = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;

                float3 edge1 = IN[1].vertex - IN[0].vertex;
                float3 edge2 = IN[2].vertex - IN[0].vertex;
                float3 normal = normalize(cross(edge1, edge2));

                fixed r = 2 * (random(center) - .5), r2 = random(center), r3 = random(center + 2);

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

                _Destruction /= 50;
                float3 noise = noiseSelector(noiseType, center.xyz);
                float rotation = _Destruction * length(_PositionFactor);
                float scale = _Destruction;
                float alpha = _Destruction * .6;

                [unroll]
                for(int i = 0; i < 3; i++){
                    g2f o = (g2f)0;
                    appdata v = IN[i];
                    v.vertex.xyz = (v.vertex.xyz - center) * (1. - _Destruction * scale) + center;
                    v.vertex.xyz = rotate(v.vertex.xyz - center, r3 * _Destruction * rotation) + center;
                    v.vertex.z += _Destruction * noise * _PositionFactor ;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.color.rgb = noise;
                    o.color.a = 1. - alpha;
                    o.uv = v.uv;
                    stream.Append(o);
                }
                stream.RestartStrip();
            }

            float dPolygon(float2 p, int n, float size){
                float a = atan2(p.x, p.y) + PI;
                float r = 2 * PI / n;
                return cos(floor(.5 + a / r) * r - a) * length(p) - size;
            }

            float map(float2 uv){
                float2 iPos = floor(uv);
                float2 fPos = frac(uv);

                fPos.x = fPos.x * 1. - .5;
                fPos.y = fPos.y * 1. - .5;

                return dPolygon(fPos * _Pattern, _N, 0) - _Time.x * 3.;
            }

            fixed4 frag (g2f i) : SV_Target
            {
                fixed4 col = i.color * (sin(map(i.uv) * 40) + 1) / 2;
                float2 st = i.uv * 2. - 1.;

                //col *= _Color;
                col = lerp(col, 0., (length(st)*.8));
                return saturate(col)*2.;
            }
            ENDCG
        }
    }
}
