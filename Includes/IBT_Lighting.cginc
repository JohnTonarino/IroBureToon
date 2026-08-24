#ifndef IBT_LIGHTING_INCLUDED
#define IBT_LIGHTING_INCLUDED

#include "IBT_Core.cginc"

inline float2 TriplanarUV3D(IBT_V2F i, float scale) {
    float3 localPos = mul(unity_WorldToObject, float4(i.positionWS, 1.0)).xyz;
    float3 localNormal = UnityWorldToObjectDir(i.normalWS);
    float3 n = abs(normalize(localNormal));

    if (n.z >= n.x && n.z >= n.y) { return localPos.xy * scale; }
    else if (n.x >= n.y) { return float2(localPos.z, localPos.y) * scale; }
    else { return float2(localPos.x, localPos.z) * scale; }
}

inline half3 IBT_LimitLight(half3 lightColor)
{
    half luminance = IBT_Luminance(lightColor);
    lightColor = lerp(lightColor, luminance.xxx, _MonochromeLighting);
    lightColor = min(lightColor, _LightMaxLimit.xxx);
    return max(lightColor, _LightMinLimit.xxx);
}

inline void IBT_UnpackOpenLitData(IBT_V2F i, out OpenLitLightDatas lightDatas)
{
    UnpackLightDatas(lightDatas, i.lightDatas);
}

inline half3 IBT_LightDirection(IBT_V2F i)
{
    OpenLitLightDatas lightDatas;
    IBT_UnpackOpenLitData(i, lightDatas);
    return lightDatas.lightDirection;
}

inline half IBT_SDFFaceLitFactor(float2 uv, half3 lightDirection)
{
    half3 objectRight = normalize(unity_ObjectToWorld._m00_m10_m20);
    half3 objectForward = normalize(unity_ObjectToWorld._m02_m12_m22);
    half rightDotLight = dot(objectRight.xz, lightDirection.xz);
    half forwardDotLight = dot(objectForward.xz, lightDirection.xz);

    half sdfRight = tex2D(_SDFMaskTex, float2(1.0 - uv.x, uv.y)).r;
    half sdfLeft = tex2D(_SDFMaskTex, uv).r;
    half sdfThreshold = rightDotLight < 0.0h ? sdfRight : sdfLeft;
    half directionalValue = forwardDotLight * 0.5h + 0.5h;

    return 1.0h - smoothstep(
        sdfThreshold - _ShadowSmoothness,
        sdfThreshold + _ShadowSmoothness,
        directionalValue
    );
}

inline half IBT_LitFactor(IBT_V2F i, half3 normalWS, half3 lightDirection)
{
    if (_UseSDF > 0.5h)
    {
        return IBT_SDFFaceLitFactor(i.uv, lightDirection);
    }

    half normalLight = dot(normalWS, lightDirection) * 0.5h + 0.5h;
    return normalLight;
}

inline half3 IBT_SDFFaceShadowTint(float2 uv, half litFactor)
{
    half3 shadowTexture = tex2D(_ShadowTex, uv).rgb;
    half3 faceShadow = shadowTexture * _ShadowColor1.rgb;
    half3 toonTint = lerp(faceShadow, half3(1, 1, 1), litFactor);

    return lerp(half3(1, 1, 1), toonTint, saturate(_ShadowStrength));
}

inline half3 IBT_ShadowTint(float2 uv, half lightLevel)
{
    half edge = max(_ShadowSmoothness, 0.0001h);
    half leaveSecondShadow = smoothstep(_ShadowStep1 - edge, _ShadowStep1 + edge, lightLevel);
    half becomeLit = smoothstep(_ShadowStep2 - edge, _ShadowStep2 + edge, lightLevel);

    half3 shadowTexture = tex2D(_ShadowTex, uv).rgb;
    half3 secondShadow = shadowTexture * _ShadowColor2.rgb;
    half3 firstShadow = shadowTexture * _ShadowColor1.rgb;
    half3 toonTint = lerp(secondShadow, firstShadow, leaveSecondShadow);
    toonTint = lerp(toonTint, half3(1.0h, 1.0h, 1.0h), becomeLit);

    return lerp(half3(1.0h, 1.0h, 1.0h), toonTint, _ShadowStrength);
}

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

inline half3 IBT_Specular(half3 normalWS, half3 lightDirection, half3 viewDirection)
{
    half3 halfDirection = normalize(lightDirection + viewDirection);
    half normalHalf = saturate(dot(normalWS, halfDirection));
    half edge = max(_SpecularSmoothness, 0.0001h);
    half specular = smoothstep(_SpecularSize - edge, _SpecularSize + edge, normalHalf);
    return _SpecularColor.rgb * (specular * _SpecularStrength);
}

inline half3 IBT_Rim(half3 baseColor, float2 uv, half3 normalWS, half3 viewDirection)
{
    half rimBase = 1.0h - saturate(dot(normalWS, viewDirection));
    half rimShape = pow(max(rimBase, 0.0001h), max(_RimPower, 0.0001h));
    half rim = smoothstep(0.5h - _RimSmoothness, 0.5h + _RimSmoothness, rimShape);
    rim *= tex2D(_RimMask, uv).r * _RimStrength;
    return 1.0h - (1.0h - baseColor.rgb) * (1.0h - _RimColor * rim);
}

inline half3 IBT_LightVolumeLighting(IBT_V2F i, half3 normalWS)
{
    float3 lightL0;
    float3 lightL1R;
    float3 lightL1G;
    float3 lightL1B;

    LightVolumeSH(i.positionWS, lightL0, lightL1R, lightL1G, lightL1B);
    half3 volumeLight = LightVolumeEvaluate(normalize(normalWS), lightL0, lightL1R, lightL1G, lightL1B);

    return clamp(volumeLight, 0.0h, _LightMaxLimit);
}

inline half3 IBT_BaseLighting(
    IBT_V2F i,
    half3 albedo,
    half3 normalWS,
    half3 lightDirection,
    half attenuation)
{
    half lightLevel = IBT_LitFactor(i, normalWS, lightDirection);
    half3 shadowTint = _UseSDF > 0.5h
        ? IBT_SDFFaceShadowTint(i.uv, lightLevel)
        : IBT_ShadowTint(i.uv, lightLevel);

    float2 toneUV = TriplanarUV3D(i, _ShadowToneScale);
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
        half3 volumeLight = IBT_LightVolumeLighting(i, normalWS);
        half volumeBlend = _VRCLightVolumesStrength * LightVolumesEnabled();
        lightColor = lerp(openLitLight, volumeLight, volumeBlend);
    }
    lightColor = lerp(lightColor, half3(1.0h, 1.0h, 1.0h), _AsUnlit);
    return albedo * shadowTint * lightColor;
}

#endif
