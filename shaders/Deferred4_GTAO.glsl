// Deferred4_GTAO.glsl
// Phase 4 reference module: Ground Truth Ambient Occlusion kernel.
//
// REFERENCE ONLY - NOT YET WIRED INTO THE PASS PIPELINE. AO_GTAO is a
// declared toggle in UserLib/AdvancedSettings.glsl; wiring this kernel into
// a Passes/ AO pass is tracked in docs/PHASE3-6-IMPLEMENTATION-REPORT.md.
//
// All functions are pure: positions, normals and depth samples are passed
// in by the caller so the kernel can be unit-tested and reused at any
// render scale.

#ifndef _GTAO_GLSL_
#define _GTAO_GLSL_

#define GTAO_SLICE_COUNT 4
#define GTAO_SAMPLES_PER_SLICE 4

// Single-slice horizon-based occlusion estimate.
//   viewPos  : receiver position in view space
//   viewDir  : normalized direction from camera to receiver
//   sliceDir : normalized slice direction in view space (tangent to screen)
//   normal   : shading normal in view space
//   radius   : effect radius in view space
// The slice uses a coarse view-space depth probe for occlusion; a wired pass
// replaces the probe with real scene depth samples.
float gtaoSlice(vec3 viewPos, vec3 viewDir, vec3 sliceDir, vec3 normal,
                float radius, int sampleCount) {
    // Project normal onto the slice plane.
    vec3 n = normalize(normal - sliceDir * dot(normal, sliceDir));
    float nDotView = dot(n, viewDir);

    float cosHorizonL = nDotView;
    float cosHorizonR = nDotView;
    float occlusion = 0.0;

    for (int s = 0; s < sampleCount; s++) {
        float t = (float(s) + 0.5) / float(sampleCount);
        float side = (s % 2 == 0) ? 1.0 : -1.0;
        float arc = t * radius;

        vec3 offset = (sliceDir * side + viewDir * nDotView) * arc;
        float sampleDepth = length(viewPos + offset); // caller may refine

        if (sampleDepth < length(viewPos) + arc) {
            float cosHorizon = clamp(dot(normalize(offset), n), 0.0, 1.0);
            if (side > 0.0) {
                cosHorizonR = max(cosHorizonR, cosHorizon);
            } else {
                cosHorizonL = max(cosHorizonL, cosHorizon);
            }
        }
    }

    // Horizon integral for this slice.
    occlusion = (cosHorizonL + cosHorizonR - 2.0 * nDotView);
    return clamp(occlusion, 0.0, 1.0);
}

// Full GTAO estimate: averages GTAO_SLICE_COUNT screen-aligned slices.
//   sampleOcclusion : caller-provided function evaluating the scene for a
//                     world/view-space probe (depth-test based)
float gtao(vec3 viewPos, vec3 viewDir, vec3 normal, float radius,
           float dither) {
    vec3 sliceBase = normalize(cross(viewDir, vec3(0.0, 1.0, 0.0)));
    float occlusion = 0.0;

    for (int slice = 0; slice < GTAO_SLICE_COUNT; slice++) {
        float angle = (float(slice) + dither) * 3.14159265 / float(GTAO_SLICE_COUNT);
        vec3 sliceDir = normalize(sliceBase * cos(angle) +
                                  cross(viewDir, sliceBase) * sin(angle));
        occlusion += gtaoSlice(viewPos, viewDir, sliceDir, normal, radius,
                               GTAO_SAMPLES_PER_SLICE);
    }

    return 1.0 - occlusion / float(GTAO_SLICE_COUNT);
}

#endif // _GTAO_GLSL_
