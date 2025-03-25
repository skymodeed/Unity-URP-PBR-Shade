#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#define PI 3.141592654

struct Attributes{
    float3 positionOS: POSITION;
    float3 normalOS: NORMAL;
    float2 uv: TEXCOORD0;
    float4 tangentOS: TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Interpolators{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
    float4 TtoW0 : TEXCOORD1;
    float4 TtoW1 : TEXCOORD2;
    float4 TtoW2 : TEXCOORD3;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

TEXTURE2D(_ColorMap); 
SAMPLER(sampler_ColorMap);
TEXTURE2D(_NormalMap); 
SAMPLER(sampler_NormalMap);
TEXTURE2D(_RoughnessMap);
SAMPLER(sampler_RoughnessMap);
TEXTURE2D(_MetallicMap);
SAMPLER(sampler_MetallicMap);
TEXTURE2D(_AOMap);
SAMPLER(sampler_AOMap);
TEXTURE2D(_BRDFLut);
SAMPLER(sampler_BRDFLut);

float4 _ColorMap_ST;
float _NormalScale;
float _RoughnessScale;
float _MetallicScale;
float _GlossScale;
float _AOScale;

Interpolators Vertex(Attributes input){
    Interpolators output;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
    
    output.positionCS = posnInputs.positionCS;
    output.uv = TRANSFORM_TEX(input.uv, _ColorMap);

    float3 worldPos = posnInputs.positionWS;
    float3 worldNormal = normalInputs.normalWS;
    float3 worldTangent = normalInputs.tangentWS;
    float3 worldBinormal = cross(worldNormal, worldTangent)*input.tangentOS.w;

    output.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
    output.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
    output.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

    return output;
}

inline half3 DecodeHDR(half4 data, half4 decodeInstructions, int colorspaceIsGamma)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    half alpha = decodeInstructions.w * (data.a - 1.0) + 1.0;

    // If Linear mode is not supported we can skip exponent part
    if(colorspaceIsGamma)
        return (decodeInstructions.x * alpha) * data.rgb;

    return (decodeInstructions.x * pow(alpha, decodeInstructions.y)) * data.rgb;
}

// Decodes HDR textures
// handles dLDR, RGBM formats
inline half3 DecodeHDR (half4 data, half4 decodeInstructions)
{
    #if defined(UNITY_COLORSPACE_GAMMA)
    return DecodeHDR(data, decodeInstructions, 1);
    #else
    return DecodeHDR(data, decodeInstructions, 0);
    #endif
}

float D_GGX_TR(float NdotH, float roughness)
{
    float a2 = (roughness * roughness);
    NdotH = max(NdotH, 0.0f);
    float NdotH2 = NdotH * NdotH;
    float denom = (NdotH2*(a2-1.0)+1.0);
    denom = PI * denom * denom;
    denom = max(denom, 0.001f);
    return a2 / denom;
}

float3 SchlickFresnel(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(float3(1 ,1, 1) * (1 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;
    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    return num / denom;
}
float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

float4 Fragment(Interpolators input): SV_TARGET{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    
    float2 uv = input.uv;
    float3 positionWS = float3(input.TtoW0.w,input.TtoW1.w,input.TtoW2.w);
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    Light mainLight = GetMainLight(shadowCoord);

    //world space normal
    float3 lightDir = mainLight.direction;
    float3 viewDir = GetWorldSpaceNormalizeViewDir(positionWS);
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,uv),_NormalScale);
    normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy,normalTS.xy)));
    
    float3 normalWS = normalize(float3(dot(input.TtoW0.xyz, normalTS),dot(input.TtoW1.xyz, normalTS),dot(input.TtoW2.xyz, normalTS)));

    float AO = SAMPLE_TEXTURE2D(_AOMap,sampler_AOMap,uv);
    float roughness = SAMPLE_TEXTURE2D(_RoughnessMap,sampler_RoughnessMap,uv).r*_RoughnessScale;
    float3 Metallic = SAMPLE_TEXTURE2D(_MetallicMap,sampler_MetallicMap,uv)*_MetallicScale;
    
    float3 halfDir = normalize(mainLight.direction + viewDir);
    
    float3 albedo = SAMPLE_TEXTURE2D(_ColorMap,sampler_ColorMap,uv).rgb;

    //Main Light 
    float3 NdotH = dot(normalWS,halfDir);
    float3 NdotL = dot(normalWS,lightDir);
    float nv = max(saturate(dot(normalWS,viewDir)),0.000001);
    float F0 = lerp(float3(0.04,0.04,0.04), albedo, Metallic);
    
    float D = D_GGX_TR(NdotH, roughness);
    float G = GeometrySmith(normalWS,viewDir,lightDir,roughness);
    float3 F = SchlickFresnel(NdotL, F0, roughness);
    
    float denominator = 4.0 * max(dot(normalWS, viewDir), 0.0) * max(dot(normalWS, lightDir), 0.0) + 0.001;
    
    float KD = (float3(1,1,1) - F)*(float3(1,1,1) - Metallic);
    float3 diffuse = KD * albedo * lerp(1, AO, _AOScale) / PI;
    float3 specular = D*F*G/denominator;
    
    //IBL
    half3 ambient_contrib = SampleSHVertex(normalWS);
    float3 ambient = 0.03 * albedo;
    float3 iblDiffuse = max(half3(0, 0, 0), ambient.rgb + ambient_contrib);
    
    
    float mip_roughness = roughness * (1.7 - 0.7 * roughness);
    float3 reflectVec = reflect(-viewDir, normalWS);
    half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;
    half3 iblSpecular = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVec, mip), unity_SpecCube0_HDR);;

    float2 envBRDF = SAMPLE_TEXTURE2D(_BRDFLut,sampler_BRDFLut,float2(lerp(0, 0.99, nv), lerp(0, 0.99, roughness)));
    float3 Flast = SchlickFresnel(max(nv, 0.0), F0, roughness);
    float kdLast = (1 - Flast) * (1 - Metallic);
    
    float3 iblDiffuseResult = iblDiffuse * kdLast * albedo;
    float3 iblSpecularResult = iblSpecular * (Flast * envBRDF.r + envBRDF.g);
    float3 IndirectResult = iblDiffuseResult + iblSpecularResult;
    
    float3 finalColor = (diffuse + specular)  * mainLight.color * mainLight.shadowAttenuation * NdotL;

    //additional light
    #ifdef _ADDITIONAL_LIGHTS
    uint additionalLightsCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < additionalLightsCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, positionWS ,shadowCoord);
        lightDir = light.direction;
        halfDir = normalize(lightDir + viewDir);
            
        NdotL = max(dot(normalWS, lightDir), 0.0);
        NdotH = max(dot(normalWS, halfDir), 0.0);
            
        // Recalculate D, G, F for this light
        D = D_GGX_TR(NdotH, roughness);
        G = GeometrySmith(normalWS, viewDir, lightDir, roughness);
        F = SchlickFresnel(NdotL, F0, roughness);
            
        denominator = 4.0 * max(dot(normalWS, viewDir), 0.0) * NdotL + 0.001;
            
        KD = (float3(1,1,1) - F)*(float3(1,1,1) - Metallic);
        diffuse = KD * albedo * lerp(1, AO, _AOScale) / PI;
        specular = D*F*G/denominator;
            
        // Add this light's contribution
        finalColor += (diffuse + specular) * light.color * light.shadowAttenuation * light.distanceAttenuation * NdotL;
    }
    #endif
    
    return float4 (finalColor+IndirectResult, 1);
}
