#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes{
    float3 positionOS: POSITION;
    float3 normalOS: NORMAL;
    float2 uv: TEXCOORD0;
    float4 tangentOS: TANGENT;
};

struct Interpolators{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
    float3 positionWS: TEXCOORD1;
    float3 normalWS: TEXCOORD2;
    float4 tangentWS: TEXCOORD3;
};

float4 _ColorTint;
TEXTURE2D(_ColorMap); 
SAMPLER(sampler_ColorMap);
TEXTURE2D(_NormalMap); 
SAMPLER(sampler_NormalMap);
float _NormalScale;
float4 _ColorMap_ST;
float _GlossScale;

Interpolators Vertex(Attributes input){
    Interpolators output;

    VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

    float3 binormal =cross(normalize(input.normalOS),normalize(input.tangentOS.xyz));
    float3x3 rotation = float3x3(input.tangentOS.xyz,binormal,input.normalOS);

    output.positionCS = posnInputs.positionCS;
    output.positionWS = posnInputs.positionWS;
    output.uv = TRANSFORM_TEX(input.uv, _ColorMap);
    output.tangentWS = float4(normalInputs.tangentWS, input.tangentOS.w);
    output.normalWS = normalInputs.normalWS;

    return output;
}


float4 Fragment(Interpolators input): SV_TARGET{
    float2 uv = input.uv;
    Light mainLight = GetMainLight();

    //world space normal
    float3 normalWS = normalize(input.normalWS);
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,uv),_NormalScale);
    float3x3 tangentToWorld = CreateTangentToWorld(normalWS,input.tangentWS.xyz,input.tangentWS.w);
    normalWS = normalize(TransformTangentToWorld(normalTS,tangentToWorld));

    float3 viewDir = GetWorldSpaceNormalizeViewDir(input.positionWS);
    
    float3 colorSample = SAMPLE_TEXTURE2D(_ColorMap,sampler_ColorMap,uv).rgb;
    float3 diffuse = mainLight.color * colorSample * max(0, dot(normalWS, mainLight.direction));
    float3 halfDir = normalize(mainLight.direction + viewDir);
    float3 specular = mainLight.color * pow(max(0,dot(normalWS,halfDir)),_GlossScale);

    return float4 ( diffuse + specular,1 );
}
