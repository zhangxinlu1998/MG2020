Shader "URP/Transparent"
{
    Properties
    {
        [Header(Diffuse)]
        _MainTex ("MainTex", 2D) = "white" { }
        [HDR]_Color ("BaseColor", Color) = (0,0,0,0)
        
        _Speed("Scroll Speed",Range(0,1)) = 0.5
        _SCale("Scroll _SCale",Range(0,5)) = 0.5



        
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Transparent" }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _Color;
        real _Speed,_SCale;
        CBUFFER_END

        
        
        ENDHLSL
        
        pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            
            #pragma vertex VERT
            #pragma fragment FRAG


            struct a2v
            {
                float4 positionOS: POSITION;
                float2 uv:TEXCOORD0;
            };
            struct v2f
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD;
                float3 worldPos:TEXCOORD1;
            };

            v2f VERT(a2v v)
            {
                v2f o = (v2f)0;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);           
                o.uv = v.uv;
                o.worldPos = TransformObjectToWorld(v.positionOS.xyz);  
                return o;
            }
            half4 FRAG(v2f i): SV_TARGET
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.worldPos.x+_Time.y*_Speed,i.worldPos.y)/_SCale) *_Color;
                

                return  tex ;
            }
            ENDHLSL
            
        }


        // Pass
        // {
        //     Tags{ "LightMode" = "DepthOnly" }

        //     ZWrite On
        //     ColorMask 0

        //     HLSLPROGRAM

        //     #pragma prefer_hlslcc gles
        //     #pragma exclude_renderers d3d11_9x
        //     #pragma target 2.0

        //     #pragma vertex DepthOnlyVertex
        //     #pragma fragment DepthOnlyFragment


        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
        //     ENDHLSL
        // }
        // UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}