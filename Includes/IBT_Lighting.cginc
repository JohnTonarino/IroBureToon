// Copyright (c) 2026 JohnTonarino
// Released under the MIT license
// IroBureToon v 1.0.0
#ifndef IBT_LIGHTING_INCLUDED
#define IBT_LIGHTING_INCLUDED

#include "IBT_Core.cginc"
#include "JTN_Lighting.cginc"

inline half3 IBT_MatCap(float3 baseColor, float2 uv, half3 normalWS)
{
    return JTN_MatCap(baseColor, uv, normalWS);
}

inline half3 IBT_Rim(half3 baseColor, float2 uv, half3 normalWS, half3 viewDirection)
{
    return JTN_Rim(baseColor, uv, normalWS, viewDirection);
}

inline half3 IBT_Specular(half3 normalWS, half3 lightDirection, half3 viewDirection)
{
    return JTN_Specular(normalWS, lightDirection, viewDirection);
}

inline half3 IBT_BaseLighting(
    IBT_V2F i,
    half3 albedo,
    half3 normalWS,
    half3 lightDirection,
    half attenuation)
{
    half lightLevel = JTN_LitFactor(i, normalWS, lightDirection);
    half3 shadowTint = _UseSDF > 0.5h
        ? JTN_SDFFaceShadowTint(i.uv, lightLevel)
        : JTN_ShadowTint(i.uv, lightLevel);

    float2 toneUV = JTN_TriplanarUV3D(i.positionWS, i.normalWS, _ShadowToneScale);
    half tone = tex2D(_ShadowToneTex, toneUV).r;
    shadowTint = 1.0h - tone * (1.0-shadowTint);

    OpenLitLightDatas lightDatas;
    JTN_UnpackOpenLitData(i, lightDatas);
    half3 ambient = lightDatas.indirectLight;
    half3 direct = lightDatas.directLight;
    half receiveAttenuation = lerp(1.0h, attenuation, saturate(_ReceiveShadow));
    direct *= receiveAttenuation;

    half bandMultiplier = lerp(1.0h, lightLevel, _ShadowStrength);
    half3 openLitLight = lerp(ambient, direct, bandMultiplier);
    half3 lightColor = openLitLight;
    if (_VRCLightVolumesOn > 0.5h)
    {
        half3 volumeLight = JTN_LightVolumeLighting(i, normalWS);
        half volumeBlend = _VRCLightVolumesStrength * LightVolumesEnabled();
        lightColor = lerp(openLitLight, volumeLight, volumeBlend);
    }
    lightColor = lerp(lightColor, half3(1.0h, 1.0h, 1.0h), _AsUnlit);
    return albedo * shadowTint * lightColor;
}

#endif
