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

void disk(vec2 r, vec2 center, float radius, vec3 col, inout vec3 pixel){
    if(length(r - center) < radius){
        pixel = col;
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    vec2 r = 2.0 * vec2(fragCoord.xy - iResolution.xy * 0.5) / iResolution.y;
    float xMax = iResolution.x / iResolution.y;

    vec3 backgroundColor = vec3(abs(sin(iTime)));
    vec3 col1 = vec3(.216, .471, .698);
    vec3 col2 = vec3(1.0, .329, .298);
    vec3 col3 = vec3(.867, .910, .247);

    vec3 pixel = backgroundColor;
    float edge, variable, ret;

    if(r.x < -.6 * xMax){
        variable = r.y;
        edge = .2;
        if(variable > edge){
            ret = 1.0;
        } else {
            ret = .0;
        }
    }else if(r.x < -.2 * xMax){
        variable = r.y;
        edge = -.2;
        ret = step(edge, variable);
    }else if(r.x < .2 * xMax){
        ret = 1.0 - step(.5, r.y);
    }else if(r.x < .6 * xMax){
        ret = .3 + .5 * step(-.4, r.y);
    }else{
        ret = step(-.3, r.y) * (1.0 - step(.2, r.y));
    }

    pixel = vec3(ret);
    fragColor = vec4(pixel, .8);
}