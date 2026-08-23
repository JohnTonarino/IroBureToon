#ifndef IBT_OUTLINE_INCLUDED
#define IBT_OUTLINE_INCLUDED

#include "IBT_Lighting.cginc"

struct IBT_OutlineV2F
{
    float4 pos : SV_POSITION;
    UNITY_FOG_COORDS(0)
    UNITY_VERTEX_OUTPUT_STEREO
};

IBT_OutlineV2F IBT_OutlineVert(IBT_AppData v)
{
    IBT_OutlineV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(IBT_OutlineV2F, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 clipPosition = UnityObjectToClipPos(v.vertex);
    float3 normalVS = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
    float normalLength = max(length(normalVS.xy), 0.0001);
    float2 direction = normalVS.xy / normalLength;
    float2 offset = TransformViewToProjection(direction);

    float mask = tex2Dlod(_OutlineMask, float4(v.uv, 0.0, 0.0)).r;
    clipPosition.xy += _OutlineWidth*offset * mask;

    o.pos = clipPosition;
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

fixed4 IBT_OutlineFrag(IBT_OutlineV2F i) : SV_Target
{
    fixed4 color = _OutlineColor;
    half3 ambient = IBT_LimitLight(ShadeSH9(half4(0.0h, 1.0h, 0.0h, 1.0h)));
    color.rgb *= lerp(half3(1.0h, 1.0h, 1.0h), ambient, _OutlineLighting);
    UNITY_APPLY_FOG(i.fogCoord, color);
    return color;
}

#endif
