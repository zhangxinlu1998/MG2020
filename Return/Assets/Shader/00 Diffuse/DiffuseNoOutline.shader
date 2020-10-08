Shader "URP/DiffuseNoOutline"
{
    Properties
    {
        [Header(Diffuse)]
        _MainTex ("MainTex", 2D) = "white" { }
        _Color ("BaseColor", Color) = (0,0,0,0)
        [Toggle]_Clip("Clip",int) = 0
        
        _ShadowCol ("Shadow Color", Color) = (0,0,0,0)
        _ShadowRange("Shadow Range",Range(0,1)) = 0.5
        _Shadow("Shadow Strength",Range(0,1)) = 0.5

        [Header(Emissive)]
        _EmissTex ("Emissive Tex", 2D) = "white" { }
        [HDR]_EmissColor ("Emissive Color", Color) = (0,0,0,0)


        
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }
        cull Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_EmissTex);
        SAMPLER(sampler_EmissTex);

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _Color,_ShadowCol,_EmissColor;
        real _ShadowRange,_Shadow,_Clip;
        CBUFFER_END

        
        
        ENDHLSL
        
        pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            
            #pragma vertex VERT
            #pragma fragment FRAG

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            struct a2v
            {
                float4 positionOS: POSITION;
                float4 normalOS: NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord: TEXCOORD;
                float4 color:COLOR;
            };
            struct v2f
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD;
                float3 positionWS: TEXCOORD1;
                float3 positionOS: TEXCOORD2;
                float3 normalWS: NORMAL;
                float4 color:COLOR;
            };

            v2f VERT(a2v v)
            {
                v2f o = (v2f)0;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionOS = v.positionOS.xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);

                return o;
            }
            half4 FRAG(v2f i): SV_TARGET
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) ;
                half4 emisstex = SAMPLE_TEXTURE2D(_EmissTex, sampler_EmissTex, i.uv)*_EmissColor;
                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                float3 WS_L = normalize(mylight.direction);
                float3 WS_N = normalize(i.normalWS);
                float4 shadow = (1 - mylight.shadowAttenuation) * _ShadowCol + mylight.shadowAttenuation;
                float LightAtten = saturate(saturate(dot(WS_L, WS_N)+_ShadowRange)+_Shadow);
                float4 col =tex* LightAtten * shadow * real4(mylight.color, 1);

                
                float4 finalcol =emisstex+col* _Color+_ShadowCol*(1-step(0.5,LightAtten));
                clip(tex.a-0.9*_Clip);

                return float4(finalcol.rgb,tex.a*_Color.a) ;
            }
            ENDHLSL
            
        }


        Pass
        {
            Tags{ "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment


            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}