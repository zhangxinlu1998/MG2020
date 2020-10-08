//https://80.lv/articles/stylized-nature-vegetation-animation-shaders/

Shader "MRShader/Tree"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)

        [Header(Shadow)]
        _ShadowCol ("Shadow Color", Color) = (0,0,0,0)
        _ShadowRange("Shadow Range",Range(0,1)) = 0.5
        _Shadow("Shadow Strength",Range(0,1)) = 0.5

        [Header(Wave)]
        _Speed("Speed",range(0,5)) = 1
        _Strength("Strength",range(0,1)) = 1

        [Header(Leaf Wave)]
        [Toggle]_Leafwave("Leaf Wave",int) = 0
        _LeafStrength("Leaf Strength",Range(0,5)) = 1
        _LeafWaveRate("Leaf Wave Rate",Range(0,5)) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }
        Cull Back
        

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color:COLOR;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 color:COLOR;
                float3 worldPos :TEXCOORD1;
                float3 normalWS:NORMAL;
            };


            float2 hash22(float2 p) {
                p = float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3)));
                return -1.0 + 2.0*frac(sin(p)*43758.5453123);
            }


            float noise(float2 p) {				
                float2 pi = floor(p);
                float2 pf = p - pi;
                float2 w = pf * pf*(3.0 - 2.0*pf);
                return lerp(lerp(dot(hash22(pi + float2(0.0, 0.0)), pf - float2(0.0, 0.0)),
                dot(hash22(pi + float2(1.0, 0.0)), pf - float2(1.0, 0.0)), w.x),
                lerp(dot(hash22(pi + float2(0.0, 1.0)), pf - float2(0.0, 1.0)),
                dot(hash22(pi + float2(1.0, 1.0)), pf - float2(1.0, 1.0)), w.x), w.y);
            }

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color,_ShadowCol;
            half _Speed,_Strength,_Leafwave,_LeafStrength,_Shadow,_ShadowRange,_Smooth,_LeafWaveRate;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                v.vertex.xyz += sin((v.vertex.z+_Time.y)*_Speed)*o.color.r*_Strength*noise(o.worldPos.xz+_Time.y);
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normal);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                i.uv.x += (i.uv.y*(sin(i.uv.y+_Time.y*5)*_LeafStrength)-0.05)*noise((i.worldPos.yz)/_LeafWaveRate+_Time.y)*_LeafStrength*_Leafwave;
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;;
                clip(col.a-0.5);
                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.worldPos));
                float3 L = normalize(mylight.direction);
                float3 N = normalize(i.normalWS);

                float4 shadow = (1 - mylight.shadowAttenuation) * _ShadowCol + mylight.shadowAttenuation;
                float LightAtten = saturate(saturate(dot(L, N)+_ShadowRange)+_Shadow);
                col *= LightAtten * shadow * real4(mylight.color, 1);
                
                float4 finalcol =col+_ShadowCol*(1-LightAtten);

                return float4(finalcol.rgb,1) ;
                
                // float diffuse = smoothstep(0,_Smooth,saturate(saturate(dot(N,L)+_ShadowRange*2-1)+_Shadow));
                // return float4(col.rgb*diffuse+(1-diffuse)*_ShadowCol.rgb,col.a);
            }
            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
