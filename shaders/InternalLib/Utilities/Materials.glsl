// InternalLib/Utilities/Materials.glsl
#ifndef MATERIAL_SYSTEM
#define MATERIAL_SYSTEM

#include "/UserLib/LightingSettings.glsl"

// ============================================================================
// labPBR Texture Format Definitions
// ============================================================================
#define TEXTURE_FORMAT_LAB     1  // Full labPBR 1.3+
#define TEXTURE_FORMAT_OLD     2  // Legacy labPBR
#define TEXTURE_FORMAT_VANILLA 0  // No PBR textures

#ifndef TEXTURE_FORMAT
    #define TEXTURE_FORMAT TEXTURE_FORMAT_LAB
#endif

// ============================================================================
// Material Structure
// ============================================================================
struct Material {
    vec3 albedo;
    vec3 normal;
    float roughness;
    float metallic;
    float specular;
    vec3 emission;
    float subsurface;
    float porosity;
    float thickness;
};

// ============================================================================
// Material ID Constants (for fallback materials)
// ============================================================================
#define MAT_STONE       0
#define MAT_WOOD        1
#define MAT_METAL       2
#define MAT_GLASS       3
#define MAT_WATER       4
#define MAT_LEAF        5
#define MAT_SKIN        6
#define MAT_FABRIC      7
#define MAT_EMISSIVE    8

// ============================================================================
// Read Specular Map (labPBR format)
// ============================================================================
vec4 readSpecularMap(sampler2D specularMap, vec2 uv) {
    #if TEXTURE_FORMAT == TEXTURE_FORMAT_LAB
        // Full labPBR 1.3+: R=roughness, G=metallic, B=specular, A=emission
        return texture(specularMap, uv);
        
    #elif TEXTURE_FORMAT == TEXTURE_FORMAT_OLD
        // Legacy labPBR: R=roughness, G=metallic, B=emission
        vec4 s = texture(specularMap, uv);
        return vec4(s.r, s.g, 0.02, s.b);
        
    #else
        // Vanilla: default values
        return vec4(0.5, 0.0, 0.02, 0.0);
    #endif
}

// ============================================================================
// Read Normal Map with Tangent Space Transformation
// ============================================================================
vec3 readNormalMap(sampler2D normalMap, vec2 uv, vec3 tangent, vec3 bitangent, vec3 normal) {
    #ifdef USE_NORMAL_MAPPING
        vec3 n = texture(normalMap, uv).rgb * 2.0 - 1.0;
        n.z += 0.001; // Prevent division by zero
        n = normalize(n);
        
        // Transform from tangent space to world space
        mat3 tbn = mat3(normalize(tangent), normalize(bitangent), normalize(normal));
        return normalize(tbn * n);
    #else
        return normalize(normal);
    #endif
}

// ============================================================================
// Fallback Material (when no labPBR textures available)
// ============================================================================
Material getFallbackMaterial(int materialID) {
    Material mat;
    mat.albedo = vec3(1.0);
    mat.normal = vec3(0.0, 0.0, 1.0);
    mat.subsurface = 0.0;
    mat.porosity = 0.5;
    mat.thickness = 1.0;
    mat.emission = vec3(0.0);
    
    switch (materialID) {
        case MAT_STONE:
            mat.roughness = 0.7;
            mat.metallic = 0.0;
            mat.specular = 0.02;
            break;
            
        case MAT_WOOD:
            mat.roughness = 0.6;
            mat.metallic = 0.0;
            mat.specular = 0.03;
            mat.subsurface = 0.1;
            break;
            
        case MAT_METAL:
            mat.roughness = 0.3;
            mat.metallic = 1.0;
            mat.specular = 0.8;
            break;
            
        case MAT_GLASS:
            mat.roughness = 0.1;
            mat.metallic = 0.0;
            mat.specular = 0.04;
            break;
            
        case MAT_WATER:
            mat.roughness = 0.2;
            mat.metallic = 0.0;
            mat.specular = 0.02;
            break;
            
        case MAT_LEAF:
            mat.roughness = 0.8;
            mat.metallic = 0.0;
            mat.specular = 0.01;
            mat.subsurface = 0.5;
            break;
            
        case MAT_SKIN:
            mat.roughness = 0.4;
            mat.metallic = 0.0;
            mat.specular = 0.03;
            mat.subsurface = 0.8;
            break;
            
        case MAT_FABRIC:
            mat.roughness = 0.9;
            mat.metallic = 0.0;
            mat.specular = 0.01;
            break;
            
        case MAT_EMISSIVE:
            mat.roughness = 0.5;
            mat.metallic = 0.0;
            mat.specular = 0.02;
            mat.emission = vec3(1.0);
            break;
            
        default:
            mat.roughness = 0.5;
            mat.metallic = 0.0;
            mat.specular = 0.02;
            break;
    }
    
    return mat;
}

// ============================================================================
// Identify Material from Block/Texture Properties
// ============================================================================
int identifyMaterial(vec3 albedo, float brightness, vec3 normal) {
    // Simple heuristic-based material identification
    // Can be extended with texture name matching in the future
    
    // High brightness → emissive
    if (brightness > 0.9) {
        return MAT_EMISSIVE;
    }
    
    // Blue tint + low roughness → water or glass
    if (albedo.b > albedo.r * 1.2 && albedo.b > albedo.g) {
        return MAT_GLASS;
    }
    
    // Green + subsurface → leaves
    if (albedo.g > albedo.r && albedo.g > albedo.b) {
        return MAT_LEAF;
    }
    
    // Default to stone
    return MAT_STONE;
}

// ============================================================================
// Decode Full Material from Textures
// ============================================================================
Material decodeMaterial(
    sampler2D albedoMap,
    sampler2D specularMap,
    sampler2D normalMap,
    vec2 uv,
    vec3 tangent,
    vec3 bitangent,
    vec3 normal
) {
    Material mat;
    
    // Sample albedo
    mat.albedo = texture(albedoMap, uv).rgb;
    
    // Sample specular map
    vec4 specData = readSpecularMap(specularMap, uv);
    mat.roughness = specData.r;
    mat.metallic = specData.g;
    mat.specular = specData.b;
    mat.emission = vec3(specData.a);
    
    // Sample normal
    mat.normal = readNormalMap(normalMap, uv, tangent, bitangent, normal);
    
    // Default subsurface
    mat.subsurface = 0.0;
    
    return mat;
}

#endif // MATERIAL_SYSTEM
