Shader "Bigdra/PietMondrian"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float3 rect(float2 bl, float2 tr, float2 st){
                float d = .02;
                float2 blInv = step(bl-d, st);
                float2 trInv = step(tr-d, 1.-st);
                float3 r2 = blInv.x * trInv.x * blInv.y * trInv.y;
                r2 = 1. - r2;
                // bottom - left
                bl = step(bl, st);
                //bl = smoothstep(bl, bl+.02, st);
                // top - right
                tr = step(tr, 1.-st);
                //tr = smoothstep(tr, tr+.02, 1.-st);
                float3 r1 = bl.x * tr.x * bl.y * tr.y;
                return r1 + r2;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 st = i.uv;
                float4 col;
                col.rgb = float3(248./256., 241./256., 225./256.);
                float d = .02;

                
                float3 hLine1 = rect(float2(.0, .68), float2(.0, .18), i.uv);
                float3 hLine2 = rect(float2(.25, .08), float2(.0, .0), i.uv);
                float3 vLine1 = rect(float2(.25, .0), float2(.25, .0), i.uv);
                float3 vLine2 = rect(float2(.98, .0), float2(.0, .0), i.uv);
                float3 vLine3 = rect(float2(.08, .68), float2(.0, .0), i.uv);

                col.rgb *= hLine1 * hLine2 * vLine1 * vLine2 * vLine3;

                if(i.uv.x <= .25 && i.uv.y >= .68){
                    col.gb = 0;
                }
                if(i.uv.x >= .98 && i.uv.y >= .68){
                    col.b = 0;
                }
                if(i.uv.x >= .75 && i.uv.y <= .08){
                    col.rg = 0;
                }
                
                return col;
            }

            ENDCG
        }
    }
}
