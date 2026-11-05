// Deferred6_SSGI.glsl - Screen Space Global Illumination (Experimental)
// Phase 6: Experimental Ray Tracing

#include "/InternalLib/Common/Vertex.glsl"
#include "/InternalLib/Common/Fragment.glsl"
#include "/InternalLib/Samplers/NoiseLib.glsl"

layout(rgba16f) uniform image2D giTex;  // GI output buffer

uniform int giRays;
uniform float giRadius;

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

uniform sampler2D colortex0;  // Albedo
uniform sampler2D depthTex;
uniform sampler2D normalTex;
uniform mat3 gbufferNormalMatrix;

// Cosine-weighted hemisphere sampling
vec3 cosineSampleHemisphere(int index, vec3 normal) {
    // Use blue noise for better distribution
    float xi = texture(blueNoiseTex, gl_FragCoord.xy / 128.0).r;
    float phi = 2.0 * 3.14159265359 * (xi + float(index) / float(giRays));
    
    float r = sqrt(1.0 - xi);
    vec3 dir;
    dir.x = r * cos(phi);
    dir.y = r * sin(phi);
    dir.z = sqrt(xi);
    
    // Rotate to align with normal
    vec3 up = abs(normal.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent = normalize(cross(up, normal));
    vec3 bitangent = cross(normal, tangent);
    return normalize(dir.x * tangent + dir.y * bitangent + dir.z * normal);
}

void main() {
    ivec2 coord = ivec2(gl_FragCoord.xy);
    vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    
    // Sample scene data
    float depth = texture(depthTex, uv).r;
    if (depth >= 1.0) {
        imageStore(giTex, coord, vec4(0.0));
        return;
    }
    
    vec3 albedo = texture(colortex0, uv).rgb;
    vec3 normal = texture(normalTex, uv).rgb * 2.0 - 1.0;
    normal = normalize(gbufferNormalMatrix * normal);
    
    // Reconstruct world position
    vec3 viewPos = getPositionView(uv, depth);
    vec3 worldPos = getViewPos(worldPosition, viewPos);
    
    // SSGI calculation
    vec3 gi = vec3(0.0);
    float totalWeight = 0.0;
    
    for (int i = 0; i < giRays; i++) {
        // Sample direction
        vec3 dir = cosineSampleHemisphere(i, normal);
        
        // March along ray
        vec3 samplePos = worldPos;
        float stepSize = giRadius / 16.0;
        
        for (int step = 0; step < 16; step++) {
            samplePos += dir * stepSize;
            
            // Project to screen space
            vec4 screenPos = projectionMatrix * viewMatrix * vec4(samplePos, 1.0);
            screenPos.xyz /= screenPos.w;
            screenPos.xy = screenPos.xy * 0.5 + 0.5;
            
            // Bounds check
            if (screenPos.xy < 0.0 || screenPos.xy > 1.0) {
                break;
            }
            
            // Sample scene depth and color
            float sceneDepth = texture(depthTex, screenPos.xy).r;
            vec3 sceneColor = texture(colortex0, screenPos.xy).rgb;
            
            // Depth test (with tolerance)
            float sceneViewZ = -screenPos.z / screenPos.w;
            if (abs(sceneDepth + viewPos.z) < 0.01) {
                // Hit: accumulate GI
                float distanceWeight = 1.0 - float(step) / 16.0;
                gi += sceneColor * albedo * distanceWeight;
                totalWeight += distanceWeight;
                break;
            }
        }
    }
    
    // Normalize GI
    if (totalWeight > 0.0) {
        gi /= totalWeight;
    }
    
    // Apply intensity
    gi *= 0.5;  // GI intensity
    
    imageStore(giTex, coord, vec4(gi, 1.0));
}

#endif
