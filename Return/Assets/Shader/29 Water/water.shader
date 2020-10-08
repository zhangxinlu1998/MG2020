Shader "Universal Render Pipeline/Custom/UnlitBase"
{
    Properties
    {
        
        _Transform("Transform",Range(0,1)) = 0
        _TrSpeed("Transform Speed",Range(0,5)) = 0
        [NoScaleOffset]_IceTex ("Ice Tex", 2D) = "white" { }
        _IceScale("Ice Scale",Range(0,10)) = 0
        _IceColor ("Ice Color", Color) = (1, 1, 1, 1)

        [HDR]_ShallowColor ("Shallow Color", Color) = (1, 1, 1, 1)
        [HDR]_DeepColor ("Deep Color", Color) = (1, 1, 1, 1)
        _Deep ("Deep Control", Range(0, 10)) = 1
        [Header(Wave)]
        [Toggle]_Wave("Wave",int) = 1
        [NoScaleOffset]_MainTex ("Wave Tex", 2D) = "white" { }
        _Wavescale("Wave Scale",Range(0,10)) = 5
        _Wavecol("Wave Color", Color) = (1, 1, 1, 1)
        _waveSpeed ("Wave Speed", Range(0, 2)) = 0.3

        [NoScaleOffset]_DisTex ("Displacement Tex", 2D) = "white" { }
        _DisScale ("Displacement Scale", Range(0, 1)) = 0.5
        _Height ("Wave Height", Range(0, 1)) = 0.2
        _Speed ("Speed", Range(0, 2)) = 0.3

        [Header(Foam)]
        _FoamColor ("Foam Color", Color) = (1, 1, 1, 1)
        _FoamFade ("Foam Fade", Range(1, 5)) = 3
        [NoScaleOffset]_FoamTex ("Foam Noise Tex", 2D) = "white" { }
        _FoamScale ("Foam Scale", Range(0, 1)) = 0.5
        _FoamRange ("Foam Range", Range(0, 0.1)) = 0.01
        _FoamSpeed ("Foam Speed", Range(0, 1)) = 0.5

        [Header(Caustics)]
        [NoScaleOffset]_CauTex ("Caustics Tex", 2D) = "white" { }
        _CauColor ("Caustics Color", Color) = (1, 1, 1, 1)
        _CauScale ("Caustics Scale", Range(0, 1)) = 0.5
        _Caustics ("Caustics Strength", Range(0, 1)) = 0.4

        [Header(Distort)]
        [NoScaleOffset]_DistortTex ("Distort Tex", 2D) = "white" { }
        _Distort ("Distort Strength", Range(0, 0.1)) = 0.025
        _DistortScale ("Distort Scale", Range(0, 1)) = 0.5
        _DistortSpeed ("Distort Speed", Range(0, 1)) = 0.5

        // [Header(Specular)]
        // _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        // _SpecularRange("Specular Range",Range(0,200)) = 100
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #define REQUIRE_OPAQUE_TEXTURE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float4 uv: TEXCOORD0;
                float4 pos: SV_POSITION;
                float3 viewPos: TEXCOORD1;
                float3 worldNormal: TEXCOORD2;
                float3 viewDir: TEXCOORD3;
                float3 localPos: TEXCOORD4;
                float3 worldPos: TEXCOORD5;
                float3 sphere :TEXCOORD6;
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_IceTex);SAMPLER(sampler_IceTex);
            TEXTURE2D(_DisTex);SAMPLER(sampler_DisTex);
            TEXTURE2D(_CauTex);SAMPLER(sampler_CauTex);
            TEXTURE2D(_FoamTex);SAMPLER(sampler_FoamTex);
            TEXTURE2D(_DistortTex);SAMPLER(sampler_DistortTex);
            TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);

            CBUFFER_START(UnityPerMaterial)
            half4 _ShallowColor, _DeepColor, _FoamColor, _CauColor,_SpecularColor,_Wavecol,_IceColor;
            float4 _MainTex_ST;
            real _FoamFade, _foamRange, _FoamSpeed, _Distort, _FoamRange, _DistortSpeed,_Wavescale,_Wave,_TrSpeed,_IceScale;
            real _Deep, _FoamScale, _CauScale, _DistortScale, _Caustics, _Speed, _Height, _DisScale, _waveSpeed,_SpecularRange,_Transform;
            CBUFFER_END


            v2f vert(a2v v)
            {
                v2f o = (v2f)0;
                o.localPos = v.vertex.xyz;
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = TransformObjectToWorld(o.localPos);

                float3 center = unity_ObjectToWorld._14_24_34;
                float3 dissphere = distance(center,o.worldPos);
                o.sphere = smoothstep(0,0.05,1 - saturate(dissphere / ((_Transform + 0.8) * _TrSpeed)));

               
                float dis = SAMPLE_TEXTURE2D_LOD(_DisTex, sampler_DisTex, (o.worldPos.xz + _Time.y * _Speed) * _DisScale, 0).r;
                o.localPos.y += dis * _Height *(1-o.sphere);
                o.worldPos = TransformObjectToWorld(o.localPos);
                o.viewPos = TransformWorldToView(o.worldPos);
                o.pos = TransformWViewToHClip(o.viewPos);
                o.uv.zw = o.pos.xz;
                return o;
            }

            half4 frag(v2f i): SV_Target
            {
                //foam
                float2 uv = i.pos.xy / _ScreenParams.xy;
                half4 depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
                half depth = LinearEyeDepth(depthMap.r, _ZBufferParams);
                half foam = 1 - pow(saturate((depth - (-i.viewPos.z))), 1 / _FoamFade) * _FoamFade;
                float2 foamUV = i.worldPos.xz * _FoamScale;
                half foamnoisetex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, foamUV + _Time.y * _FoamSpeed).r;
                foam *= foamnoisetex;
                half foamnoise = step(_FoamRange, foam);
                half4 foamcol = saturate(foamnoise * _FoamColor) * step(1.4, i.localPos.y) ;

                //Distort
                half distorttex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, i.worldPos.xz + _Time.y * _DistortSpeed).r;
                half2 distortuv = lerp(uv, distorttex.rr, _Distort);
                float4 watercol = lerp(_ShallowColor, _DeepColor, 1 - smoothstep(0, _Deep, depth + i.viewPos.z));
                float4 trans = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, distortuv) * watercol.r;
                trans = trans * watercol + (1 - watercol.r) * watercol;

                //Caustics
                float4 depthVS = 1;
                depthVS.xy = i.viewPos.xy * depth / - i.viewPos.z;
                depthVS.z = depth;
                float4 depthWS = mul(unity_CameraToWorld, depthVS);
                float4 depthOS = mul(unity_WorldToObject, depthWS);
                float2 uvdeclay = depthOS.xz + 0.5;
                uvdeclay = lerp(uvdeclay, distorttex.rr, _Distort + 0.1);
                half distorttex2 = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, (uvdeclay + _Time.y * _DistortSpeed) * _DistortScale).r;
                real4 caucol1 = SAMPLE_TEXTURE2D(_CauTex, sampler_CauTex, uvdeclay * _CauScale + sin(_Time.y / 5) / 20) * _CauColor ;
                real4 caucol2 = SAMPLE_TEXTURE2D(_CauTex, sampler_CauTex, uvdeclay * _CauScale + sin(_Time.y / 5) / 15) * _CauColor ;
                real4 caucol = 200 * _Caustics * half4(caucol1.r, caucol2.g, caucol1.b, 1) * distorttex2 * watercol.r ;

                //wavetex
                half wavetex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, (i.worldPos.xz*_Wavescale - _Time.y * _waveSpeed) * 0.25).r * step(1.3, i.localPos.y);
                half waveonce = frac(i.localPos.z / 8 - _Time.y * _waveSpeed) - 0.6;
                half wave = step(0.4, wavetex + waveonce) * step(0.2, waveonce)*_Wave;
                half basewave = step(0.4,foamnoisetex*distorttex);



                float4 finalcol = trans + caucol + foamcol + (wave+basewave)*_Wavecol;
                float4 icecol = _IceColor*SAMPLE_TEXTURE2D(_IceTex, sampler_IceTex,i.uv*_IceScale);
                return finalcol*(1-i.sphere.r)+icecol*i.sphere.r;
            }
            ENDHLSL
            
        }
    }
}