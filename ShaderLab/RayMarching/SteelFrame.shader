Shader "Raymarching/SteelFrame"
{
    Properties
    {
        _Color ("Albedo", color) = (1, 1, 1, 1)
        [HDR] _EmissionColor("EmissionColor", color) = (0, 0, 0)

        [Header(Raymarching)]
        [IntRange] _Iteration ("Marching Iteration", Range(0, 1080)) = 128
        [IntRange] _RepeatInterval ("Repeat Interval", Range(1, 10)) = 1

        [Header(Sphere)]
        _Radius ("Radius", Range(0, 1.0)) = .5
        _SphereX("Offset X", float) = 0
        _SphereY("Offset Y", float) = 0
        _SphereZ("Offset Z", float) = 0

        [Header(Box)]
        _ScaleX ("Scale X", Range(.0, 5.0)) = .5
        _ScaleY ("Scale Y", Range(.0, 5.0)) = .5
        _ScaleZ ("Scale Z", Range(.0, 5.0)) = .5
        _BoxX("Offset X", float) = 0
        _BoxY("Offset Y", float) = 0
        _BoxZ("Offset Z", float) = 0

        [Header(Bar)]
        _BarWidth ("Width", Range(0, 1)) = .1
         _BarRepeat ("Repeat Interval", Range(0, 10)) = 1

        [Header(Tube)]
        _TubeWidth ("Width", Range(0, 1)) = .1
        _TubeRepeat ("Repeat Interval", Range(0, 10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
        LOD 100
        Cull Off

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
                float3 oPos : TEXCOORD1;
            };

            static float EPS = .00001;

            fixed4 _LightColor0;

            fixed4 _Color;
            fixed4 _EmissionColor;
            uint _Iteration;
            float _RepeatInterval;

            float _Radius;
            float _ScaleX;
            float _ScaleY;
            float _ScaleZ;
            float _SphereX;
            float _SphereY;
            float _SphereZ;
            float _BoxX;
            float _BoxY;
            float _BoxZ;

            float _BarWidth;
            float _BarRepeat;
            
            float _TubeWidth;
            float _TubeRepeat;

            float mod(float x, float y)
            {
            	return x - y * floor(x / y);
            }

            float2 mod(float2 x, float2 y)
            {
            	return x - y * floor(x / y);
            }

            float3 mod(float3 x, float3 y)
            {
            	return x - y * floor(x / y);
            }

            float4 mod(float4 x, float4 y)
            {
            	return x - y * floor(x / y);
            }

            // Distance Function
            float3 Repeat(float3 pos, float interval){
                return mod(pos, interval) - interval * .5;
            }

            float2 Repeat(float2 pos, float interval){
                return mod(pos, interval) - interval * .5;
            }

            float dSphere(float3 pos){
                float3 offset = float3(_SphereX, _SphereY, _SphereZ);
                return length(pos + offset) - _Radius;
            }

            float dBox(float3 pos){
                float3 offset = float3(_BoxX, _BoxY, _BoxZ);
                float3 scale = float3(_ScaleX, _ScaleY, _ScaleZ);
                return length(max(abs(pos + offset) - scale, .0));
            }

            float dBar(float3 pos){
                return length(max(abs(pos) - _BarWidth, .0));
            }

            float dBar(float2 pos){
                return length(max(abs(Repeat(pos, _BarRepeat)) - _BarWidth, .0));
            }

            float dTube(float2 pos){
                return length(Repeat(pos, _TubeRepeat)) - _TubeWidth;
            }

            float distFunc(float3 pos){
                float bar_x = dBar(pos.yz);
                float bar_y = dBar(pos.xz);
                float bar_z = dBar(pos.xy);

                float tube_x = dTube(pos.yz);
                float tube_y = dTube(pos.xz);
                float tube_z = dTube(pos.xy);

                return max(max(max(min(
                        min(bar_x, bar_y), bar_z),
                            -tube_x), -tube_y), -tube_z
                       );
            }

            float3 getNormal(float3 pos){
                return normalize(float3(
                    distFunc(pos + float3(EPS, .0, .0)) - distFunc(pos + float3(-EPS, .0, .0)),
                    distFunc(pos + float3(.0, EPS, .0)) - distFunc(pos + float3(.0, -EPS, .0)),
                    distFunc(pos + float3(.0, .0, EPS)) - distFunc(pos + float3(.0, .0, -EPS))
                ));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.oPos = v.vertex.xyz;  // メッシュのローカル座標
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 cameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 rayDir = normalize(i.oPos - cameraPos);
                float3 currentPos = cameraPos;
                bool isCollided = false;

                float dist, depth = .0;
                for(uint j = 0; j < _Iteration; j++){
                    float dist = distFunc(currentPos);
                    depth += dist;
                    currentPos = cameraPos + depth * rayDir;
                    currentPos.x += _Time.w;
                    isCollided = EPS > dist;
                    if(abs(dist) < EPS) break;
                }

                fixed4 col = _Color;

                if(isCollided){
                    float3 normal = getNormal(cameraPos + rayDir * depth);
                    float3 lightDir = normalize(mul(unity_WorldToObject, _WorldSpaceLightPos0).xyz);
                    float NdotL = max(.0, dot(normal, lightDir));

                    // ランバート反射
                    col.rgb = float3(1 + _SinTime.y * 1.25 / 2.0, 1.0 + _SinTime.z * 1.5 / 2.0, 1.0 + _SinTime.w * 2.0 / 2.0) * _LightColor0.rgb * NdotL + fixed4(.0, .0, .0, 1);

                    
                   // col.rgb = float4(float3(1 + _SinTime.y * 1.25 / 2.0, 1.0 + _SinTime.z * 1.5 / 2.0, 1.0 + _SinTime.w * 2.0 / 2.0) * NdotL, 1);
                }else{
                    discard;
                }
                //return col * _EmissionColor;
                return col;
            }
            ENDCG
        }
    }
}