Shader "LearnShader/MyLit"{
    Properties{
        [Header(Surface Options)]
        [MainTexture] _ColorMap("Color Map", 2D) = "white" {}
        
        [NormalTexture]_NormalMap ("Normal Map", 2D) = "bump" {}
        [NormalScale]_NormalScale ("Normal Scale", Range(0,1)) = 1.0
        
        [RoughnessTexture]_RoughnessMap("Roughness Map", 2D) = "white" {}
        [RoughnessScale]_RoughnessScale ("Roughness Scale", Range(0,1)) = 1.0
        
        [MetallicTexture]_MetallicMap("Metallic Map", 2D) = "black" {}
        [MetallicScale]_MetallicScale ("Metallic Scale", Range(0,1)) = 1.0
        
        [AOTexture]_AOMap("AO Map", 2D) = "white" {}
        [AOScale]_AOScale ("AO Scale", Range(0,1)) = 1.0
        
        [LUT]_BRDFLut("BRDF LUT", 2D) = "white" {}
    }
    SubShader{
        Tags
        {
            "RenderPipeline"="UniverPipeline"
            "RenderType" = "Opaque"
        }

        Pass{
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "MyLitShaderFile.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "MyLitShaderShadow.hlsl"
            ENDHLSL
        }
    }
}
