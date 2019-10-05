Shader "Bigdra/ATField"
{
    Properties
    {
        [HDR]_Color("Color", color) = (1, 1, 1, 1)
        [HDR]_SubColor("Color", color) = (1, 1, 1, 1)
        _Offset("Off", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass{
            ZWrite ON
            ColorMask 0
        }

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
            };

            static const float PI = 3.14159265;
            static const float EPS = .0001;
            float4 _Color;
            float4 _SubColor;
            float _Offset;

            
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
            
            float2 opRepeat(float2 p, float interval){
                return mod(p, float2(interval, interval) * 2.) - interval;
            }

            appdata vert (appdata v)
            {
                return v;
            }

            [maxvertexcount(168)]
            void geom(triangle appdata IN[3], inout TriangleStream<g2f> stream){
                [unroll]
                for(int i = 0; i < 3; i++){
                    appdata v = IN[i];
                    g2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
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

                int n = 8;
                return dPolygon(fPos*_Offset, n, 0) - _Time.x * 3.;
            }

            fixed4 frag (g2f i) : SV_Target
            {
                fixed4 col = (sin(map(i.uv) * 40) + 1) / 2;
                float2 st = i.uv * 2. - 1.;

                if(col.r <= _Offset){
                    col *= _SubColor;
                    col = lerp(col, 0., (length(st)));
                    return saturate(col);
                }


                //col = lerp(_Color, 0., (sin(map(i.uv) * 40) + 1) / 2);
                col *= _Color;
                col = lerp(col, 0., (length(st)));


                return saturate(col);
            }
            ENDCG
        }
    }
}
