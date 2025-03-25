Shader "LearnShader/MyLit"{
    Properties{
        [Header(Surface Options)]
        [MainTexture] _ColorMap("Color Map", 2D) = "white" {}
        
        [NormalTexture]_NormalMap ("Normal Map", 2D) = "bump" {}
        [NormalScale]_NormalScale ("Normal Scale", Range(0,1)) = 1.0
        
        [RoughnessTexture]_RoughnessMap("Roughness Map", 2D) = "white" {}
        [RoughnessScale]_RoughnessScale ("Roughness Scale", Range(0,1)) = 1.0
        
        [MetallicTexture]_MetallicMap("Metallic Map", 2D) = "white" {}
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
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION

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
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // 材质关键字
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // GPU实例化
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            
            ENDHLSL
        }

    }
}
