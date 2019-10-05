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

    vec2 r = vec2(fragCoord.xy - iResolution.xy * .5);
    r = 2.0 * r.xy / iResolution.xy;

    vec3 backgroundColor = vec3(abs(sin(iTime)));
    vec3 axesColor = vec3(.0, 0.5, 1.0);
    vec3 gridColor = vec3(.8);

    vec3 pixel = backgroundColor;

    const float tickWidth = 0.1;
    if(mod(r.x, tickWidth) < .008)
        pixel = gridColor;
    if(mod(r.y, tickWidth) < .008)
        pixel = gridColor;

    if(abs(r.x) < .007)
        pixel = axesColor;
    if(abs(r.y) < .007)
        pixel = axesColor;

    fragColor = vec4(pixel, 1.0);
}