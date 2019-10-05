Shader "Bigdra/Rune"
{
    Properties
    {
        [IntRange]_Density("Density", Range(0, 20)) = 0
        [IntRange]_Amount("Amount", Range(1, 50.)) = 10.
        [KeywordEnum(Random, Value, Block, Perlin, fBm)] _Noise("Noise Type", float) = 0
        // トグルだと常にランダムになった
        //[Toggle] _IsRuneRandom("IsRuneRandom", float) = 1
        [IntRange]_IsRuneRandom("IsRuneRandom", Range(0, 1)) = 1
        [IntRange]_RuneId("Rune ID", Range(0, 25)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"
            static float PI = 3.14159265;
            static float EPS = .0001;

            int _Density;
            int _Amount;
            int _RuneId;
            int _IsRuneRandom;


// ------------------- Noise ---------------------------

            float random(float p){
                return frac(sin(p) * 43758.5453);
            }

            float random(float2 p){
                return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
            }

            float2 random2(float2 st){
                st = fixed2( dot(st,fixed2(127.1,311.7)),
                               dot(st,fixed2(269.5,183.3)) );
                return -1.0 + 2.0*frac(sin(st)*43758.5453123);
            }

            float blockNoise(float2 st){
                float2 p = floor(st);
                return random(p);
            }

            float valueNoise(fixed2 st)
            {
                fixed2 p = floor(st);
                fixed2 f = frac(st);

                float v00 = random(p + fixed2(0, 0));
                float v01 = random(p + fixed2(0, 1));
                float v10 = random(p + fixed2(1, 0));
                float v11 = random(p + fixed2(1, 1));

                fixed2 sm = smoothstep(0.0, 1.0, f);

                float v0010 = lerp(v00, v10, sm.x);
                float v0111 = lerp(v01, v11, sm.x);

                return lerp(v0010, v0111, sm.y);
            }

            float perlinNoise(fixed2 st) 
            {
                fixed2 p = floor(st);
                fixed2 f = frac(st);
                fixed2 u = f*f*(3.0-2.0*f);

                float v00 = random2(p+fixed2(0,0));
                float v10 = random2(p+fixed2(1,0));
                float v01 = random2(p+fixed2(0,1));
                float v11 = random2(p+fixed2(1,1));

                return lerp( lerp( dot( v00, f - fixed2(0,0) ), dot( v10, f - fixed2(1,0) ), u.x ),
                             lerp( dot( v01, f - fixed2(0,1) ), dot( v11, f - fixed2(1,1) ), u.x ), 
                             u.y)+0.5f;
            }

            float fBm (float2 st) 
            {
                float f = 0;
                float2 q = st;

                f += 0.5000*perlinNoise( q ); q = q*2.01;
                 f += 0.2500*perlinNoise( q ); q = q*2.02;
                f += 0.1250*perlinNoise( q ); q = q*2.03;
                f += 0.0625*perlinNoise( q ); q = q*2.01;

                return f;
            }

// -----------------------------------------------------

// -------------------------- Math --------------------

            float2 rotate(float2 pos, float angle){
                angle = angle * PI / 180.;
                float2 a = normalize(angle);
                float s = sin(angle);
                float c = cos(angle);
                return float2(pos.x * c - pos.y * s,
                               pos.x * s + pos.y * c);
            }

            float3 rotate(float3 pos, float angle){
                float3 a = normalize(angle);
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

            float dot(float3 v){
                return dot(v, v);
            }

            float opUnion(float d1, float d2)
            {
                return min(d1, d2);
            }

            float2 opUnion(float2 d1, float2 d2)
            {
                return d1.x < d2.x ? d1 : d2;
            }

            float opSubstract(float d1, float d2)
            {
                return max(d1, -d2);
            }
            
            float opIntersect(float d1, float d2)
            {
                return max(d1, d2);
            }

            float2 opRepeat(float2 pos, float2 interval){
                return mod(pos, interval *2.) - interval;
            }
            
            float3 opRepeat(float3 pos, float3 interval)
            {
                return mod(pos, interval * 2.) - interval;
            }
            
            float3 opRepeat(float3 pos, float interval)
            {
                return opRepeat(pos, float3(interval, interval, interval));
            }

// ------------------------------------------------------

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

// --------------------------------------------------------


// ---------------- Distance Function ----------------------

            float dRoundRect(float2 pos, float2 size){
                float2 d = abs(pos) - size;
                return length(max(d, .0))
                    + min(max(d.x, d.y), .0);
            }

            

// ----------------- Rune -------------------------
            // フェオ
            float dFeoh(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;
                pos.x += 1.;
                float rect1 = dRoundRect(pos, float2(width, 10));
                float rect2 = dRoundRect(rotate(float2(pos.x - 3., pos.y - 6.8), 45.), float2(width, 4.));
                float rect3 = dRoundRect(rotate(float2(pos.x - 3., pos.y - 1.8), 45.), float2(width, 4.));

                return opUnion(rect1, opUnion(rect2, rect3));
            }

            // ウル
            float dUr(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(float2(pos.x + 5., pos.y + .5), float2(width, 9.5));
                float rect2 = dRoundRect(float2(pos.x - 5., pos.y + 2.), float2(width, 8));
                float rect3 = dRoundRect(rotate(float2(pos.x, pos.y - 7.5), 106), float2(width, 5.3));

                return opUnion(rect1, opUnion(rect2, rect3));
            }

            // ソーン
            float dThorn(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                pos.x += 1.;
                float rect1 = dRoundRect(pos, float2(width, 10));
                float rect2 = dRoundRect(rotate(float2(pos.x - 5.5, abs(pos.y)), 130), float2(width, 7));

                return opUnion(rect1, rect2);
            }

            // アンスール
            float dAnsur(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                pos.x += 1.;
                float rect1 = dRoundRect(pos, float2(width, 10));
                float rect2 = dRoundRect(rotate(float2(pos.x - 3., pos.y - 7.), -45.), float2(width, 4.));
                float rect3 = dRoundRect(rotate(float2(pos.x - 3., pos.y - 2.), -45.), float2(width, 4.));

                return opUnion(rect1, opUnion(rect2, rect3));                
            }

            // ラド
            float dRad(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                pos.x += 1.;
                float rect1 = dRoundRect(pos, float2(width, 10));
                float rect2 = dRoundRect(rotate(float2(pos.x - 5.5, abs(pos.y - 5.45)), 130), float2(width, 7));
                float rect3 = dRoundRect(rotate(float2(pos.x - 4, pos.y + 3.), 130), float2(width, 5.));

                return opUnion(rect1, opUnion(rect2, rect3));
            }

            // ケン
            float dKen(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                pos.x += 1.;
                float rect1 = dRoundRect(rotate(float2(pos.x, abs(pos.y)), 45.), float2(width, 10));

                return rect1;

            }

            float dGeofu(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(rotate(float2(pos.x, pos.y), 45.), float2(width, 10));
                float rect2 = dRoundRect(rotate(float2(pos.x, -pos.y), 45.), float2(width, 10));

                return opUnion(rect1, rect2);
            }

            float dWynn(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                pos.x += 1.;
                float rect1 = dRoundRect(pos, float2(width, 10));
                float rect2 = dRoundRect(rotate(float2(pos.x - 5.5, abs(pos.y - 5.45)), 130), float2(width, 7));

                return opUnion(rect1, rect2);
            }

            float dHagall(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(float2(pos.x + 6., pos.y + .5), float2(width, 9.5));
                float rect2 = dRoundRect(float2(pos.x - 6., pos.y + .5), float2(width, 9.5));
                float rect3 = dRoundRect(rotate(float2(pos.x, pos.y), 120), float2(width, 6.5));

                return opUnion(rect1, opUnion(rect2, rect3));
            }

            float dNied(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(pos, float2(width, 10));
                float rect2 = dRoundRect(rotate(float2(pos.x, pos.y - 1.), 120), float2(width, 6.5));
                
                return opUnion(rect1, rect2);
            }

            float dIs(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect = dRoundRect(pos, float2(width, 10));
                return rect;
            }

            float dJara(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(rotate(float2(pos.x + 6., abs(pos.y - 2.)), 50.), float2(width, 7.));
                float rect2 = dRoundRect(rotate(float2(pos.x - 6., abs(pos.y + 2.)), -50.), float2(width, 7.));

                return opUnion(rect1, rect2);
            }

            float dYr(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(pos, float2(width, 10));
                float rect2 = dRoundRect(rotate(float2(pos.x - 3.1, pos.y - 7.35), -50.), float2(width, 4.));
                float rect3 = dRoundRect(rotate(float2(pos.x + 3.1, pos.y + 7.35), -50.), float2(width, 4.));

                return opUnion(rect1, opUnion(rect2, rect3));

            }

            float dPeorth(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                pos.x += 1.;
                float rect1 = dRoundRect(float2(pos.x + 5., pos.y), float2(width, 8.));
                float rect2 = dRoundRect(rotate(float2(abs(pos.x - 1.4), pos.y - 3.15), 53.), float2(width, 8.));
                float rect3 = dRoundRect(rotate(float2(abs(pos.x - 1.4), pos.y + 3.15), -53.), float2(width, 8.));
                
                return opUnion(rect1, opUnion(rect2, rect3));
            }

            float dEolh(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(float2(pos.x, pos.y), float2(width, 10.));
                float rect2 = dRoundRect(rotate(float2(abs(pos.x), pos.y - 2.), 45.), float2(width, 8.));

                return opUnion(rect1, rect2);
            }

            float dSigel(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(rotate(float2(pos.x - .7, pos.y + 4.), 53.), float2(width, 4.));
                float rect2 = dRoundRect(rotate(float2(pos.x - .7, pos.y - .7), -53.), float2(width, 4.));
                float rect3 = dRoundRect(rotate(float2(pos.x - .7, pos.y - 5.5), 53.), float2(width, 4.));

                return opUnion(rect1, opUnion(rect2, rect3));
            }

            float dTir(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(float2(pos.x, pos.y), float2(width, 10.));
                float rect2 = dRoundRect(rotate(float2(pos.x - 3.3, pos.y - 7.5), -53.), float2(width, 4.));
                float rect3 = dRoundRect(rotate(float2(pos.x + 3.3, pos.y - 7.5), 53.), float2(width, 4.));
                
                return opUnion(rect1, opUnion(rect2, rect3));
            }

            float dBeorc(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;
                pos.x += 2.;

                float rect1 = dRoundRect(float2(pos.x, pos.y), float2(width, 10.));
                float rect2 = dRoundRect(rotate(float2(pos.x - 3.3, pos.y - 7.5), -53.), float2(width, 4.));
                float rect3 = dRoundRect(rotate(float2(pos.x - 3.3, pos.y - 2.7), 53.), float2(width, 4.));
                float rect4 = dRoundRect(rotate(float2(pos.x - 3.3, pos.y + 7.5), 53.), float2(width, 4.));
                float rect5 = dRoundRect(rotate(float2(pos.x - 3.3, pos.y + 2.7), -53.), float2(width, 4.));
                
                return opUnion(rect1, opUnion(rect2, opUnion(rect3, opUnion(rect4, rect5))));
            }

            float dEoh(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(float2(pos.x - 7, pos.y + .5), float2(width, 9.5));
                float rect2 = dRoundRect(float2(pos.x + 7., pos.y + .5), float2(width, 9.5));
                float rect3 = dRoundRect(rotate(float2(pos.x - 3.5, pos.y - 6.4), 54.), float2(width, 4.3));
                float rect4 = dRoundRect(rotate(float2(pos.x + 3.5, pos.y - 6.4), -54.), float2(width, 4.3));

                return opUnion(rect1, opUnion(rect2, opUnion(rect3, rect4)));
            }

            float dMann(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(float2(pos.x - 7, pos.y + .5), float2(width, 9.5));
                float rect2 = dRoundRect(float2(pos.x + 7., pos.y + .5), float2(width, 9.5));
                float rect3 = dRoundRect(rotate(float2(pos.x - 3.5, pos.y - 6.9), 60.), float2(width, 4.1));
                float rect4 = dRoundRect(rotate(float2(pos.x + 3.5, pos.y - 6.9), -60.), float2(width, 4.1));
                float rect5 = dRoundRect(rotate(float2(pos.x + 3.5, pos.y - 3.), 60.), float2(width, 4.1));
                float rect6 = dRoundRect(rotate(float2(pos.x - 3.5, pos.y - 3.), -60.), float2(width, 4.1));

                return opUnion(rect1, opUnion(rect2, opUnion(rect3, opUnion(rect4, opUnion(rect5, rect6)))));
            }

            float dLagu(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;
                pos.x += 1.;

                float rect1 = dRoundRect(float2(pos.x, pos.y), float2(width, 9.5));
                float rect2 = dRoundRect(rotate(float2(pos.x - 3., pos.y - 6.5), -45.), float2(width, 4.3));

                return opUnion(rect1, rect2);
            }

            float dIng(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(rotate(float2(pos.x - 3.5, pos.y + 3.5), 45.), float2(width, 5.));
                float rect2 = dRoundRect(rotate(float2(pos.x + 3.5, pos.y + 3.5), -45.), float2(width, 5.));
                float rect3 = dRoundRect(rotate(float2(pos.x + 3.5, pos.y - 3.5), 45.), float2(width, 5.));
                float rect4 = dRoundRect(rotate(float2(pos.x - 3.5, pos.y - 3.5), -45.), float2(width, 5.));
                
                return opUnion(rect1, opUnion(rect2, opUnion(rect3, rect4)));
            }

            float dOthel(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(rotate(float2(pos.x - .5, pos.y + 3.5), 45.), float2(width, 6.));
                float rect2 = dRoundRect(rotate(float2(pos.x + .5, pos.y + 3.5), -45.), float2(width, 6.));
                float rect3 = dRoundRect(rotate(float2(pos.x + .5, pos.y - 3.3), 45.), float2(width, 3.5));
                float rect4 = dRoundRect(rotate(float2(pos.x - .5, pos.y - 3.3), -45.), float2(width, 3.5));
                
                return opUnion(rect1, opUnion(rect2, opUnion(rect3, rect4)));
            }

            float dDaeg(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;

                float rect1 = dRoundRect(float2(pos.x - 7, pos.y), float2(width, 9.5));
                float rect2 = dRoundRect(float2(pos.x + 7., pos.y), float2(width, 9.5));
                float rect3 = dRoundRect(rotate(float2(pos.x, pos.y ), 36.5), float2(width, 11.7));
                float rect4 = dRoundRect(rotate(float2(pos.x, pos.y ), -36.5), float2(width, 11.7));

                return opUnion(rect1, opUnion(rect2, opUnion(rect3, rect4)));
            }

            float dBlank(float2 pos, float size){
                pos *= 100. / size;
                float width = .1;
                return 1.;
            }

// ---------------------------------------

// ----------------- Selector --------------

            float RuneSelector(int n, float2 uv, float size){
                return  n == 0 ? dFeoh(uv, size):
                        n == 1 ? dUr(uv, size):
                        n == 2 ? dThorn(uv, size):
                        n == 3 ? dAnsur(uv, size):
                        n == 4 ? dRad(uv, size):
                        n == 5 ? dKen(uv, size):
                        n == 6 ? dGeofu(uv, size):
                        n == 7 ? dWynn(uv, size):
                        n == 8 ? dHagall(uv, size):
                        n == 9 ? dNied(uv, size):
                        n == 10 ? dIs(uv, size):
                        n == 11 ? dJara(uv, size):
                        n == 12 ? dYr(uv, size):
                        n == 13 ? dPeorth(uv, size):
                        n == 14 ? dEolh(uv, size):
                        n == 15 ? dSigel(uv, size):
                        n == 16 ? dTir(uv, size):
                        n == 17 ? dBeorc(uv, size):
                        n == 18 ? dEoh(uv, size):
                        n == 19 ? dMann(uv, size):
                        n == 20 ? dLagu(uv, size):
                        n == 21 ? dIng(uv, size):
                        n == 22 ? dOthel(uv, size):
                        n == 23 ? dDaeg(uv, size):
                        dBlank(uv, size);
            }

            float noiseSelector(int n, float2 uv){
                return n == 0 ? random(uv):
                       n == 1 ? blockNoise(uv):
                       n == 2 ? valueNoise(uv):
                       n == 3 ? perlinNoise(uv):
                       fBm(uv);
            }

// ---

            float time;

            #pragma multi_compile _NOISE_RANDOM _NOISE_BLOCK _NOISE_VALUE _NOISE_PERLIN _NOISE_FBM

            #pragma _multi_compile _ISRUNERANDOM_ON

            float map(float2 uv){
                
                float2 ipos = floor(uv * _Amount);
                float2 fpos = frac(uv * _Amount);

                int noiseType = 0;
                #ifdef _NOISE_BLOCK
                    noiseType = 1;
                #elif _NOISE_VALUE
                    noiseType = 2;
                #elif _NOISE_PERLIN
                    noiseType = 3;
                #elif _NOISE_FBM
                    noiseType = 4;
                #else
                    noiseType = 0;
                #endif

                float runeId = 0;
                if(_IsRuneRandom){ 
                    runeId = random(ipos) * 24.;

                    runeId = mod(blockNoise(_Time.y * (1. + random(ipos)) + noiseSelector(noiseType, fpos)) * 10, 24.);
                }
                else{
                    runeId = _RuneId;
                }

                fpos.x = fpos.x * 2. - 1.;
                fpos.y = fpos.y * 1.2 - .6;

                return RuneSelector(runeId * _Density, fpos, 5.);
            }

            fixed4 frag (v2f_img i) : SV_Target
            {
                float4 col = step(.5, map(i.uv));
                
                if(col.r >= 1. && col.g >= 1. && col.b >= 1. ){
                    discard;
                }
                col.rgb += hsb2rgb(float3(frac(_Time.x), 1, 1));
  
                return col;
            }
            ENDCG
        }
    }
}
