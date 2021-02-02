Shader "Bigdra/ATField"
{
    Properties
    {
        [HDR]_Color("Color", color) = (1, 1, 1, 1)
        [HDR]_SubColor("SubColor", color) = (1, 1, 1, 1)
        [IntRange]_N("n", Range(3, 10)) = 8
        _Destruction("Destruction Factor", Range(0, 1)) = 0
        _Pattern("Pattern Factor", float) = .6
        _PositionFactor("Position Factor", Vector) = (0, 1, 0, 0)
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

            
            float random(float2 seed){
               return frac(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453);
            }


//
// Noise Shader Library for Unity - https://github.com/keijiro/NoiseShader
//
// Original work (webgl-noise) Copyright (C) 2011 Ashima Arts.
// Translation and modification was made by Keijiro Takahashi.

            float3 mod289(float3 x)
            {
                return x - floor(x / 289.0) * 289.0;
            }

            float4 mod289(float4 x)
            {
                return x - floor(x / 289.0) * 289.0;
            }

            float4 permute(float4 x)
            {
                return mod289((x * 34.0 + 1.0) * x);
            }

            float4 taylorInvSqrt(float4 r)
            {
                return 1.79284291400159 - r * 0.85373472095314;
            }

            float snoise(float3 v)
            {
                const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);

                // First corner
                float3 i  = floor(v + dot(v, C.yyy));
                float3 x0 = v   - i + dot(i, C.xxx);

                // Other corners
                float3 g = step(x0.yzx, x0.xyz);
                float3 l = 1.0 - g;
                float3 i1 = min(g.xyz, l.zxy);
                float3 i2 = max(g.xyz, l.zxy);

                // x1 = x0 - i1  + 1.0 * C.xxx;
                // x2 = x0 - i2  + 2.0 * C.xxx;
                // x3 = x0 - 1.0 + 3.0 * C.xxx;
                float3 x1 = x0 - i1 + C.xxx;
                float3 x2 = x0 - i2 + C.yyy;
                float3 x3 = x0 - 0.5;

                // Permutations
                i = mod289(i); // Avoid truncation effects in permutation
                float4 p =
                  permute(permute(permute(i.z + float4(0.0, i1.z, i2.z, 1.0))
                                        + i.y + float4(0.0, i1.y, i2.y, 1.0))
                                        + i.x + float4(0.0, i1.x, i2.x, 1.0));

                // Gradients: 7x7 points over a square, mapped onto an octahedron.
                // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
                float4 j = p - 49.0 * floor(p / 49.0);  // mod(p,7*7)

                float4 x_ = floor(j / 7.0);
                float4 y_ = floor(j - 7.0 * x_);  // mod(j,N)

                float4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
                float4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;

                float4 h = 1.0 - abs(x) - abs(y);

                float4 b0 = float4(x.xy, y.xy);
                float4 b1 = float4(x.zw, y.zw);

                //float4 s0 = float4(lessThan(b0, 0.0)) * 2.0 - 1.0;
                //float4 s1 = float4(lessThan(b1, 0.0)) * 2.0 - 1.0;
                float4 s0 = floor(b0) * 2.0 + 1.0;
                float4 s1 = floor(b1) * 2.0 + 1.0;
                float4 sh = -step(h, 0.0);

                float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
                float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

                float3 g0 = float3(a0.xy, h.x);
                float3 g1 = float3(a0.zw, h.y);
                float3 g2 = float3(a1.xy, h.z);
                float3 g3 = float3(a1.zw, h.w);

                // Normalise gradients
                float4 norm = taylorInvSqrt(float4(dot(g0, g0), dot(g1, g1), dot(g2, g2), dot(g3, g3)));
                g0 *= norm.x;
                g1 *= norm.y;
                g2 *= norm.z;
                g3 *= norm.w;

                // Mix final noise value
                float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
                m = m * m;
                m = m * m;

                float4 px = float4(dot(x0, g0), dot(x1, g1), dot(x2, g2), dot(x3, g3));
                return 42.0 * dot(m, px);
            }

            float4 snoise_grad(float3 v)
            {
                const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);

                // First corner
                float3 i  = floor(v + dot(v, C.yyy));
                float3 x0 = v   - i + dot(i, C.xxx);

                // Other corners
                float3 g = step(x0.yzx, x0.xyz);
                float3 l = 1.0 - g;
                float3 i1 = min(g.xyz, l.zxy);
                float3 i2 = max(g.xyz, l.zxy);

                // x1 = x0 - i1  + 1.0 * C.xxx;
                // x2 = x0 - i2  + 2.0 * C.xxx;
                // x3 = x0 - 1.0 + 3.0 * C.xxx;
                float3 x1 = x0 - i1 + C.xxx;
                float3 x2 = x0 - i2 + C.yyy;
                float3 x3 = x0 - 0.5;

                // Permutations
                i = mod289(i); // Avoid truncation effects in permutation
                float4 p =
                  permute(permute(permute(i.z + float4(0.0, i1.z, i2.z, 1.0))
                                        + i.y + float4(0.0, i1.y, i2.y, 1.0))
                                        + i.x + float4(0.0, i1.x, i2.x, 1.0));

                // Gradients: 7x7 points over a square, mapped onto an octahedron.
                // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
                float4 j = p - 49.0 * floor(p / 49.0);  // mod(p,7*7)

                float4 x_ = floor(j / 7.0);
                float4 y_ = floor(j - 7.0 * x_);  // mod(j,N)

                float4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
                float4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;

                float4 h = 1.0 - abs(x) - abs(y);

                float4 b0 = float4(x.xy, y.xy);
                float4 b1 = float4(x.zw, y.zw);

                //float4 s0 = float4(lessThan(b0, 0.0)) * 2.0 - 1.0;
                //float4 s1 = float4(lessThan(b1, 0.0)) * 2.0 - 1.0;
                float4 s0 = floor(b0) * 2.0 + 1.0;
                float4 s1 = floor(b1) * 2.0 + 1.0;
                float4 sh = -step(h, 0.0);

                float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
                float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

                float3 g0 = float3(a0.xy, h.x);
                float3 g1 = float3(a0.zw, h.y);
                float3 g2 = float3(a1.xy, h.z);
                float3 g3 = float3(a1.zw, h.w);

                // Normalise gradients
                float4 norm = taylorInvSqrt(float4(dot(g0, g0), dot(g1, g1), dot(g2, g2), dot(g3, g3)));
                g0 *= norm.x;
                g1 *= norm.y;
                g2 *= norm.z;
                g3 *= norm.w;

                // Compute noise and gradient at P
                float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
                float4 m2 = m * m;
                float4 m3 = m2 * m;
                float4 m4 = m2 * m2;
                float3 grad =
                    -6.0 * m3.x * x0 * dot(x0, g0) + m4.x * g0 +
                    -6.0 * m3.y * x1 * dot(x1, g1) + m4.y * g1 +
                    -6.0 * m3.z * x2 * dot(x2, g2) + m4.z * g2 +
                    -6.0 * m3.w * x3 * dot(x3, g3) + m4.w * g3;
                float4 px = float4(dot(x0, g0), dot(x1, g1), dot(x2, g2), dot(x3, g3));
                return 42.0 * float4(grad, dot(m4, px));
            }

// ---

// curl Noise is based on https://github.com/cabbibo/glsl-curl-noise/blob/master/curl.glsl
            float3 snoiseVec3( float3 x ){
            
              float s  = snoise(float3( x ));
              float s1 = snoise(float3( x.y - 19.1 , x.z + 33.4 , x.x + 47.2 ));
              float s2 = snoise(float3( x.z + 74.2 , x.x - 124.5 , x.y + 99.4 ));
              float3 c = float3( s , s1 , s2 );
              return c;

            }


            float3 curlNoise( float3 p ){
            
              const float e = .1;
              float3 dx = float3( e   , 0.0 , 0.0 );
              float3 dy = float3( 0.0 , e   , 0.0 );
              float3 dz = float3( 0.0 , 0.0 , e   );

              float3 p_x0 = snoiseVec3( p - dx );
              float3 p_x1 = snoiseVec3( p + dx );
              float3 p_y0 = snoiseVec3( p - dy );
              float3 p_y1 = snoiseVec3( p + dy );
              float3 p_z0 = snoiseVec3( p - dz );
              float3 p_z1 = snoiseVec3( p + dz );

              float x = p_y1.z - p_y0.z - p_z1.y + p_z0.y;
              float y = p_z1.x - p_z0.x - p_x1.z + p_x0.z;
              float z = p_x1.y - p_x0.y - p_y1.x + p_y0.x;

              const float divisor = 1.0 / ( 2.0 * e );
              return normalize( float3( x , y , z ) * divisor );

            }            

// ---

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
            
            appdata vert (appdata v)
            {
                return v;
            }

            [maxvertexcount(3)]
            void geom(triangle appdata IN[3], inout TriangleStream<g2f> stream){
                float3 center = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;

                float3 edge1 = IN[1].vertex - IN[0].vertex;
                float3 edge2 = IN[2].vertex - IN[0].vertex;
                float3 normal = normalize(cross(edge1, edge2));

                fixed r = 2 * (random(center) - .5), r2 = random(center), r3 = random(center + 2);
                float3 curl = curlNoise(center.xyz);
                float rotation = _Destruction * length(_PositionFactor);
                float scale = _Destruction;
                float alpha = _Destruction * .7;

                [unroll]
                for(int i = 0; i < 3; i++){
                    g2f o = (g2f)0;
                    appdata v = IN[i];
                    v.vertex.xyz = (v.vertex.xyz - center) * (1. - _Destruction * scale) + center;
                    v.vertex.xyz = rotate(v.vertex.xyz - center, r3 * _Destruction * rotation) + center;
                    v.vertex.xyz += _Destruction * _PositionFactor * curl;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.color = _SubColor;
                    o.color.a *= 1. - _Destruction * alpha;
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

                if(col.r <= .0){
                    col *= _SubColor;
                    col = lerp(col, 0., (length(st)));
                    return saturate(col);
                }

                col *= _Color;
                col = lerp(col, 0., (length(st)));

                return saturate(col);
            }
            ENDCG
        }
    }
}
