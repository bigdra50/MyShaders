// based on http://nn-hokuson.hatenablog.com/entry/2017/01/27/195659

#include "./Math.cginc"

// Block
float block(float2 seed){
    seed *= 8.;
    return random(floor(seed));
}

float block(float3 seed){
    seed *= 8;
    return random(floor(seed));
}

float2 block2D(float2 seed){
    seed *= 8;
    return random2D(floor(seed));
}

float3 block3D(float3 seed){
    seed *= 8;
    return random3D(floor(seed));
}

// ---

// Value

float value(float2 seed){
    float2 i = floor(seed);
    float2 f = frac(seed);

    float a = random(i);
    float b = random(i + float2(1, 0));
    float c = random(i + float2(0, 1));
    float d = random(i + float2(1, 1));

    float2 u = smoothstep(0, 1, f);

    float ab = lerp(a, b, u.x);
    float cd = lerp(c, d, u.x);
    return lerp(ab, cd, u.y);
}

float value(float3 seed){
    float3 i = floor(seed);
    float3 f = frac(seed);

    float o = random(i + float3(0, 0, 0));
    float x = random(i + float3(1, 0, 0));
    float y = random(i + float3(0, 1, 0));
    float z = random(i + float3(0, 0, 1));
    float xy = random(i + float3(1, 1, 0));
    float yz = random(i + float3(0, 1, 1));
    float xz = random(i + float3(1, 0, 1));
    float xyz = random(i + float3(1, 1, 1));

    float3 u = smoothstep(0., 1., f);

    float a = lerp(o, x, u.x);
    float b = lerp(y, xy, u.x);
    float c = lerp(yz, xyz, u.x);
    float d = lerp(z, xz, u.x);
    
    float ab = lerp(a, b, u.y);
    float cd = lerp(c, d, u.y);
    return lerp(ab, cd, u.z);
}


float2 value2D(float2 seed){
    float x = value(seed);
    float y = value(float2(seed.y - 19.1, seed.x + 47.2));
    return float2(x, y);
}

float3 value3D(float3 seed){
    seed *= 8;
    float x = value(seed);
    float y = value(float3(seed.y - 19.1, seed.z + 34.3, seed.x + 47.2));
    float z = value(float3(seed.z + 74.2, seed.x - 125.3, seed.y + 99.2));
    return float3(x, y, z);
}
// ---

// perlin

float perlin(float2 seed){
    float2 i = floor(seed);
    float2 f = frac(seed);

    float2 a = random2D(i);
    float2 b = random2D(i + float2(1, 0));
    float2 c = random2D(i + float2(0, 1));
    float2 d = random2D(i + float2(1, 1));

    //float2 u = smoothstep(0, 1, f);
    float2 u = f * f * f *(f * (f * 6 - 15) + 10);

    return lerp(lerp(dot(a, f - float2(0, 0)), dot(b, f - float2(1, 0)), u.x),
                lerp(dot(c, f - float2(0, 1)), dot(d, f - float2(1, 1)), u.x),
                u.y) + .5;
}

float perlin(float3 seed){
    float3 i = floor(seed);
    float3 f = frac(seed);

    float3 o = random3D(i + float3(0, 0, 0));
    float3 x = random3D(i + float3(1, 0, 0));
    float3 y = random3D(i + float3(0, 1, 0));
    float3 z = random3D(i + float3(0, 0, 1));
    float3 xy = random3D(i + float3(1, 1, 0));
    float3 yz = random3D(i + float3(0, 1, 1));
    float3 xz = random3D(i + float3(1, 0, 1));
    float3 xyz = random3D(i + float3(1, 1, 1));

    //float3 u = smoothstep(0., 1., f);               
    float3 u = f * f * f *(f * (f * 6 - 15) + 10);

    float a = lerp(dot(o, f - float3(0, 0, 0)), dot(x, f - float3(1, 0, 0)), u.x);
    float b = lerp(dot(y, f - float3(0, 1, 0)), dot(xy, f - float3(1, 1, 0)), u.x);
    float c = lerp(dot(z, f - float3(0, 0, 1)), dot(xz, f - float3(1, 0, 1)), u.x);
    float d = lerp(dot(yz, f - float3(0, 1, 1)), dot(xyz, f - float3(1, 1, 1)), u.x);

    float ab = lerp(a, b, u.y);
    float cd = lerp(c, d, u.y);
    return lerp(ab, cd, u.z) + .5;
}

float2 perlin2D(float2 seed){
    float x = perlin(seed);
    float y = perlin(float2(seed.y - 19.1, seed.x + 47.2));
    return float2(x, y);                
}

float3 perlin3D(float3 seed){
    seed *= 8;
    float x = perlin(seed);
    float y = perlin(float3(seed.y - 19.1, seed.z + 34.3, seed.x + 47.2));
    float z = perlin(float3(seed.z + 74.2, seed.x - 125.3, seed.y + 99.2));
    return float3(x, y, z);                
}

// ---

// simplex

// Based on https://www.shadertoy.com/view/Msf3WH
float simplex(float2 seed)
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

	float2  i = floor( seed + (seed.x + seed.y) * K1 );
    float2  a = seed - i + (i.x + i.y) * K2;
    float m = step(a.y, a.x); 
    float2  o = float2(m, 1. - m);
    float2  b = a - o + K2;
	float2  c = a - 1.0 + 2.0 * K2;
    float3  h = max( 0.5 - float3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	float3  n = h*h*h*h*float3( dot(a, random2D(i+0.0)), dot(b, random2D(i+o)), dot(c, random2D(i+1.0)));
    return dot( n, float3(70, 70, 70) );
}

// ---

// curl

//
// Description : Array and textureless GLSL 2D/3D/4D simplex
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//

float3 mod289(float3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 mod289(float4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 permute(float4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

float4 taylorInvSqrt(float4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float simplex(float3 v)
{
  const float2  C = float2(1.0/6.0, 1.0/3.0) ;
  const float4  D = float4(0.0, 0.5, 1.0, 2.0);

// First corner
  float3 i  = floor(v + dot(v, C.yyy) );
  float3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  float3 g = step(x0.yzx, x0.xyz);
  float3 l = 1.0 - g;
  float3 i1 = min( g.xyz, l.zxy );
  float3 i2 = max( g.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  float3 x1 = x0 - i1 + C.xxx;
  float3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  float3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = mod289(i);
  float4 p = permute( permute( permute(
             i.z + float4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + float4(0.0, i1.y, i2.y, 1.0 ))
           + i.x + float4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  float3  ns = n_ * D.wyz - D.xzx;

  float4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  float4 x_ = floor(j * ns.z);
  float4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  float4 x = x_ *ns.x + ns.yyyy;
  float4 y = y_ *ns.x + ns.yyyy;
  float4 h = 1.0 - abs(x) - abs(y);

  float4 b0 = float4( x.xy, y.xy );
  float4 b1 = float4( x.zw, y.zw );

  //float4 s0 = float4(lessThan(b0,0.0))*2.0 - 1.0;
  //float4 s1 = float4(lessThan(b1,0.0))*2.0 - 1.0;
  float4 s0 = floor(b0)*2.0 + 1.0;
  float4 s1 = floor(b1)*2.0 + 1.0;
  float4 sh = -step(h, float4(0, 0, 0, 0));

  float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  float3 p0 = float3(a0.xy,h.x);
  float3 p1 = float3(a0.zw,h.y);
  float3 p2 = float3(a1.xy,h.z);
  float3 p3 = float3(a1.zw,h.w);

//Normalise gradients
  float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1),
                                dot(p2,x2), dot(p3,x3) ) );
}

float2 simplex2D(float3 seed){
    float x = simplex(seed);
    float y = simplex(float2(seed.y - 19.1, seed.x + 47.2));
    return float2(x, y);                
}

float3 simplex3D(float3 seed){
    seed *= 8;
    float x = simplex(seed);
    float y = simplex(float3(seed.y - 19.1, seed.z + 34.3, seed.x + 47.2));
    float z = simplex(float3(seed.z + 74.2, seed.x - 125.3, seed.y + 99.2));
    return float3(x, y, z);                
}

float3 curl3D( float3 p ){

  const float e = 0.0009765625;
  const float e2 = 2.0 * e;

  float3 dx = float3( e   , 0.0 , 0.0 );
  float3 dy = float3( 0.0 , e   , 0.0 );
  float3 dz = float3( 0.0 , 0.0 , e   );

  float3 p_x0 = simplex3D( p - dx );
  float3 p_x1 = simplex3D( p + dx );
  float3 p_y0 = simplex3D( p - dy );
  float3 p_y1 = simplex3D( p + dy );
  float3 p_z0 = simplex3D( p - dz );
  float3 p_z1 = simplex3D( p + dz );

  float x = p_y1.z - p_y0.z - p_z1.y + p_z0.y;
  float y = p_z1.x - p_z0.x - p_x1.z + p_x0.z;
  float z = p_x1.y - p_x0.y - p_y1.x + p_y0.x;

  return normalize( float3( x , y , z ) / e2 );
}   

// ---

// cellular

float cellular(float2 seed){
    seed *= 8;
    float2 i = floor(seed);
    float2 f = frac(seed);

    float m_dist = 1e6;
    for(int y = -1; y <= 1; y++){
        for(int x = -1; x <= 1; x++){
            float2 neighbor = float2(float(x), float(y));
            float2 p = random2D(i + neighbor);
            // Animation
            p= .5 + .5 * sin(_Time.y + 6.2831 * p);
            float2 diff = neighbor + p - f;
            m_dist = min(m_dist, length(diff));
        }
    }

    return m_dist;
}

float cellular(float3 seed){
    seed *= 8;
    float3 i = floor(seed);
    float3 f = frac(seed);

    float m_dist = 1e6;
    for(int z = -1; z <= 1; z++)
    for(int y = -1; y <= 1; y++)
    for(int x = -1; x <= 1; x++){
        float3 neighbor = float3(float(x), float(y), float(z));
        float3 p = random3D(i + neighbor);

        // Animation
        p= .5 + .5 * sin(_Time.y + 6.2831 * p);
        float3 diff = neighbor + p - f;
        m_dist = min(m_dist, length(diff));
    }
    

    return m_dist;
}


float3 cellular3D(float3 seed){
    float x = cellular(seed);
    float y = cellular(float3(seed.y - 19.1, seed.z + 34.3, seed.x + 47.2));
    float z = cellular(float3(seed.z + 74.2, seed.x - 125.3, seed.y + 99.2));
    return float3(x, y, z);                
}

// ---

// fBm
float fBm(float2 seed){
    float f = 0;
    float2 q = seed;

    f += .5 * perlin(q);
    q *= 2.01;
    f += .25 * perlin(q);
    q *= 2.02;
    f += .1250 * perlin(q);
    q *= 2.03;
    f += .0625 * perlin(q);
    q *= 2.01;

    return f;
}

float fBm(float3 seed){
    float f = 0;

    f += .5 * cellular3D(seed);
    seed *= 2.01;
    f += .25 * cellular3D(seed);
    seed *= 2.02;
    f += .1250 * cellular3D(seed);
    seed *= 2.03;
    f += .0625 * cellular3D(seed);
    seed *= 2.01;

    return f;
}

float2 fBm2D(float2 seed){
    float x = fBm(seed);
    float y = fBm(float2(seed.y - 19.1, seed.x + 34.3));
    return float2(x, y);
}

float3 fBm3D(float3 seed){
    float x = fBm(seed);
    float y = fBm(float3(seed.y - 19.1, seed.z + 34.3, seed.x + 47.2));
    float z = fBm(float3(seed.z + 74.2, seed.x - 125.3, seed.y + 99.2));
    return float3(x, y, z);
}