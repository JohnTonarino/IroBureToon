#ifndef IBT_CORE_INCLUDED
#define IBT_CORE_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "VRCLightVolumes/LightVolumes.cginc"
#include "OpenLit/OpenLit.cginc"

sampler2D _MainTex;
float4 _MainTex_ST;
fixed4 _Color;

float _IBTPreset;
fixed4 _CustomAColor;
fixed4 _CustomBColor;
fixed4 _CustomKeyColor;
float4 _PlateAOffset;
float4 _PlateBOffset;
float4 _KeyPlateOffset;
half _ShiftScale;
half _EffectStrength;
half _Saturation;

sampler2D _BumpMap;
half _BumpScale;

sampler2D _ShadowTex;
fixed4 _ShadowColor1;
fixed4 _ShadowColor2;
half _ShadowStep1;
half _ShadowStep2;
half _ShadowSmoothness;
half _ShadowStrength;
float _UseSDF;
sampler2D _SDFMaskTex;

sampler2D _MatCap;
sampler2D _MatCapMask;
half _MatCapStrength;
half _MatCapBlend;

fixed4 _SpecularColor;
half _SpecularStrength;
half _SpecularSize;
half _SpecularSmoothness;

fixed4 _RimColor;
sampler2D _RimMask;
half _RimStrength;
half _RimPower;
half _RimSmoothness;

sampler2D _EmissionMap;
fixed4 _EmissionColor;

fixed4 _OutlineColor;
float _OutlineWidth;
sampler2D _OutlineMask;
float4 _OutlineMask_ST;
half _OutlineLighting;

// OpenLit
half _AsUnlit;
half _LightMinLimit;
half _LightMaxLimit;
half _MonochromeLighting;
float4 _LightDirectionOverride;
float _ReceiveShadow;
float _BeforeExposureLimit;
float _AlphaBoostFA;
//---

// VRCLightVolumes
float _VRCLightVolumesOn;
half _VRCLightVolumesStrength;
//---


struct IBT_AppData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct IBT_V2F
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    half3 normalWS : TEXCOORD2;
    half3 tangentWS : TEXCOORD3;
    half3 bitangentWS : TEXCOORD4;
    float4 screenPos : TEXCOORD5;
    nointerpolation uint3 lightDatas : TEXCOORD6;
    UNITY_FOG_COORDS(7)
    UNITY_LIGHTING_COORDS(8, 9)
    UNITY_VERTEX_OUTPUT_STEREO
};

IBT_V2F IBT_Vert(IBT_AppData v)
{
    IBT_V2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(IBT_V2F, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.positionWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.normalWS = UnityObjectToWorldNormal(v.normal);
    o.tangentWS = UnityObjectToWorldDir(v.tangent.xyz);
    o.bitangentWS = cross(o.normalWS, o.tangentWS) * (v.tangent.w * unity_WorldTransformParams.w);
    o.screenPos = ComputeScreenPos(o.pos);

    OpenLitLightDatas lightDatas;
    ComputeLights(lightDatas, _LightDirectionOverride);
    CorrectLights(lightDatas, _LightMinLimit, _LightMaxLimit, _MonochromeLighting, _AsUnlit);
    PackLightDatas(o.lightDatas, lightDatas);

    UNITY_TRANSFER_FOG(o, o.pos);
    UNITY_TRANSFER_LIGHTING(o, v.uv);
    return o;
}

inline half3 IBT_NormalWS(IBT_V2F i)
{
    half3 normalTS = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
    return normalize(
        normalize(i.tangentWS) * normalTS.x +
        normalize(i.bitangentWS) * normalTS.y +
        normalize(i.normalWS) * normalTS.z
    );
}

inline half IBT_Luminance(half3 color)
{
    return dot(color, half3(0.299h, 0.587h, 0.114h));
}

#endif
