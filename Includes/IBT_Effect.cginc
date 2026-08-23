#ifndef IBT_EFFECT_INCLUDED
#define IBT_EFFECT_INCLUDED

#include "IBT_Core.cginc"

inline half3 IBT_Saturation(half3 color, half saturation)
{
    half luminance = IBT_Luminance(color);
    return lerp(luminance.xxx, color, saturation);
}

inline void IrozurePreset(
    float preset,
    inout half3 plateAInk,
    inout half3 plateBInk,
    inout half3 keyPlateInk)
{
    // 0 = Custom
    if (preset < 0.5) return;

    // 1 = PinkBlue
    if (preset < 1.5)
    {
        plateAInk = half3(1.00h, 0.08h, 0.28h);
        plateBInk = half3(0.00h, 0.55h, 1.00h);
        keyPlateInk = half3(0.04h, 0.04h, 0.06h);
        return;
    }
    // 2 = RedBlue
    if (preset < 2.5)
    {
        plateAInk = half3(0.95h, 0.12h, 0.08h);
        plateBInk = half3(0.08h, 0.22h, 0.85h);
        keyPlateInk = half3(0.05h, 0.045h, 0.04h);
        return;
    }
    // 3 = BlackCyan
    if (preset < 3.5)
    {
        plateAInk = half3(0.85h, 0.12h, 0.25h);
        plateBInk = half3(0.00h, 0.80h, 0.85h);
        keyPlateInk = half3(0.035h, 0.04h, 0.055h);
        return;
    }

    // 4 = Vintage
    plateAInk = half3(0.72h, 0.20h, 0.16h);
    plateBInk = half3(0.16h, 0.32h, 0.58h);
    keyPlateInk = half3(0.10h, 0.085h, 0.065h);
}

inline half3 ApplyIrozure(IBT_V2F i, half3 litColor, half3 baseTexture)
{
    half3 plateAInk = _CustomAColor.rgb;
    half3 plateBInk = _CustomBColor.rgb;
    half3 keyPlateInk = _CustomKeyColor.rgb;
    half effectStrength = _EffectStrength;
    half saturation = _Saturation;
    IrozurePreset(
        _IBTPreset,
        plateAInk,
        plateBInk,
        keyPlateInk
    );

    float2 plateAUV = i.uv + _PlateAOffset.xy * _ShiftScale;
    float2 plateBUV = i.uv + _PlateBOffset.xy * _ShiftScale;
    float2 keyPlateUV = i.uv + _KeyPlateOffset.xy * _ShiftScale;
    half3 plateASample = tex2D(_MainTex, plateAUV).rgb * _Color.rgb;
    half3 plateBSample = tex2D(_MainTex, plateBUV).rgb * _Color.rgb;
    half3 keyPlateSample = tex2D(_MainTex, keyPlateUV).rgb * _Color.rgb;

    // 中央との差分が大きい場所 = 色面や輪郭の端. 暗部は締める
    half plateAMask = smoothstep(0.03h, 0.22h, length(plateASample - baseTexture));
    half plateBMask = smoothstep(0.03h, 0.22h, length(plateBSample - baseTexture));
    half keyPlateMask = smoothstep(0.45h, 0.95h, 1.0h - IBT_Luminance(keyPlateSample));

    half3 result = litColor;
    result = lerp(result, plateAInk, saturate(plateAMask * effectStrength * 0.55h));
    result = lerp(result, plateBInk, saturate(plateBMask * effectStrength * 0.55h));
    result = lerp(result, keyPlateInk, saturate(keyPlateMask * effectStrength * 0.18h));
    return IBT_Saturation(result, saturation);
}

#endif
