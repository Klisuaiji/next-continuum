// UserLib/WaterPresetSettings.glsl
#ifndef WATER_PRESET_SETTINGS
#define WATER_PRESET_SETTINGS

// ============================================================================
// Water Preset Settings (Phase 2)
// ============================================================================
// Water presets control optical properties: per-channel absorption,
// scattering, wave height, foam and refraction. Orthogonal to VISUAL_STYLE
// in VisualStyleSettings.glsl.
//
// STATUS: parameter tables defined; application points (water absorption in
// the water shading path, wave height in the Tessendorf/wave field path)
// are wired in a follow-up. WATER_PRESET defaults to NATURAL which matches
// the current hard-coded behavior, so including this file is safe.
// ============================================================================

#define WATER_PRESET_NATURAL     0  // Balanced, realistic water
#define WATER_PRESET_CLEAR       1  // Crystal clear tropical water
#define WATER_PRESET_DEEP        2  // Dark ocean depths
#define WATER_PRESET_TURQUOISE   3  // Turquoise tropical paradise
#define WATER_PRESET_MURKY       4  // Murky swamp water
#define WATER_PRESET_CUSTOM      5  // Reserved for user-defined parameters

#ifndef WATER_PRESET
    #define WATER_PRESET WATER_PRESET_NATURAL
#endif

#if WATER_PRESET == WATER_PRESET_CLEAR
    #define WP_ABSORPTION_R     0.008
    #define WP_ABSORPTION_G     0.010
    #define WP_ABSORPTION_B     0.012
    #define WP_SCATTERING       0.25
    #define WP_WAVE_HEIGHT      0.5
    #define WP_FOAM_AMOUNT      0.3
    #define WP_SPECULAR_INT     1.1
    #define WP_REFRACTION_STR   0.025

#elif WATER_PRESET == WATER_PRESET_DEEP
    #define WP_ABSORPTION_R     0.035
    #define WP_ABSORPTION_G     0.028
    #define WP_ABSORPTION_B     0.020
    #define WP_SCATTERING       0.5
    #define WP_WAVE_HEIGHT      1.2
    #define WP_FOAM_AMOUNT      0.7
    #define WP_SPECULAR_INT     0.9
    #define WP_REFRACTION_STR   0.015

#elif WATER_PRESET == WATER_PRESET_TURQUOISE
    #define WP_ABSORPTION_R     0.012
    #define WP_ABSORPTION_G     0.018
    #define WP_ABSORPTION_B     0.022
    #define WP_SCATTERING       0.4
    #define WP_WAVE_HEIGHT      0.6
    #define WP_FOAM_AMOUNT      0.4
    #define WP_SPECULAR_INT     1.15
    #define WP_REFRACTION_STR   0.028

#elif WATER_PRESET == WATER_PRESET_MURKY
    #define WP_ABSORPTION_R     0.045
    #define WP_ABSORPTION_G     0.038
    #define WP_ABSORPTION_B     0.025
    #define WP_SCATTERING       0.8
    #define WP_WAVE_HEIGHT      0.4
    #define WP_FOAM_AMOUNT      0.2
    #define WP_SPECULAR_INT     0.7
    #define WP_REFRACTION_STR   0.01

#else
    // NATURAL and CUSTOM fall back to the current hard-coded behavior.
    #define WP_ABSORPTION_R     0.015
    #define WP_ABSORPTION_G     0.012
    #define WP_ABSORPTION_B     0.008
    #define WP_SCATTERING       0.35
    #define WP_WAVE_HEIGHT      0.8
    #define WP_FOAM_AMOUNT      0.5
    #define WP_SPECULAR_INT     1.0
    #define WP_REFRACTION_STR   0.02
#endif

// ============================================================================
// Helper Functions
// ============================================================================

// Beer-Lambert absorption over a water path of the given length.
vec3 getWaterAbsorption(float depth) {
    return vec3(
        exp(-WP_ABSORPTION_R * depth),
        exp(-WP_ABSORPTION_G * depth),
        exp(-WP_ABSORPTION_B * depth)
    );
}

// In-scattered light color for the given incident light color.
vec3 getWaterScattering(vec3 lightColor) {
    return lightColor * WP_SCATTERING;
}

#endif // WATER_PRESET_SETTINGS
