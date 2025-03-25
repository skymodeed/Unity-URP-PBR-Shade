Shader "LearnShader/Skin"{
    Properties{
        [Header(Surface Options)]
        [MainColor] _ColorTint("Tint", Color) = (1, 1, 1, 1)
        [MainTexture] _ColorMap("Color Map", 2D) = "white" {}
        [Gloss]_GlossScale("Gloss Scale", Float) = 1
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Scale", Range(0,1)) = 1.0
    }
    SubShader{
        Tags{"RenderPipeline"="UniverPipeline"}

        Pass{
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "Skin.hlsl"
            ENDHLSL
        }
    }
}
