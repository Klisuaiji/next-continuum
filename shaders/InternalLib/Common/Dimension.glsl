// InternalLib/Common/Dimension.glsl
#ifndef DIMENSION_SYSTEM
#define DIMENSION_SYSTEM

// ============================================================================
// Dimension ID Constants
// ============================================================================
#define DIM_OVERWORLD        0
#define DIM_NETHER           1
#define DIM_END              2
#define DIM_TWILIGHT_FOREST  10
#define DIM_AETHER           11
#define DIM_MARS             12
#define DIM_MOON             13

// ============================================================================
// Dimension Parameters Structure
// ============================================================================
struct DimensionParams {
    vec3 skyColor;
    vec3 fogColor;
    float ambientBrightness;
    float cloudHeight;
    bool hasAtmosphere;
    vec3 atmosphereColor;
    vec3 sunColor;
    vec3 moonColor;
};

// ============================================================================
// Get Dimension Parameters
// ============================================================================
DimensionParams getDimensionParams() {
    DimensionParams params;
    
    #ifdef DIMENSION_OVERWORLD
        params.skyColor = vec3(0.5, 0.7, 1.0);
        params.fogColor = vec3(0.8, 0.9, 1.0);
        params.ambientBrightness = 1.0;
        params.cloudHeight = 200.0;
        params.hasAtmosphere = true;
        params.atmosphereColor = vec3(1.0, 0.95, 0.9);
        params.sunColor = vec3(1.0, 0.95, 0.85);
        params.moonColor = vec3(0.9, 0.95, 1.0);
        
    #elifdef DIMENSION_NETHER
        params.skyColor = vec3(0.3, 0.1, 0.1);
        params.fogColor = vec3(0.5, 0.2, 0.1);
        params.ambientBrightness = 0.4;
        params.cloudHeight = 0.0;
        params.hasAtmosphere = true;
        params.atmosphereColor = vec3(1.0, 0.5, 0.3);
        params.sunColor = vec3(0.0);  // No sun
        params.moonColor = vec3(0.0);
        
    #elifdef DIMENSION_END
        params.skyColor = vec3(0.6, 0.5, 0.8);
        params.fogColor = vec3(0.8, 0.7, 0.9);
        params.ambientBrightness = 0.6;
        params.cloudHeight = 0.0;
        params.hasAtmosphere = false;
        params.atmosphereColor = vec3(0.0);
        params.sunColor = vec3(0.0);
        params.moonColor = vec3(0.0);
        
    #elifdef DIMENSION_TWILIGHT_FOREST
        // Twilight Forest: Dense canopy, dim sky
        params.skyColor = vec3(0.3, 0.4, 0.6);
        params.fogColor = vec3(0.4, 0.5, 0.6);
        params.ambientBrightness = 0.6;
        params.cloudHeight = 120.0;
        params.hasAtmosphere = true;
        params.atmosphereColor = vec3(0.8, 0.75, 0.7);
        params.sunColor = vec3(0.9, 0.85, 0.7);
        params.moonColor = vec3(0.7, 0.75, 0.9);
        
    #elifdef DIMENSION_AETHER
        // Aether: High-altitude floating islands, bright sky
        params.skyColor = vec3(0.8, 0.9, 1.0);
        params.fogColor = vec3(0.9, 0.95, 1.0);
        params.ambientBrightness = 1.3;
        params.cloudHeight = 300.0;
        params.hasAtmosphere = true;
        params.atmosphereColor = vec3(1.0, 0.98, 0.95);
        params.sunColor = vec3(1.0, 0.98, 0.9);
        params.moonColor = vec3(0.95, 0.98, 1.0);
        
    #elifdef DIMENSION_MARS
        // Mars (Ad Astra): Thin atmosphere, red sky
        params.skyColor = vec3(0.9, 0.4, 0.3);
        params.fogColor = vec3(0.8, 0.5, 0.4);
        params.ambientBrightness = 0.7;
        params.cloudHeight = 50.0;
        params.hasAtmosphere = true;
        params.atmosphereColor = vec3(1.0, 0.6, 0.5);
        params.sunColor = vec3(1.0, 0.9, 0.8);
        params.moonColor = vec3(0.8, 0.7, 0.7);
        
    #elifdef DIMENSION_MOON
        // Moon (Ad Astra): No atmosphere, black sky
        params.skyColor = vec3(0.0, 0.0, 0.0);
        params.fogColor = vec3(0.0, 0.0, 0.0);
        params.ambientBrightness = 0.3;
        params.cloudHeight = 0.0;
        params.hasAtmosphere = false;
        params.atmosphereColor = vec3(0.0);
        params.sunColor = vec3(1.0, 1.0, 0.95);
        params.moonColor = vec3(0.0);
        
    #else
        // Default: Overworld
        params.skyColor = vec3(0.5, 0.7, 1.0);
        params.fogColor = vec3(0.8, 0.9, 1.0);
        params.ambientBrightness = 1.0;
        params.cloudHeight = 200.0;
        params.hasAtmosphere = true;
        params.atmosphereColor = vec3(1.0, 0.95, 0.9);
        params.sunColor = vec3(1.0, 0.95, 0.85);
        params.moonColor = vec3(0.9, 0.95, 1.0);
    #endif
    
    return params;
}

// ============================================================================
// Check if Current Dimension Has Atmosphere
// ============================================================================
bool hasAtmosphere() {
    #ifdef DIMENSION_END
        return false;
    #elifdef DIMENSION_MOON
        return false;
    #else
        return true;
    #endif
}

// ============================================================================
// Get Cloud Height for Current Dimension
// ============================================================================
float getCloudHeight() {
    DimensionParams params = getDimensionParams();
    return params.cloudHeight;
}

// ============================================================================
// Dimension-Specific Fog Density Multiplier
// ============================================================================
float getFogDensityMultiplier() {
    #ifdef DIMENSION_NETHER
        return 2.5;  // Dense nether fog
    #elifdef DIMENSION_END
        return 1.5;
    #elifdef DIMENSION_TWILIGHT_FOREST
        return 1.3;  // Slightly denser due to canopy
    #else
        return 1.0;
    #endif
}

#endif // DIMENSION_SYSTEM
