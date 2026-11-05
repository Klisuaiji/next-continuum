// Deferred4_GTAO.glsl - Ground Truth Ambient Occlusion
// Phase 4: Advanced Lighting & Reflection

#include "/InternalLib/Common/Vertex.glsl"
#include "/InternalLib/Common/Fragment.glsl"
#include "/InternalLib/Samplers/NoiseLib.glsl"

layout(rgba8) uniform image2D aoTex;  // Quarter resolution AO output

uniform float aoRadius;
uniform int aoSamples;

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

uniform sampler2D depthTex;
uniform sampler2D normalTex;
uniform mat3 gbufferNormalMatrix;

// Hemisphere sampling pattern (precomputed)
const vec3 hemisphereSamples[16] = vec3[](
    vec3(0.0, 1.0, 0.0),
    vec3(0.5, 0.866, 0.0),
    vec3(0.866, 0.5, 0.0),
    vec3(1.0, 0.0, 0.0),
    vec3(0.866, -0.5, 0.0),
    vec3(0.5, -0.866, 0.0),
    vec3(0.0, -1.0, 0.0),
    vec3(-0.5, -0.866, 0.0),
    vec3(-0.866, -0.5, 0.0),
    vec3(-1.0, 0.0, 0.0),
    vec3(-0.866, 0.5, 0.0),
    vec3(-0.5, 0.866, 0.0),
    vec3(0.3, 0.7, 0.5),
    vec3(-0.3, 0.7, 0.5),
    vec3(0.3, -0.7, 0.5),
    vec3(-0.3, -0.7, 0.5)
);

// Rotate vector to align with normal
vec3 rotateToNormal(vec3 v, vec3 normal) {
    vec3 up = abs(normal.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent = normalize(cross(up, normal));
    vec3 bitangent = cross(normal, tangent);
    return v.x * tangent + v.y * bitangent + v.z * normal;
}

void main() {
    ivec2 coord = ivec2(gl_FragCoord.xy);
    vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    
    // Sample depth and normal
    float depth = texture(depthTex, uv).r;
    if (depth >= 1.0) {
        imageStore(aoTex, coord, vec4(1.0));
        return;
    }
    
    vec3 normal = texture(normalTex, uv).rgb * 2.0 - 1.0;
    normal = normalize(gbufferNormalMatrix * normal);
    
    // Reconstruct world position
    vec3 viewPos = getPositionView(uv, depth);
    vec3 worldPos = getViewPos(worldPosition, viewPos);
    
    // GTAO calculation
    float ao = 0.0;
    float radius = aoRadius;
    
    for (int i = 0; i < aoSamples; i++) {
        // Get sample direction
        vec3 sampleDir = hemisphereSamples[i];
        sampleDir = rotateToNormal(sampleDir, normal);
        
        // Sample position
        vec3 samplePos = worldPos + sampleDir * radius;
        
        // Project to screen space
        vec4 screenPos = projectionMatrix * viewMatrix * vec4(samplePos, 1.0);
        screenPos.xyz /= screenPos.w;
        screenPos.xy = screenPos.xy * 0.5 + 0.5;
        
        if (screenPos.xy < 0.0 || screenPos.xy > 1.0) {
            continue;
        }
        
        // Sample scene depth
        float sampleDepth = texture(depthTex, screenPos.xy).r;
        
        // Depth comparison
        float sampleViewZ = -screenPos.z / screenPos.w;
        if (sampleDepth < -viewPos.z) {
            ao += 1.0;
        }
    }
    
    ao /= float(aoSamples);
    ao = 1.0 - ao;
    
    // Apply horizon-based attenuation
    float horizonAO = max(0.0, normal.z);
    ao = mix(ao, 1.0, horizonAO * 0.3);
    
    imageStore(aoTex, coord, vec4(ao));
}

#endif
