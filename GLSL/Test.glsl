#define PI 3.14159265359

// Cheat Sheet of HLSL To GLSL
#define float2 vec2 
#define float3 vec3 
#define  float4 vec4
#define mat2 float2x2
#define mat4 float4x4
#define _Time.y iTime 
#define fmod mod 
#define lerp mix 
#define atan2 atan 
#define frac fract
#define tex2D texture 
#define _ScreenParams iResolution 

vec3 rgbNormalize(vec3 col){
    return vec3(col.x / 256.0, col.y / 256.0, col.z / 256.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    vec2 r = 2.0 * vec2(fragCoord.xy - iResolution.xy * 0.5) / iResolution.y;

    vec3 backgroundColor = vec3(abs(sin(iTime)));
    vec3 col1 = vec3(.216, .471, .698);
    vec3 col2 = vec3(1.0, .329, .298);
    vec3 col3 = vec3(.867, .910, .247);

    vec3 pixel = backgroundColor;

    float radius = 0.8;
    if(r.x * r.x + r.y * r.y < radius * radius){
        pixel = col1;
    }

    if( length(r) < .3){
        pixel = col3;
    }

    vec2 center = vec2(.6, -.4);
    vec2 d = r - center;
    if(length(d) < .6){
        pixel = col2;
    }


    fragColor = vec4(pixel, 1.0);
}