Shader "Universal Render Pipeline/Custom/Layout"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _Color ("Color", Color) = (1, 1, 1, 1)

        [Header(Emissive)]
        _EmissTex ("Emissive Tex", 2D) = "white" { }
        [HDR]_EmissColor ("Emissive Color", Color) = (0,0,0,0)

        _Shadow ("Shadow Strength", Range(0, 1)) = 0.5
        [IntRange]_Strength("Bend Strength",Range(0,30)) = 3
        _Power("Bend Power",Range(0,1)) = 3

        // [Toggle]_Outlineable("Outline able",int) = 0
        // _OutlineColor("Outline Color", Color) = (0,0,0,1)
        // _Outline("Outline width", Float) = .005
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float easeInOutCubic(float x)
            {
                return x * x;
            }

            struct a2v
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 pos: SV_POSITION;
                float3 worldPos: TEXCOORD1;
                float3 localPos: TEXCOORD2;
                float3 worldNormal: TEXCOORD3;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_EmissTex);
            SAMPLER(sampler_EmissTex);

            

            CBUFFER_START(UnityPerMaterial)
            half4 _Color,_EmissColor;
            float3 _KnifePos, _PastPos;
            float4 _MainTex_ST;
            real _Shadow,_Strength,_Power;
            CBUFFER_END


            v2f vert(a2v v)
            {
                v2f o;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                float3 dir = _PastPos - _KnifePos ;
                o.localPos = v.vertex.xyz;
                o.localPos.x += clamp(dir * (easeInOutCubic(o.localPos.x * _Power*4)),0,0.04);
                o.localPos.y -= clamp(dir * (easeInOutCubic(o.localPos.y * _Power*5)),0,0.02);
                o.localPos.z += clamp(dir * (easeInOutCubic(o.localPos.z * _Power*5)),0,0.04);
                o.pos = TransformObjectToHClip(o.localPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag(v2f i): SV_Target
            {
                //Lambert光照模型
                Light mylight = GetMainLight();
                real4 LightColor = real4(mylight.color, 1);
                float3 LightDir = normalize(mylight.direction);
                float LightAtten = min(1, max(0, dot(LightDir, normalize(i.worldNormal))) + _Shadow);

                half4 emisstex = SAMPLE_TEXTURE2D(_EmissTex, sampler_EmissTex, i.uv)*_EmissColor;

                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;
                col *= LightAtten * LightColor;
                return col+emisstex;
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

        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        //     struct a2v
        //     {
        //         float4 positionOS: POSITION;
        //         float4 normalOS: NORMAL;

        //     };
        //     struct v2f
        //     {
        //         float4 positionCS: SV_POSITION;
        //     };

        //     half4 _OutlineColor;
        //     half _Outline,_Outlineable;

        //     v2f VERT(a2v v)
        //     {
        //         v2f o = (v2f)0;

        //         v.positionOS.xyz += normalize( v.normalOS.rgb) * _Outline*_Outlineable;
        //         o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
        //         return o;
        //     }

        //     half4 FRAG(v2f i): SV_TARGET
        //     {
        //         return _OutlineColor;
        //     }
        //     ENDHLSL
            
        // }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}