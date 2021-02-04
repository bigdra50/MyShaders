Shader "Custom/VanishmentTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Line Color", color) = (1,1,1,1)
        _Vanish("Vanish", Range(0, 1)) = 1
        _ScanLineWidth("ScanLineWidth", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent" "Queue"="Transparent"
        }
        LOD 100

        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha


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
                float3 pos: TEXCOORD1;
                float3 worldPos: TEXCOORD2;
            };

            sampler2D _MainTex;
            fixed4 _Color;
            float4 _MainTex_ST;
            float _Vanish;
            float _ScanLineWidth;


            // <y> 上から下へ消失させるならuv.y,
            //     右から左へ消失させるならuv.x
            // <threshold> 消失点の位置
            void vanish(float y, float threshold)
            {
                clip(step(y, threshold) - .1);
            }

            // thresholdからwidthの範囲内の色を変化させる
            fixed4 scanLine(float y, float threshold, float width, fixed4 col)
            {
                return distance(y, threshold) < width ? fixed4(1 - col.rgb, .5) : col;
                //return distance(y, threshold) < width ? _Color*col : col;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos = v.vertex.xyz;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed2 st = i.uv * 2. - 1.; // -1~1
                float threshold = (2. + _ScanLineWidth) * clamp(_Vanish, 0., 1.) - 1.;
                fixed4 col = tex2D(_MainTex, st * .5);
                vanish(i.pos.y, threshold);
                col = scanLine(i.pos.y, threshold, _ScanLineWidth, col);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}