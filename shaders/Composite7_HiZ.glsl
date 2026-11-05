// Composite7_HiZ.glsl
// Phase 4 reference module: Hierarchical-Z (HiZ) acceleration for SSR.
//
// REFERENCE ONLY - NOT YET WIRED INTO THE PASS PIPELINE. The live pass
// programs live in Passes/ and are fused by the build scripts; this module
// provides the algorithms for a future Passes/HiZ pass and for integrating
// HiZ-accelerated ray marching into the specular pass.
//
// Integration prerequisites (tracked in docs/PHASE3-6-IMPLEMENTATION-REPORT.md):
//   - one free image slot or a colortex target for the pyramid
//   - a compute pass to build the pyramid after depth construction
//   - hooking hiZMarch into the specular ray march

#ifndef _HIZ_GLSL_
#define _HIZ_GLSL_

#define HIZ_MAX_MIP_LEVELS 10

// Reduce a 2x2 quad of linear depths to the conservative max (nearest occluder).
float hiZReduceQuad(float d0, float d1, float d2, float d3) {
    return max(max(d0, d1), max(d2, d3));
}

// Screen-space march against a HiZ pyramid stored in a single texture whose
// mip levels hold the per-level maximum depth.
//   hizSampler : pyramid texture (mip 0 = full-res max-reduced depth)
//   rayOrigin  : screen-space xyz, xy in [0,1], z = linear depth
//   rayDir     : screen-space direction (pre-divided by projected w)
// Returns the hit uv in .xy and the hit linear depth in .z; z < 0.0 on miss.
vec3 hiZMarch(sampler2D hizSampler, vec3 rayOrigin, vec3 rayDir, int maxSteps) {
    vec3 pos = rayOrigin;
    float mip = float(HIZ_MAX_MIP_LEVELS - 1);

    for (int i = 0; i < maxSteps; i++) {
        vec2 mipSize = vec2(textureSize(hizSampler, 0));
        float levelSize = exp2(-mip);

        // Advance one cell of the current mip level.
        vec2 cellSize = levelSize / mipSize;
        vec3 delta = rayDir / max(abs(rayDir.z), 1e-6);
        vec3 nextCross = pos + delta * cellSize.y * sign(rayDir.z);

        float cellDepth = texelFetch(hizSampler, ivec2(pos.xy * mipSize), int(mip)).r;

        if (nextCross.z > cellDepth) {
            // Ray passes behind the occluder bound of this cell: refine.
            if (mip <= 0.0) {
                return vec3(pos.xy, pos.z);
            }
            mip -= 1.0;
        } else {
            pos = nextCross;
            mip = min(float(HIZ_MAX_MIP_LEVELS - 1), mip + 1.0);
        }

        if (any(lessThan(pos.xy, vec2(0.0))) || any(greaterThan(pos.xy, vec2(1.0)))) {
            break;
        }
    }

    return vec3(pos.xy, -1.0);
}

#endif // _HIZ_GLSL_
