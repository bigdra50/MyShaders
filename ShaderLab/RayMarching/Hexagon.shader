Shader "Raymarching/hexagon"
{
	Properties
	{
		[Header(Raymarching)]
		[IntRange] _Iteration("Marching Iteration", Range(0, 1024)) = 512
		_Speed("Speed", Range(1, 5)) = 2
		[IntRange] _ExRepeat("Ex Repeat", range(0, 3)) = 1
		[IntRange] _InRepeat("In Repeat", range(0, 3)) = 1

		[Header(Rotation)]
		_AxisX ("Rotate Axis X", Range(-1, 1)) = 0
		_AxisY ("Rotate Axis Y", Range(-1, 1)) = 0
		_AxisZ ("Rotate Axis Z", Range(-1, 1)) = 0

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
				float4 vertex : SV_POSITION;
				float3 oPos : TEXCOORD1;
			};

			static float EPS = .00001;
			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _AxisX;
			float _AxisY;
			float _AxisZ;
			uint _Iteration;
			float _Speed;
			uint _ExRepeat;
			uint _InRepeat;
			
			float mod(float x, float y){
				return x - y * floor(x/y);
			}

			float2 mod (float2 x, float2 y){
				return x - y * floor(x / y);
			}

			float3 mod (float3 x, float3 y){
				return x - y * floor(x / y);
			}

			float4 mod(float4 x, float4 y){
				return x - y * floor(x / y);
			}

			float3 rotate(float3 pos, float angle, float3 axis){
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

			float smoothMin(float d1, float d2, float k){
				float h = exp(-k * d1) + exp(-k * d2);
				return -log(h) / k;
			}

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

			float3 Repeat(float3 pos, float interval){
				return mod(pos, interval) - interval * .5;
			}

			float sdHexPrism( float3 p, float2 h )
			{
				float3 q = rotate(p, radians(_Time.w * 50.0), float3(_AxisX, _AxisY, _AxisZ));
			    q = abs(q);
			    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
			}

			float sdBox( float3 p, float3 b )
			{
			  float3 d = abs(p) - b;
			  return min(max(d.x,max(d.y,d.z)),0.0) +
			         length(max(d,0.0));
			}

			float opS( float d1, float d2 )
			{
			    return max(-d1,d2);
			}

			float2 opU( float2 d1, float2 d2 )
			{
				return (d1.x<d2.x) ? d1 : d2;
			}

			float2 map(float3 pos )
			{
			    //pos.x += sin(pos.z+iTime)*0.2;
			    //pos.y += cos(pos.z+iTime)*0.2;

			    float height = .42;
			    float depth = .75;
			    float t = 0.02 + _SinTime.x * .01;
			    pos.z = mod(pos.z, depth * 2.) - 0.5 * depth * 2.;

			   	float cyl = sdHexPrism( Repeat(pos, _ExRepeat), float2(height - t, depth + t));
			   	float scyl = sdHexPrism( Repeat(pos, _InRepeat), float2(height - t * 2.0, depth + t + .001));

			    float2 res = float2(opS(scyl, cyl), 1.5); 
			    float2 final = res;

			    for (int i = 1; i < 3; i++) {
				
			        height -= 0.1;
			        depth -= 0.19;
			    	// cyl = sdHexPrism( Repeat(pos, _InRepeat), float2(height - t, depth + t));
			    	cyl = sdHexPrism( pos, float2(height - t, depth + t));
			    	// scyl = sdHexPrism( Repeat(pos, _InRepeat), float2(height - t * 2.0, depth + t + .001));
			    	scyl = sdHexPrism( pos, float2(height - t * 2.0, depth + t + .001));

			        final = opU(final, float2(opS(scyl, cyl), 2.5)); 

			    }

			    return final;
			}

			float2 castRay( float3 ro, float3 rd )
			{
			    float tmin = .0;
			    float tmax = 100.0;
				ro.z = _Time.z * _Speed;

			    float t = tmin;
			    float m = -1.0;
			    for( int j = 0; j < _Iteration; j++ )
			    {
			   		float2 res = map( ro + rd * t );
			        if(t > tmax ) break;
			        t += res.x;
			   		m = res.y;
			    }

			    if( t > tmax ) m = -1.0;
			    return float2( t, m );
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
			    float2 res = castRay(cameraPos, rayDir);
			    float t = res.x;
				float m = res.y;

			    if( m > -0.5 )
			    {
			        float3 pos = cameraPos + t * rayDir;
			        float3 nor = calcNormal( pos );
			        float3 ref = reflect( rayDir, nor );

			        // material        
			        float occ = calcAO( pos, nor );
					col = 1.0 - hue(float3(0.0,1.0,1.0), _Time.w * .5 + pos.z) * occ;
			    }

				return float3( clamp(col,0.0,1.0) );
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
				fixed4 col;
				// camera 
				float3 cameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
				 
				// ray direction
				float3 rayDir = normalize(i.oPos - cameraPos);

				// render
				col.rgb = render(cameraPos, rayDir);

				col.a = 1;
				return col;
			}
			ENDCG
		}
	}
}
