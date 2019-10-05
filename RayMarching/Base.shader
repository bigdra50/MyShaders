Shader "Raymarching/Base"
{
	Properties
	{
        [Header(Debug)]
        _Offset0("Offset 0", Range(0, 1)) = 0
        _Offset1("Offset 1", Range(0, 10)) = 0
        _Offset2("Offset 2", Range(0, 10)) = 0
        _Offset3("Offset 3", Range(0, 10)) = 0

		[Header(Raymarching)]
		_Speed("Speed", Range(1, 5)) = 2


        [Header(Rendering)]
        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull("Cull", Float) = 0                // Off

        [Enum(UnityEngine.Rendering.CompareFunction)]
        _ZTest("ZTest", Float) = 4              // LEqual

        [Enum(Off, 0, On, 1)]
        _ZWrite("ZWrite", Float) = 0            // Off

        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcFactor("Src Factor", Float) = 5     // SrcAlpha

        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstFactor("Dst Factor", Float) = 10    // OneMinusSrcAlpha

	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
		LOD 100
		Cull [_Cull]
		ZTest [_ZTest]
		ZWrite [_ZWrite]
		Blend [_SrcFactor] [_DstFactor]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#include "UnityCG.cginc"
            #include "../Include/Math.cginc"
            #include "../Include/Primitives.cginc"

            // For Debug

            float _Offset0;
            float _Offset1;
            float _Offset2;
            float _Offset3;


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 oPos : TEXCOORD1;
			};

			const float EPS = .00001;
			sampler2D _MainTex;
			float4 _MainTex_ST;

            fixed4 _LightColor0;
			
			float3 hue(float3 color, float shift) {
		 	   	static float3  kRGBToYPrime = float3 (0.299, 0.587, 0.114);
		 	   	static float3  kRGBToI     = float3 (0.596, -0.275, -0.321);
		 	   	static float3  kRGBToQ     = float3 (0.212, -0.523, 0.311);

		 	   	static float3  kYIQToR   = float3 (1.0, 0.956, 0.621);
		 	   	static float3  kYIQToG   = float3 (1.0, -0.272, -0.647);
		 	   	static float3  kYIQToB   = float3 (1.0, -1.107, 1.704);

		 	   	// Convert to YIQ
		 	   	float   YPrime  = dot (color, kRGBToYPrime);
		 	   	float   I      = dot (color, kRGBToI);
		 	   	float   Q      = dot (color, kRGBToQ);

		 	   	// Calculate the hue and chroma
		 	   	float   hue     = atan2 (Q, I);
		 	   	float   chroma  = sqrt (I * I + Q * Q);

		 	   	// Make the user's adjustments
		 	   	hue += shift;

		 	   	// Convert back to YIQ
		 	   	Q = chroma * sin (hue);
		 	   	I = chroma * cos (hue);

		 	   	// Convert back to RGB
		 	   	float3    yIQ   = float3 (YPrime, I, Q);
		 	   	color.r = dot (yIQ, kYIQToR);
		 	   	color.g = dot (yIQ, kYIQToG);
		 	   	color.b = dot (yIQ, kYIQToB);

		 	   	return color;
			}


			float map(float3 pos )
			{
                return sdSphere(pos, .1);
			}

			float castRay( float3 ro, float3 rd )
			{
			    float tmax = 100.0;
				//ro.z = _Time.z * _Speed;

				float depth = .0;
				float3 rPos = ro;

				// marching loop
			    for( int j = 0; j < 128; j++ )
			    {
			   		float distance = map(rPos);

					if(distance < EPS)
					{
						return depth;
					}

			        if(depth > tmax )
					{
                        return -1;
						//return distance / 30;
					}

			        depth += distance;
					rPos = ro + rd * depth;
			    }

				return depth;
			}


			float3 calcNormal( float3 pos )
			{
				float3 eps = float3( 0.01, 0.0, 0.0 );
				float3 nor = float3(
				   map(pos+eps.xyy).x - map(pos-eps.xyy).x,
				   map(pos+eps.yxy).x - map(pos-eps.yxy).x,
				   map(pos+eps.yyx).x - map(pos-eps.yyx).x );
				return normalize(nor);
			}

            float3 lambert(float3 cameraPos, float3 rayDir, float depth){
                float3 normal = calcNormal(cameraPos + rayDir * depth);
                float3 lightDir = normalize(mul(unity_WorldToObject, _WorldSpaceLightPos0).xyz);
                float NdotL = max(.0, dot(normal, lightDir));
                // float3 col = float3(1 + _SinTime.y * 1.25 / 2., 1. + _SinTime.z * 1.5 / 2., 1. + _SinTime.w * 2. / 2.);

                float3 col = _LightColor0.rgb * NdotL + fixed3(.55, .55, .55);
                return col;

            }

			float calcAO( float3 pos, float3 nor )
			{
				float occ = 0.0;
			    float sca = 1.0;
			    for( int i=0; i<5; i++ )
			    {
			        float hr = 0.01 + 0.12 *float(i)/4.0;
			        float3 aopos =  nor * hr + pos;
			        float dd = map( aopos ).x;
			        occ += -(dd-hr)*sca;
			        sca *= .95;
			    }
			    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
			}

			float3 render(float3 cameraPos, float3 rayDir )
			{ 
			    float3 col = 1.;
			    float d = castRay(cameraPos, rayDir);

			    if(d > 0) //res > -.5 )
			    {
			        float3 pos = cameraPos + d * rayDir;
			        float3 nor = calcNormal( pos );

			        float occ = calcAO( pos, nor );
					//col = 1-hue(float3(0.0,1.0,1.0), _Time.w * .5 + pos);
                    col *= lambert(cameraPos, rayDir, d) * occ;
			    }else{
                    discard;
                }
                return saturate(col);

			}


			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.oPos = v.vertex.xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = 1;

				float3 cameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
				float3 rayDir = normalize(i.oPos - cameraPos);

				col.rgb = render(cameraPos, rayDir);


				return col;
			}
			ENDCG
		}
	}
}
