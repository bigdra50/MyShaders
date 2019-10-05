Shader "Custom/OldTV"
{
	Properties
	{
		_MainTex ("Display Texture", 2D) = "white" {}
		_Thick ("Stripe Thickness", Range(0, 10)) = 5

		[Header(Noise)]
		_RGBNoise("ノイズ", Range(0, 1)) = 0 
		_NoiseR("Red Offset", Range(1, 2)) = 0
		_NoiseG("Green Offset", Range(1, 2)) = 0
		_NoiseB("Blue Offset", Range(1, 2)) = 0

		[Header(Glitch)]
		_GlitchInterval("Interval", Range(.01, 10)) = 2.
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
			float _Thick;
			float _RGBNoise;
			float _NoiseR;
			float _NoiseG;
			float _NoiseB;

			float _GlitchInterval;
			
			
			// Math Func
			float mod(float x, float y){
				return x - y * floor(x / y);
			}

			float2 mod(float2 x, float2 y){
				return x - y * floor(x / y);
			}

			float3 mod(float3 x, float3 y){
				return x - y * floor(x / y);
			}

			// Noise Effect
			fixed rand(fixed st) {
				return frac(sin(dot(st, fixed2(12.9898, 78.233))) * 43758.5453);
			}

			fixed2 rand2(fixed2 st) {
				st = fixed2(dot(st, fixed2(127.1, 311.7)),
							dot(st, fixed2(269.5, 183.3)));
				
				return -1. + 2. * frac(sin(st) + 43758.5453123);
			}

			float perlinNoise(fixed2 st){
				fixed2 p = floor(st);
				fixed2 f = frac(st);
				fixed2 u = f * f * (3.-2.*f);

				float v00 = rand2(p + fixed2(0, 0));
				float v10 = rand2(p + fixed2(1, 0));
				float v01 = rand2(p + fixed2(0, 1));
				float v11 = rand2(p + fixed2(1, 1));

				return lerp(lerp(dot(v00, f-fixed2(0, 0)), dot(v10, f-fixed2(1, 0)), u.x),
							lerp(dot(v01, f-fixed2(0, 1)), dot(v11, f-fixed2(1, 1)), u.x),
							u.y) + .5;
			}

			// Filter Effects

			// hotizontal displacement map
			float glitchAmount(float gTimeOffset){
				float xRange = 20.;
				float x = mod((_Time.y + gTimeOffset) * xRange / _GlitchInterval, xRange);
				return sin(x) / pow(x, 3.);
			}

			float2 hotizontalGlitch(float2 pos, float timeOffset){
				float noiseValue = (perlinNoise(floor(float2(pos.y * 100., _Time.y + timeOffset)) / 1.01) - .5) * glitchAmount(0.) * 2.;
				pos.x += noiseValue * 3.;
				return pos;
			}

			
			fixed4 stripe(v2f i)
			{
			    return step(0, sin(_Thick * 100 * i.uv.y));
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				i.uv = hotizontalGlitch(i.uv, 0);
				fixed4 col = tex2D(_MainTex, i.uv);
				
				col.r += rand(i.uv + float2(123 + _Time.y, 0)) * _RGBNoise * _NoiseR;
				col.g += rand(i.uv + float2(123 + _Time.y, 1)) * _RGBNoise * _NoiseG;
				col.b += rand(i.uv + float2(123 + _Time.y, 2)) * _RGBNoise * _NoiseB;

				col *= stripe(i);
				return col;
			}
			ENDCG
		}
	}
}
