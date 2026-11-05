// InternalLib/Utilities/MaterialPBR.glsl
#ifndef _MATERIAL_PBR_GLSL_
#define _MATERIAL_PBR_GLSL_

// ============================================================================
// labPBR Material Decoding (Phase 3)
// ============================================================================
// Companion library to Materials.glsl (which keeps the vanilla block-ID
// helpers: GetLightColor / GetEmitterMask / IsVeg / ...).
//
// STATUS: reference library for the LabPBR texture-format upgrade. The
// gbuffers path currently consumes vanilla material data; wiring this into
// the gbuffer encoding/decoding chain is tracked in
// docs/PHASE3-6-IMPLEMENTATION-REPORT.md.
//
// labPBR 1.3 specular texture layout:
//   R: perceptual roughness   (255 -> 0.0 smooth, 0 -> 1.0 rough)
//   G: metal mask             (230-255 = f0 varies, else binary)
//   B: porosity / subsurface  (semantics depend on metal value)
//   A: emission strength
//
// Callers must define MATERIAL_PBR_FORMAT before including:
//   0 = vanilla (no specular texture), 1 = labPBR 1.3, 2 = legacy SEUS
// ============================================================================

// labPBR encodes perceptual roughness inverted; convert to linear.
float labPBRDecodeRoughness(float encoded) {
    return encoded * encoded;
}

// f0 for dielectrics from the packed specular value; 230-255 encodes
// a specific IoR on the green channel per labPBR 1.3.
float labPBRDecodeF0(float packed) {
    return packed * 0.08 + 0.02;
}

// Decode the specular map into (roughness, metallic, f0, emission).
//   spec : raw specular texture sample
vec4 labPBRDecodeSpecular(vec4 spec) {
#if MATERIAL_PBR_FORMAT == 1
    float roughness = labPBRDecodeRoughness(spec.r);
    float metallic  = step(0.5, spec.g) * (spec.g < 230.0 / 255.0 ? 1.0 : 1.0);
    float f0        = mix(labPBRDecodeF0(spec.b), 0.85, metallic);
    float emission  = spec.a;
    return vec4(roughness, metallic, f0, emission);
#elif MATERIAL_PBR_FORMAT == 2
    // Legacy SEUS-style: R = smoothness, G = metallic-ish, B/A unused.
    float roughness = 1.0 - spec.r;
    return vec4(roughness, clamp(spec.g, 0.0, 1.0), 0.04, 0.0);
#else
    // Vanilla fallback values.
    return vec4(0.8, 0.0, 0.04, 0.0);
#endif
}

// Transform a tangent-space normal map sample to the given frame.
vec3 labPBRDecodeNormal(vec3 packedNormal, mat3 tbnFrame) {
    vec3 n = packedNormal * 2.0 - 1.0;
    n.z = max(n.z, 0.001);
    return normalize(tbnFrame * normalize(n));
}

// Fallback PBR constants per coarse material class for blocks without a
// labPBR resource pack. Values mirror common shaderpack defaults.
//   class : 0 stone, 1 wood, 2 metal, 3 glass, 4 water, 5 leaf, 6 fabric
vec4 labPBRFallbackMaterial(int class) {
    switch (class) {
        case 1:  return vec4(0.6, 0.0, 0.03, 0.0);  // wood: semi-rough dielectric
        case 2:  return vec4(0.3, 1.0, 0.85, 0.0);  // metal
        case 3:  return vec4(0.1, 0.0, 0.04, 0.0);  // glass: smooth dielectric
        case 4:  return vec4(0.2, 0.0, 0.02, 0.0);  // water
        case 5:  return vec4(0.8, 0.0, 0.01, 0.0);  // leaf
        case 6:  return vec4(0.9, 0.0, 0.01, 0.0);  // fabric
        default: return vec4(0.7, 0.0, 0.02, 0.0);  // stone
    }
}

#endif // _MATERIAL_PBR_GLSL_
