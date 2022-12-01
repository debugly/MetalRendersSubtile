/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Metal shaders the sample uses.
*/

#include <metal_stdlib>

using namespace metal;

// Include the headers that share types between the C code, which executes Metal API commands,
// and the shader code here, which uses the types as inputs to the shaders.

#import "AAPLShaderTypes-Common.h"

#ifdef USE_METAL3
#include "AAPLShaderTypes-Metal3.h"
#else
#include "AAPLShaderTypes-Metal2.h"

struct FragmentShaderArguments {
    texture2d<half> exampleTexture  [[ id(AAPLArgumentBufferIDExampleTexture)  ]];
    sampler         exampleSampler  [[ id(AAPLArgumentBufferIDExampleSampler)  ]];
    device float   *exampleBuffer   [[ id(AAPLArgumentBufferIDExampleBuffer)   ]];
    uint32_t        exampleConstant [[ id(AAPLArgumentBufferIDExampleConstant) ]];
    SubtitleFragmentArguments subRect [[ id(AAPLArgumentBufferIDExampleSubtitleRect) ]];
};
#endif

// The vertex shader outputs and the per-fragment inputs.
struct RasterizerData
{
    float4 position [[position]];
    float2 texCoord;
    half4  color;
};

vertex RasterizerData
vertexShader(             uint        vertexID [[ vertex_id ]],
             const device AAPLVertex *vertices [[ buffer(AAPLVertexBufferIndexVertices) ]])
{
    RasterizerData out;

    float2 position = vertices[vertexID].position;

    out.position.xy = position;
    out.position.z  = 0.0;
    out.position.w  = 1.0;

    out.texCoord = vertices[vertexID].texCoord;
    out.color    = (half4) vertices[vertexID].color;

    return out;
}

fragment float4
fragmentShader(       RasterizerData            in                 [[ stage_in ]],
               device FragmentShaderArguments & fragmentShaderArgs [[ buffer(AAPLFragmentBufferIndexArguments) ]])
{
    // Use the fragment position and the encoded constant in the argument buffer to calculate an array index.
    uint32_t index = (uint32_t)in.position.x % fragmentShaderArgs.exampleConstant;

    // Index into the encoded buffer in the argument buffer.
    float colorScale = fragmentShaderArgs.exampleBuffer[index];
    
    sampler exampleSampler = fragmentShaderArgs.exampleSampler;
    
    float2 texCoord = in.texCoord;
    SubtitleFragmentArguments subRect = fragmentShaderArgs.subRect;
    float sx = subRect.x;
    float sy = subRect.y;
    
    if (texCoord.x > sx && texCoord.x < (sx + subRect.w) && texCoord.y > sy && texCoord.y < (sy + subRect.h)) {
        texCoord.x = (texCoord.x - sx) / subRect.w;
        texCoord.y = (texCoord.y - sy) / subRect.h;
        //垂直翻转
        texCoord.y = 1 - texCoord.y;
        // Sample the encoded texture in the argument buffer.
        half4 textureSample = fragmentShaderArgs.exampleTexture.sample(exampleSampler, texCoord);
        // Add the subtitle and color values together and return the result.
        return float4((1.0 - textureSample.a) * colorScale * in.color + textureSample);
    }  else {
        // Add the sample and color values together and return the result.
        return float4(colorScale * in.color);
    }
}
