Shader "IroBureToon/Cutout"
{
    Properties
    {
        [Header(Main)]
        [Space(10)]
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _TransparentMask ("Transparent Mask", 2D) = "white" {}
        _TransparentLevel ("Cutout Threshold", Range(0, 1)) = 0

        [Header(Normal Map)]
        [Space(10)]
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Range(0, 2)) = 1

        [Header(Toon Shadow)]
        [Space(10)]
        _ShadowTex ("Shadow Texture", 2D) = "white" {}
        _ShadowColor1 ("First Shadow Color", Color) = (0.72, 0.76, 0.90, 1)
        _ShadowColor2 ("Second Shadow Color", Color) = (0.48, 0.52, 0.70, 1)
        _ShadowStep1 ("Second Shadow Border", Range(0, 1)) = 0.35
        _ShadowStep2 ("Lit Border", Range(0, 1)) = 0.5
        _ShadowSmoothness ("Shadow Smoothness", Range(0.001, 0.25)) = 0.03
        _ShadowStrength ("Shadow Strength", Range(0, 1)) = 0.65
        _ShadowToneTex ("Shadow Tone Texture", 2D) = "white" {}
        _ShadowToneScale ("Shadow Tone Scale", Float) = 1.0
        [Toggle] _UseSDF ("Use SDF Face Shadow", Float) = 0
        _SDFMaskTex ("SDF Face Mask", 2D) = "white" {}

        [Header(MatCap)]
        [Space(10)]
        _MatCap ("MatCap", 2D) = "white" {}
        _MatCapMask ("MatCap Mask", 2D) = "white" {}
        _MatCapStrength ("MatCap Strength", Range(0, 1)) = 0
        [Enum(Lerp,0,Multiply,1)] _MatCapBlend ("MatCap Blend", Float) = 0

        [Header(Specular)]
        [Space(10)]
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularStrength ("Specular Strength", Range(0, 1)) = 0
        _SpecularSize ("Specular Size", Range(0, 1)) = 0.8
        _SpecularSmoothness ("Specular Smoothness", Range(0.001, 0.25)) = 0.02

        [Header(Rim Light)]
        [Space(10)]
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimMask ("Rim Mask", 2D) = "white" {}
        _RimStrength ("Rim Strength", Range(0, 1)) = 0.25
        _RimPower ("Rim Power", Range(0.25, 8)) = 2
        _RimSmoothness ("Rim Smoothness", Range(0.001, 0.49)) = 0.08

        [Header(Emission)]
        [Space(10)]
        _EmissionMap ("Emission Map", 2D) = "black" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0, 0, 0, 1)

        [Header(VRC Light Volumes)]
        [Space(10)]
        [Toggle] _VRCLightVolumesOn ("VRChat Light Volumes", Float) = 0
        _VRCLightVolumesStrength ("Light Volumes Strength", Range(0, 1)) = 1

        [Header(IroBre)]
        [Space(10)]
        [Enum(Custom,0,PinkBlue,1,RedBlue,2,RedCyan,3,Vintage,4)]
        _IBTPreset ("Ink Preset", Float) = 0
        _CustomAColor ("Custom A Color", Color) = (1, 0.08, 0.25, 1)
        _CustomBColor ("Custom B Color", Color) = (0, 0.55, 1, 1)
        _CustomKeyColor ("Custom Key Color", Color) = (0.04, 0.04, 0.06, 1)
        _PlateAOffset ("Plate A Offset", Vector) = (0.004, 0.002, 0, 0)
        _PlateBOffset ("Plate B Offset", Vector) = (-0.004, -0.002, 0, 0)
        _KeyPlateOffset ("Key Plate Offset", Vector) = (0, 0, 0, 0)
        _ShiftScale ("Shift Scale", Range(0, 4)) = 1
        _EffectStrength ("Effect Strength", Range(0, 1)) = 0.3
        _FringeCutoff ("Fringe Cutoff", Range(0, 0.2)) = 0.03
        _Saturation ("Saturation", Range(0, 2)) = 1

        [Header(Outline)]
        [Space(10)]
        _OutlineColor ("Outline Color", Color) = (0.04, 0.04, 0.06, 1)
        _OutlineWidth ("Outline Width", Range(0, 0.02)) = 0
        _OutlineMask ("Outline Mask", 2D) = "white" {}
        _OutlineLighting ("Outline Lighting", Range(0, 1)) = 0.25

        [Header(Lighting Control)]
        [Space(10)]
        _AsUnlit ("As Unlit", Range(0, 1)) = 0
        _LightMinLimit ("Light Min Limit", Range(0, 1)) = 0.05
        _LightMaxLimit ("Light Max Limit", Range(0, 10)) = 0.8
        _MonochromeLighting ("Monochrome Lighting", Range(0, 1)) = 0
        _LightDirectionOverride ("Light Direction Override", Vector) = (0, 0, 0, 0)
        [Toggle] _ReceiveShadow ("Receive Realtime Shadow", Float) = 0
        _BeforeExposureLimit ("Before Exposure Limit", Float) = 10000
        _AlphaBoostFA ("ForwardAdd Alpha Boost", Range(1, 100)) = 10
    }

    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        LOD 200

        CGINCLUDE
        #pragma target 3.0
        #include "../Includes/IBT_Core.cginc"
        #include "../Includes/IBT_Lighting.cginc"
        #include "../Includes/IBT_Effect.cginc"
        sampler2D _TransparentMask;
        half _TransparentLevel;
        inline half IBT_Alpha(float2 uv)
        {
            return tex2D(_MainTex, uv).a * _Color.a * dot(tex2D(_TransparentMask, uv).rgb, half3(0.299h, 0.587h, 0.114h));
        }
        ENDCG

        Pass
        {
            Name "FORWARD_BASE"
            Tags { "LightMode"="ForwardBase" }
            Cull Back
            ZWrite On
            ZTest LEqual
            BlendOp Add, Add
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex IBT_Vert
            #pragma fragment fragBase
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK DIRLIGHTMAP_COMBINED

            fixed4 fragBase(IBT_V2F i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_LIGHT_ATTENUATION(attenuation, i, i.positionWS);

                fixed4 mainSample = tex2D(_MainTex, i.uv) * _Color;
                half alpha = IBT_Alpha(i.uv);
                clip(alpha - _TransparentLevel);

                half3 normalWS = IBT_NormalWS(i);
                half3 viewDirection = normalize(UnityWorldSpaceViewDir(i.positionWS));
                half3 lightDirection = IBT_LightDirection(i);

                half3 matCapAlbedo = IBT_MatCap(mainSample.rgb, i.uv, normalWS);
                half3 irozureAlbedo = ApplyIrozure(i, matCapAlbedo.rgb, mainSample.rgb);
                irozureAlbedo = IBT_Rim(irozureAlbedo, i.uv, normalWS, viewDirection);

                half3 color = IBT_BaseLighting(
                    i,
                    irozureAlbedo,
                     normalWS,
                    lightDirection,
                    attenuation
                );

                OpenLitLightDatas lightDatas;
                IBT_UnpackOpenLitData(i, lightDatas);
                color += IBT_Specular(normalWS, lightDirection, viewDirection) * lightDatas.directLight * attenuation;
                color += tex2D(_EmissionMap, i.uv).rgb * _EmissionColor.rgb;

                fixed4 result = fixed4(saturate(color), alpha);
                UNITY_APPLY_FOG(i.fogCoord, result);
                return result;
            }
            ENDCG
        }

        Pass
        {
            Name "FORWARD_ADD"
            Tags { "LightMode"="ForwardAdd" }
            Cull Back
            ZWrite Off
            ZTest LEqual
            BlendOp Max, Add
            Blend One One, Zero One
            Fog { Color (0, 0, 0, 0) }

            CGPROGRAM
            #pragma vertex IBT_Vert
            #pragma fragment fragAdd
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            fixed4 fragAdd(IBT_V2F i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_LIGHT_ATTENUATION(attenuation, i, i.positionWS);

                half alpha = IBT_Alpha(i.uv);
                clip(alpha - _TransparentLevel);

                fixed3 baseAlbedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                half3 irozureAlbedo = ApplyIrozure(i, baseAlbedo, baseAlbedo);

                half3 normalWS = IBT_NormalWS(i);
                half3 viewDirection = normalize(UnityWorldSpaceViewDir(i.positionWS));

                OpenLitLightDatas lightDatas;
                IBT_UnpackOpenLitData(i, lightDatas);
                half3 lightDirection = normalize(UnityWorldSpaceLightDir(i.positionWS));

                half lightLevel = IBT_LitFactor(i, normalWS, lightDirection);
                half edge = max(_ShadowSmoothness, 0.0001h);
                half toonLight = _UseSDF > 0.5h?
                    lightLevel
                    : smoothstep(
                        _ShadowStep2 - edge,
                        _ShadowStep2 + edge,
                        lightLevel
                    );
                toonLight = lerp(1.0h, toonLight, _ShadowStrength);

                half3 addLight = OPENLIT_LIGHT_COLOR * attenuation;
                half3 contribution = irozureAlbedo * addLight * toonLight;
                contribution += IBT_Specular(normalWS, lightDirection, viewDirection) * addLight;
                fixed4 result = fixed4(contribution, 0);

                UNITY_APPLY_FOG_COLOR(i.fogCoord, result, fixed4(0, 0, 0, 0));
                return result;
            }
            ENDCG
        }

        Pass
        {
            Name "OUTLINE"
            Tags { "LightMode"="ForwardBase" }
            Cull Front
            ZWrite On
            ZTest LEqual

            CGPROGRAM
            #pragma vertex IBT_OutlineCutoutVert
            #pragma fragment IBT_OutlineCutoutFrag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #include "../Includes/IBT_Outline.cginc"

            struct IBT_OutlineCutoutV2F
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            IBT_OutlineCutoutV2F IBT_OutlineCutoutVert(IBT_AppData v)
            {
                IBT_OutlineV2F baseOutput = IBT_OutlineVert(v);
                IBT_OutlineCutoutV2F o;
                UNITY_INITIALIZE_OUTPUT(IBT_OutlineCutoutV2F, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = baseOutput.pos;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }
            fixed4 IBT_OutlineCutoutFrag(IBT_OutlineCutoutV2F i) : SV_Target
            {
                clip(IBT_Alpha(i.uv) - _TransparentLevel);
                fixed4 color = _OutlineColor;
                half3 ambient = IBT_LimitLight(ShadeSH9(half4(0, 1, 0, 1)));
                color.rgb *= lerp(half3(1, 1, 1), ambient, _OutlineLighting);
                UNITY_APPLY_FOG(i.fogCoord, color);
                return color;
            }
            ENDCG
        }

        Pass
        {
            Name "SHADOWCASTER"
            Tags { "LightMode"="ShadowCaster" }
            Cull Back
            ZWrite On
            ZTest LEqual

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vertShadow
            #pragma fragment fragShadow
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct ShadowV2F
            {
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD1;
            };

            ShadowV2F vertShadow(appdata_base v)
            {
                ShadowV2F o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
                return o;
            }
            float4 fragShadow(ShadowV2F i) : SV_Target
            {
                clip(IBT_Alpha(i.uv) - _TransparentLevel);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    FallBack "Transparent/Cutout/Diffuse"
}
