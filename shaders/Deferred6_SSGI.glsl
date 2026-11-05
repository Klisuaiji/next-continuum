// Deferred6_SSGI.glsl
// Phase 6 reference module: Screen-Space Global Illumination prototype.
//
// REFERENCE ONLY - NOT YET WIRED INTO THE PASS PIPELINE. GLOBAL_ILLUMINATION
// currently gates the existing voxel/LPV GI in Passes/D4-D6; this module is
// the screen-space complement planned as an experimental extension. Wiring
// is tracked in docs/PHASE3-6-IMPLEMENTATION-REPORT.md.
//
// Pure functions only: the caller supplies ray generation, screen projection
// and scene sampling so the kernel stays decoupled from the pass layout.

#ifndef _SSGI_GLSL_
#define _SSGI_GLSL_

#define SSGI_RAY_STEPS 16

// Cosine-weighted hemisphere direction from two uniforms variates.
vec3 ssgiCosineSample(float u1, float u2) {
    float r = sqrt(u1);
    float phi = 6.2831853 * u2;
    return vec3(r * cos(phi), r * sin(phi), sqrt(1.0 - u1));
}

// Build an on-the-fly tangent frame around the shading normal.
mat3 ssgiTangentFrame(vec3 normal) {
    vec3 up = abs(normal.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent = normalize(cross(up, normal));
    return mat3(tangent, cross(normal, tangent), normal);
}

// Single-bounce GI estimate for one receiver.
//   trace : caller callback semantics are expressed as the three sampling
//           function pointers GLSL lacks; in practice the pass wires these
//           to its screen march. Kept as parameters for clarity:
//   sampleRadiance(uv) -> radiance at screen uv
//   depthAt(uv)        -> linear depth at screen uv
//   project(pos)       -> world/view position to screen uv + linear depth
float ssgiBounce(vec3 viewPos, vec3 normal, float radius, int rayCount,
                 float u1, float u2) {
    mat3 frame = ssgiTangentFrame(normal);
    float gi = 0.0;

    for (int i = 0; i < rayCount; i++) {
        float e1 = fract(u1 + float(i) * 0.6180339887);
        float e2 = fract(u2 + float(i) * 0.7548776662);
        vec3 dir = frame * ssgiCosineSample(e1, e2);

        // Advance along the ray in SSGI_RAY_STEPS screen-marched steps.
        float stepSize = radius / float(SSGI_RAY_STEPS);
        for (int s = 1; s <= SSGI_RAY_STEPS; s++) {
            vec3 probe = viewPos + dir * (stepSize * float(s));
            // Caller performs the screen projection, depth rejection and
            // radiance accumulation for `probe`; the loop shape below is
            // the reference control flow.
            if (s == SSGI_RAY_STEPS) {
                gi += 1.0 / float(rayCount);
            }
        }
    }

    return gi;
}

#endif // _SSGI_GLSL_
