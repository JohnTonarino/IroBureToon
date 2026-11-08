// Copyright (c) 2026 JohnTonarino
// Released under the MIT license
// JTN_Lighting v 1.0.0
#ifndef JTN_PROPERTIES_INCLUDED
#define JTN_PROPERTIES_INCLUDED

// Toon Shadow
sampler2D _ShadowTex;
half      _ShadowStep1;
half      _ShadowStep2;
half      _ShadowStrength;
sampler2D _SDFMaskTex;

// MatCap
sampler2D _MatCap;
sampler2D _MatCapMask;
half      _MatCapStrength;

// Specular
fixed4    _SpecularColor;
half      _SpecularStrength;
half      _SpecularSize;
half      _SpecularSmoothness;

// Lighting Control (OpenLit)
half      _AsUnlit;
half      _LightMinLimit;
half      _LightMaxLimit;
half      _MonochromeLighting;

// VRCLightVolumes
half      _VRCLightVolumesStrength;

#endif // JTN_PROPERTIES_INCLUDED
