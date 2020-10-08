Shader "Universal Render Pipeline/Custom/DepthSticker"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _Color ("Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent""RenderPipeline" = "UniversalRenderPipeline" }
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 pos: SV_POSITION;
                float4 localPos: TEXCOORD1;
                float3 viewPos: TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float4 _MainTex_ST;
            float3 _StickPos;
            CBUFFER_END
            #define smp _linear_clamp
            SAMPLER(smp);


            v2f vert(a2v v)
            {
                v2f o;
                float3 newpos = v.vertex.xyz;
                o.pos = TransformObjectToHClip(newpos);
                o.localPos = float4(newpos,1);
                o.viewPos = TransformWorldToView(TransformObjectToWorld(newpos));
                o.uv = TRANSFORM_TEX(o.localPos.xy, _MainTex);
                return o;
            }

            half4 frag(v2f i): SV_Target
            {
                //获取场景内物体的深度信息，将其作为贴花的uv。
                //由于深度值本身处于观察空间中，故需要将深度值从观察空间一步步转至物体空间中

                //通过深度图求出像素所在的观察空间中的Z轴
                //通过当前渲染的面片求出像素在观察空间下的坐标
                //通过以上两者求出深度值中得像素的XYZ坐标
                //在将此坐标转换到面片模型的本地空间，把XY当作UV来进行纹理采样
                float2 uv = i.pos.xy / _ScreenParams.xy;
                half4 depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
                half depth = LinearEyeDepth(depthMap.r, _ZBufferParams);

                //构建深度图上的像素在观察空间下的坐标
                float4 depthVS = 1;
                depthVS.xy = i.viewPos.xy * depth / - i.viewPos.z;
                depthVS.z = depth;
                //把像素从观察空间转到世界空间
                float4 depthWS = mul(unity_CameraToWorld,depthVS);
                //把像素从世界空间转到物体空间
                float4 depthOS = mul(unity_WorldToObject,depthWS);
                float2 uvdeclay = depthOS.xz+0.5;

                return SAMPLE_TEXTURE2D(_MainTex, smp, uvdeclay) * _Color;
            }
            ENDHLSL
        }

    }
}