// Composite7_HiZ.glsl - Hierarchical Z-Buffer Generation
// Phase 4: Advanced Lighting & Reflection

#include "/InternalLib/Common/Vertex.glsl"
#include "/InternalLib/Common/Fragment.glsl"

layout(r32f) uniform image2D hizTex;  // 1024x1024, stores mip levels

// ============================================================================
// Vertex Shader
// ============================================================================
#ifdef VERTEX_SHADER
void main() {
    gl_Position = ftransform();
}
#endif

// ============================================================================
// Fragment Shader
// ============================================================================
#ifdef FRAGMENT_SHADER

uniform sampler2D depthTex;  // Full resolution depth buffer

// Generate HiZ pyramid
// Each mip level stores the maximum depth of 4 samples from previous level
void main() {
    ivec2 coord = ivec2(gl_FragCoord.xy);
    
    // Base level (mip 0): Sample from full-res depth
    if (coord.x < 512 && coord.y < 512) {
        float d0 = texture(depthTex, (vec2(coord * 2) + vec2(0, 0)) / vec2(viewWidth, viewHeight)).r;
        float d1 = texture(depthTex, (vec2(coord * 2) + vec2(1, 0)) / vec2(viewWidth, viewHeight)).r;
        float d2 = texture(depthTex, (vec2(coord * 2) + vec2(0, 1)) / vec2(viewWidth, viewHeight)).r;
        float d3 = texture(depthTex, (vec2(coord * 2) + vec2(1, 1)) / vec2(viewWidth, viewHeight)).r;
        
        float maxDepth = max(max(d0, d1), max(d2, d3));
        imageStore(hizTex, coord, vec4(maxDepth));
    }
    
    // Higher mip levels are generated in subsequent passes
    // This is a simplified single-pass version
    // For full implementation, use 10 passes or compute shader
}

// ============================================================================
// HiZ Ray March Function (to be included in SSR shader)
// ============================================================================
/*
vec3 hiZMarch(vec3 origin, vec3 dir, float maxDistance) {
    const int maxSteps = 64;
    const int maxMipLevels = 10;
    
    vec3 currentPos = origin;
    float mipLevel = float(maxMipLevels);
    float stepSize = maxDistance / float(maxSteps);
    
    for (int i = 0; i < maxSteps; i++) {
        // Project to screen space
        vec4 screenPos = projectionMatrix * viewMatrix * vec4(currentPos, 1.0);
        screenPos.xyz /= screenPos.w;
        screenPos.xy = screenPos.xy * 0.5 + 0.5;
        
        if (screenPos.xy < 0.0 || screenPos.xy > 1.0) {
            break;
        }
        
        // Sample HiZ at current mip level
        float hizDepth = texture(hizTex, screenPos.xy, mipLevel).r;
        
        if (currentPos.z < hizDepth) {
            // Hit: refine step
            mipLevel = max(0.0, mipLevel - 1.0);
            stepSize *= 0.5;
        } else {
            // Miss: continue marching
            currentPos += dir * stepSize;
        }
        
        if (mipLevel <= 0.0 && stepSize < 0.001) {
            break;
        }
    }
    
    return currentPos;
}
*/

#endif
