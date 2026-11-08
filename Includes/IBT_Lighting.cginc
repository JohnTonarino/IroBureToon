// Copyright (c) 2026 JohnTonarino
// Released under the MIT license
// IroBureToon v 1.0.0
#ifndef IBT_LIGHTING_INCLUDED
#define IBT_LIGHTING_INCLUDED

#include "IBT_Core.cginc"
#include "JTN_Lighting.cginc"

inline half3 IBT_MatCap(float3 baseColor, float2 uv, half3 normalWS)
{
    half3 normalVS = mul((half3x3)UNITY_MATRIX_V, normalWS);
    float2 matCapUV = normalVS.xy * 0.5 + 0.5;
    half3 matCap = tex2D(_MatCap, matCapUV).rgb;
    half mask = tex2D(_MatCapMask, uv).r * _MatCapStrength;

    if (_MatCapBlend > 0.5h)
    {
        return baseColor * (half3(1.0h, 1.0h, 1.0h) + matCap * mask);
    }
    else
    {
        // Lerp: black is transparent, MatCap RGB is the visible color
        half matCapLevel = max(matCap.r, max(matCap.g, matCap.b));
        half amount = (matCapLevel * mask);
        return baseColor * (1.0h - amount) + matCap * mask;
    }
}

inline half3 IBT_Rim(half3 baseColor, float2 uv, half3 normalWS, half3 viewDirection)
{
    half rimBase = 1.0h - saturate(dot(normalWS, viewDirection));
    half rimShape = pow(max(rimBase, 0.0001h), max(_RimPower, 0.0001h));
    half rim = smoothstep(0.5h - _RimSmoothness, 0.5h + _RimSmoothness, rimShape);
    rim *= tex2D(_RimMask, uv).r * _RimStrength;
    return 1.0h - (1.0h - baseColor.rgb) * (1.0h - _RimColor.rgb * rim);
}

inline half3 IBT_Specular(half3 normalWS, half3 lightDirection, half3 viewDirection)
{
    half3 halfDirection = normalize(lightDirection + viewDirection);
    half normalHalf = saturate(dot(normalWS, halfDirection));
    half edge = max(_SpecularSmoothness, 0.0001h);
    half specular = smoothstep(_SpecularSize - edge, _SpecularSize + edge, normalHalf);
    return _SpecularColor.rgb * (specular * _SpecularStrength);
}

inline half3 IBT_BaseLighting(
    IBT_V2F i,
    half3 albedo,
    half3 normalWS,
    half3 lightDirection,
    half attenuation)
{
    half lightLevel = JTN_LitFactor(i.uv, normalWS, lightDirection);
    half3 shadowTint = _UseSDF != 0u?
        JTN_SDFFaceShadowTint(i.uv, lightLevel) :
        JTN_ShadowTint(i.uv, lightLevel);

    float2 toneUV = JTN_TriplanarUV3D(i.positionWS, i.normalWS, _ShadowToneScale);
    half tone = tex2D(_ShadowToneTex, toneUV).r;
    shadowTint = 1.0h - tone * (1.0-shadowTint);

    OpenLitLightDatas lightDatas;
    IBT_UnpackOpenLitData(i, lightDatas);
    half3 ambient = lightDatas.indirectLight;
    half3 direct = lightDatas.directLight;
    half receiveAttenuation = lerp(1.0h, attenuation, saturate(_ReceiveShadow));
    direct *= receiveAttenuation;

    half bandMultiplier = lerp(1.0h, lightLevel, _ShadowStrength);
    half3 openLitLight = lerp(ambient, direct, bandMultiplier);
    half3 lightColor = openLitLight;
    if (_VRCLightVolumesOn > 0.5h)
    {
        half3 volumeLight = JTN_LightVolumeLighting(i.positionWS, normalWS);
        half volumeBlend = _VRCLightVolumesStrength * LightVolumesEnabled();
        lightColor = lerp(openLitLight, volumeLight, volumeBlend);
    }
    lightColor = lerp(lightColor, half3(1.0h, 1.0h, 1.0h), _AsUnlit);
    return albedo * shadowTint * lightColor;
}

#endif
