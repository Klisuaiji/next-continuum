// UserLib/WaterPresetSettings.glsl
#ifndef WATER_PRESET_SETTINGS
#define WATER_PRESET_SETTINGS

// ============================================================================
// Water Preset Settings - Independent from Visual Style
// ============================================================================
// Water presets control absorption, scattering, wave height, and foam
// This is separate from visual style settings
// ============================================================================

// Water Preset Definitions
#define WATER_PRESET_NATURAL     0  // Balanced, realistic water
#define WATER_PRESET_CLEAR       1  // Crystal clear tropical water
#define WATER_PRESET_DEEP        2  // Dark ocean depths
#define WATER_PRESET_TURQUOISE   3  // Turquoise tropical paradise
#define WATER_PRESET_MURKY       4  // Murky swamp water
#define WATER_PRESET_CUSTOM      5  // User-defined parameters

// Default water preset
#ifndef WATER_PRESET
    #define WATER_PRESET WATER_PRESET_NATURAL
#endif

// ============================================================================
// Water Optical Parameters
// ============================================================================
// Absorption coefficients (per meter) for RGB channels
// Higher values = faster light absorption = darker water at depth

// Scattering coefficient (controls light diffusion in water)
// Higher = more volumetric lighting effect

// Wave height multiplier (affects normal map intensity)

// Foam amount (white water at wave peaks)

// Specular intensity (sun/moon reflection on surface)

// ============================================================================

#if WATER_PRESET == WATER_PRESET_NATURAL
    // Natural: Balanced realistic water
    #define WP_ABSORPTION_R     0.015
    #define WP_ABSORPTION_G     0.012
    #define WP_ABSORPTION_B     0.008
    #define WP_SCATTERING       0.35
    #define WP_WAVE_HEIGHT      0.8
    #define WP_FOAM_AMOUNT      0.5
    #define WP_SPECULAR_INT     1.0
    #define WP_REFRACTION_STR   0.02
    #define WP_PRESET_NAME      "Natural"

#elif WATER_PRESET == WATER_PRESET_CLEAR
    // Clear: Crystal clear tropical lagoon
    #define WP_ABSORPTION_R     0.008
    #define WP_ABSORPTION_G     0.010
    #define WP_ABSORPTION_B     0.012
    #define WP_SCATTERING       0.25
    #define WP_WAVE_HEIGHT      0.5
    #define WP_FOAM_AMOUNT      0.3
    #define WP_SPECULAR_INT     1.1
    #define WP_REFRACTION_STR   0.025
    #define WP_PRESET_NAME      "Clear"

#elif WATER_PRESET == WATER_PRESET_DEEP
    // Deep: Dark ocean abyss
    #define WP_ABSORPTION_R     0.035
    #define WP_ABSORPTION_G     0.028
    #define WP_ABSORPTION_B     0.020
    #define WP_SCATTERING       0.5
    #define WP_WAVE_HEIGHT      1.2
    #define WP_FOAM_AMOUNT      0.7
    #define WP_SPECULAR_INT     0.9
    #define WP_REFRACTION_STR   0.015
    #define WP_PRESET_NAME      "Deep"

#elif WATER_PRESET == WATER_PRESET_TURQUOISE
    // Turquoise: Tropical paradise Caribbean style
    #define WP_ABSORPTION_R     0.012
    #define WP_ABSORPTION_G     0.018
    #define WP_ABSORPTION_B     0.022
    #define WP_SCATTERING       0.4
    #define WP_WAVE_HEIGHT      0.6
    #define WP_FOAM_AMOUNT      0.4
    #define WP_SPECULAR_INT     1.15
    #define WP_REFRACTION_STR   0.028
    #define WP_PRESET_NAME      "Turquoise"

#elif WATER_PRESET == WATER_PRESET_MURKY
    // Murky: Swamp or river water with sediment
    #define WP_ABSORPTION_R     0.045
    #define WP_ABSORPTION_G     0.038
    #define WP_ABSORPTION_B     0.025
    #define WP_SCATTERING       0.8
    #define WP_WAVE_HEIGHT      0.4
    #define WP_FOAM_AMOUNT      0.2
    #define WP_SPECULAR_INT     0.7
    #define WP_REFRACTION_STR   0.01
    #define WP_PRESET_NAME      "Murky"

#elif WATER_PRESET == WATER_PRESET_CUSTOM
    // Custom: User-defined via shaders.properties
    // These are placeholder values, actual values set by user
    #define WP_ABSORPTION_R     0.015
    #define WP_ABSORPTION_G     0.012
    #define WP_ABSORPTION_B     0.008
    #define WP_SCATTERING       0.35
    #define WP_WAVE_HEIGHT      0.8
    #define WP_FOAM_AMOUNT      0.5
    #define WP_SPECULAR_INT     1.0
    #define WP_REFRACTION_STR   0.02
    #define WP_PRESET_NAME      "Custom"

#else
    // Fallback to Natural
    #define WP_ABSORPTION_R     0.015
    #define WP_ABSORPTION_G     0.012
    #define WP_ABSORPTION_B     0.008
    #define WP_SCATTERING       0.35
    #define WP_WAVE_HEIGHT      0.8
    #define WP_FOAM_AMOUNT      0.5
    #define WP_SPECULAR_INT     1.0
    #define WP_REFRACTION_STR   0.02
    #define WP_PRESET_NAME      "Natural (Default)"
#endif

// ============================================================================
// Backward Compatibility Layer
// ============================================================================
// For legacy configs that used old water settings

#ifdef LEGACY_WATER_MODE
    #ifdef WATER_DARK
        #undef WATER_PRESET
        #define WATER_PRESET WATER_PRESET_DEEP
    #elifdef WATER_TROPICAL
        #undef WATER_PRESET
        #define WATER_PRESET WATER_PRESET_TURQUOISE
    #endif
#endif

// ============================================================================
// Helper Functions
// ============================================================================

// Get absorption color based on depth
vec3 getWaterAbsorption(float depth) {
    return vec3(
        exp(-WP_ABSORPTION_R * depth),
        exp(-WP_ABSORPTION_G * depth),
        exp(-WP_ABSORPTION_B * depth)
    );
}

// Get scattering color
vec3 getWaterScattering(vec3 lightColor) {
    return lightColor * WP_SCATTERING;
}

#endif // WATER_PRESET_SETTINGS
