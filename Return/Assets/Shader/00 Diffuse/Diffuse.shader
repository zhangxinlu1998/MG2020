Shader "URP/Diffuse"
{
    Properties
    {
        [Header(Diffuse)]
        _MainTex ("MainTex", 2D) = "white" { }
        _Color ("BaseColor", Color) = (0,0,0,0)
        
        _ShadowCol ("Shadow Color", Color) = (0,0,0,0)
        _ShadowRange("Shadow Range",Range(0,1)) = 0.5
        _Shadow("Shadow Strength",Range(0,1)) = 0.5

        [Header(Emissive)]
        _EmissTex ("Emissive Tex", 2D) = "white" { }
        [HDR]_EmissColor ("Emissive Color", Color) = (0,0,0,0)

        [Header(Disslove)]
        [Toggle]_Disslove("Disslove able",int) = 0
        _MaskTex ("MaskTex", 2D) = "white" { }
        _Scale("MaskTex Scale",Range(0,20)) = 5
        _Edge("Edge width", Range(0,0.5)) = .005
        [HDR]_EdgeColor ("Edge Color", Color) = (0,0,0,0)
        
        [Toggle]_Outlineable("Outline able",int) = 0
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _Outline("Outline width", Float) = .005
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_EmissTex);
        SAMPLER(sampler_EmissTex);

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _Color,_ShadowCol,_OutlineColor,_EmissColor,_EdgeColor;
        real _ShadowRange,_Shadow, _Outline,_Outlineable,_Scale,_Edge,_Disslove;
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
                o.color = v.color;

                return o;
            }
            half4 FRAG(v2f i): SV_TARGET
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;
                float noise = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, _Scale*float2(i.uv.x,_Time.y/10+i.uv.y)).r;
                half mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, lerp(_Scale*i.uv,noise,0.5)).r*saturate(1-i.color.r)*2 *_Disslove;
                float4 edge= step(0.5-_Edge,mask);
                mask = step(0.5,mask);
                half4 emisstex = SAMPLE_TEXTURE2D(_EmissTex, sampler_EmissTex, i.uv)*_EmissColor;
                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                float3 WS_L = normalize(mylight.direction);
                float3 WS_N = normalize(i.normalWS);
                float4 shadow = (1 - mylight.shadowAttenuation) * _ShadowCol + mylight.shadowAttenuation;
                float LightAtten = saturate(saturate(dot(WS_L, WS_N)+_ShadowRange)+_Shadow);
                tex *= LightAtten * shadow * real4(mylight.color, 1);
                //clip(mask-0.1);
                
                float4 finalcol =edge*_EdgeColor+emisstex+tex*(1-edge.r)+_ShadowCol*(1-LightAtten);

                return float4(finalcol.rgb,1-mask.r) ;
            }
            ENDHLSL
            
        }

        // pass
        // {
        //     Tags { "LightMode" = "SRPDefaultUnlit" }
        //     cull Front
        //     HLSLPROGRAM
            
        //     #pragma vertex VERT
        //     #pragma fragment FRAG

        //     struct a2v
        //     {
        //         float4 positionOS: POSITION;
        //         float4 normalOS: NORMAL;
        //         float4 tangent : TANGENT;
        //         float4 color:COLOR0;
        //     };
        //     struct v2f
        //     {
        //         float4 positionCS: SV_POSITION;
        //         float4 color:TEXCOORD2;
        //     };

        //     v2f VERT(a2v v)
        //     {
        //         v2f o = (v2f)0;


        //         v.positionOS.xyz += normalize( v.color.rgb) * _Outline*_Outlineable;
        //         o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
        //         return o;
        //     }

        //     half4 FRAG(v2f i): SV_TARGET
        //     {
        //         return _OutlineColor;
        //     }
        //     ENDHLSL
            
        // }

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