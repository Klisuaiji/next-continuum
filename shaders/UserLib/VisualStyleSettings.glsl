// UserLib/VisualStyleSettings.glsl
#ifndef VISUAL_STYLE_SETTINGS
#define VISUAL_STYLE_SETTINGS

// ============================================================================
// Visual Style Settings (Phase 2)
// ============================================================================
// Visual styles control color grading: saturation, contrast, tint and mood.
// They are orthogonal to the performance profiles (LOW/MEDIUM/HIGH/EXTREME)
// and to WATER_PRESET in WaterPresetSettings.glsl.
//
// STATUS: parameter tables defined; application points (post-process grading
// in the final pass) are wired in a follow-up. VISUAL_STYLE defaults to
// NATURAL which is a numeric no-op (all modifiers 1.0), so including this
// file is safe before the application points land.
// ============================================================================

#define VISUAL_STYLE_NATURAL   0  // Balanced, true-to-life colors
#define VISUAL_STYLE_VIVID     1  // Enhanced saturation and contrast
#define VISUAL_STYLE_CINEMATIC 2  // Warm tones, film-like curve
#define VISUAL_STYLE_MOODY     3  // Desaturated, high contrast, dark
#define VISUAL_STYLE_NORDIC    4  // Cool tones, clear and crisp
#define VISUAL_STYLE_NEUTRAL   5  // Faithful to vanilla Minecraft

#ifndef VISUAL_STYLE
    #define VISUAL_STYLE VISUAL_STYLE_NATURAL
#endif

#if VISUAL_STYLE == VISUAL_STYLE_VIVID
    #define VS_SATURATION_MOD   1.25
    #define VS_CONTRAST_MOD     1.15
    #define VS_BRIGHTNESS_MOD   1.05
    #define VS_TINT_R           1.05
    #define VS_TINT_G           1.02
    #define VS_TINT_B           0.95
    #define VS_EXPOSURE_MOD     1.05
    #define VS_SHARPNESS        0.15
    #define VS_GRAIN            0.0
    #define VS_VIGNETTE         0.0

#elif VISUAL_STYLE == VISUAL_STYLE_CINEMATIC
    #define VS_SATURATION_MOD   0.90
    #define VS_CONTRAST_MOD     1.20
    #define VS_BRIGHTNESS_MOD   0.95
    #define VS_TINT_R           1.08
    #define VS_TINT_G           1.00
    #define VS_TINT_B           0.92
    #define VS_EXPOSURE_MOD     0.98
    #define VS_SHARPNESS        0.10
    #define VS_GRAIN            0.08
    #define VS_VIGNETTE         0.15

#elif VISUAL_STYLE == VISUAL_STYLE_MOODY
    #define VS_SATURATION_MOD   0.70
    #define VS_CONTRAST_MOD     1.30
    #define VS_BRIGHTNESS_MOD   0.85
    #define VS_TINT_R           0.95
    #define VS_TINT_G           0.95
    #define VS_TINT_B           1.00
    #define VS_EXPOSURE_MOD     0.90
    #define VS_SHARPNESS        0.05
    #define VS_GRAIN            0.12
    #define VS_VIGNETTE         0.25

#elif VISUAL_STYLE == VISUAL_STYLE_NORDIC
    #define VS_SATURATION_MOD   0.85
    #define VS_CONTRAST_MOD     1.10
    #define VS_BRIGHTNESS_MOD   1.05
    #define VS_TINT_R           0.92
    #define VS_TINT_G           0.98
    #define VS_TINT_B           1.08
    #define VS_EXPOSURE_MOD     1.02
    #define VS_SHARPNESS        0.20
    #define VS_GRAIN            0.0
    #define VS_VIGNETTE         0.05

#else
    // NATURAL and NEUTRAL are intentionally identical no-ops.
    #define VS_SATURATION_MOD   1.0
    #define VS_CONTRAST_MOD     1.0
    #define VS_BRIGHTNESS_MOD   1.0
    #define VS_TINT_R           1.0
    #define VS_TINT_G           1.0
    #define VS_TINT_B           1.0
    #define VS_EXPOSURE_MOD     1.0
    #define VS_SHARPNESS        0.0
    #define VS_GRAIN            0.0
    #define VS_VIGNETTE         0.0
#endif

// ============================================================================
// Backward Compatibility Layer
// ============================================================================
// Maps legacy QUICK_FILTER values (QuickFilterSettings.glsl) onto
// VISUAL_STYLE. Requires this file to be included AFTER QuickFilterSettings
// so QUICK_FILTER_COMPAT_MODE is already defined. WATER_PRESET remains
// independent of QUICK_FILTER.

#ifdef QUICK_FILTER_COMPAT_MODE
    #if QUICK_FILTER == QUICK_FILTER_VIVID
        #undef VISUAL_STYLE
        #define VISUAL_STYLE VISUAL_STYLE_VIVID
    #elif QUICK_FILTER == QUICK_FILTER_CINEMATIC
        #undef VISUAL_STYLE
        #define VISUAL_STYLE VISUAL_STYLE_CINEMATIC
    #elif QUICK_FILTER == QUICK_FILTER_MOODY
        #undef VISUAL_STYLE
        #define VISUAL_STYLE VISUAL_STYLE_MOODY
    #endif
    // QUICK_FILTER_CLEAR_WATER only touches water parameters, so VISUAL_STYLE
    // keeps its current value.
#endif

#endif // VISUAL_STYLE_SETTINGS
