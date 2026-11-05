// UserLib/VisualStyleSettings.glsl
#ifndef VISUAL_STYLE_SETTINGS
#define VISUAL_STYLE_SETTINGS

// ============================================================================
// Visual Style Settings - Independent from Performance Profile
// ============================================================================
// Visual styles control color grading, saturation, contrast, and mood
// This is separate from performance settings (LOW/MEDIUM/HIGH/EXTREME)
// ============================================================================

// Visual Style Presets
#define VISUAL_STYLE_NATURAL   0  // Balanced, true-to-life colors
#define VISUAL_STYLE_VIVID     1  // Enhanced saturation and contrast
#define VISUAL_STYLE_CINEMATIC 2  // Warm tones, film-like curve
#define VISUAL_STYLE_MOODY     3  // Desaturated, high contrast, dark
#define VISUAL_STYLE_NORDIC    4  // Cool tones, clear and crisp (NEW)
#define VISUAL_STYLE_NEUTRAL   5  // Faithful to vanilla Minecraft (NEW)

// Default visual style (can be overridden by shaders.properties)
#ifndef VISUAL_STYLE
    #define VISUAL_STYLE VISUAL_STYLE_NATURAL
#endif

// ============================================================================
// Style Parameters
// ============================================================================

#if VISUAL_STYLE == VISUAL_STYLE_NATURAL
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
    #define VS_STYLE_NAME       "Natural"

#elif VISUAL_STYLE == VISUAL_STYLE_VIVID
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
    #define VS_STYLE_NAME       "Vivid"

#elif VISUAL_STYLE == VISUAL_STYLE_CINEMATIC
    #define VS_SATURATION_MOD   0.9
    #define VS_CONTRAST_MOD     1.2
    #define VS_BRIGHTNESS_MOD   0.95
    #define VS_TINT_R           1.08
    #define VS_TINT_G           1.0
    #define VS_TINT_B           0.92
    #define VS_EXPOSURE_MOD     0.98
    #define VS_SHARPNESS        0.1
    #define VS_GRAIN            0.08
    #define VS_VIGNETTE         0.15
    #define VS_STYLE_NAME       "Cinematic"

#elif VISUAL_STYLE == VISUAL_STYLE_MOODY
    #define VS_SATURATION_MOD   0.7
    #define VS_CONTRAST_MOD     1.3
    #define VS_BRIGHTNESS_MOD   0.85
    #define VS_TINT_R           0.95
    #define VS_TINT_G           0.95
    #define VS_TINT_B           1.0
    #define VS_EXPOSURE_MOD     0.9
    #define VS_SHARPNESS        0.05
    #define VS_GRAIN            0.12
    #define VS_VIGNETTE         0.25
    #define VS_STYLE_NAME       "Moody"

#elif VISUAL_STYLE == VISUAL_STYLE_NORDIC
    // Nordic: Cold, clear atmosphere inspired by Nordic landscapes
    // Higher blue tint, lower saturation, crisp highlights
    #define VS_SATURATION_MOD   0.85
    #define VS_CONTRAST_MOD     1.1
    #define VS_BRIGHTNESS_MOD   1.05
    #define VS_TINT_R           0.92
    #define VS_TINT_G           0.98
    #define VS_TINT_B           1.08
    #define VS_EXPOSURE_MOD     1.02
    #define VS_SHARPNESS        0.2
    #define VS_GRAIN            0.0
    #define VS_VIGNETTE         0.05
    #define VS_STYLE_NAME       "Nordic"

#elif VISUAL_STYLE == VISUAL_STYLE_NEUTRAL
    // Neutral: Faithful to vanilla Minecraft appearance
    // Minimal color grading, vanilla-like tone mapping
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
    #define VS_STYLE_NAME       "Neutral"

#else
    // Fallback to Natural
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
    #define VS_STYLE_NAME       "Natural (Default)"
#endif

// ============================================================================
// Backward Compatibility Layer
// ============================================================================
// Maps old QUICK_FILTER values to new VISUAL_STYLE for legacy configs

#ifdef QUICK_FILTER_COMPAT_MODE
    #if QUICK_FILTER == 0
        #undef VISUAL_STYLE
        #define VISUAL_STYLE VISUAL_STYLE_NATURAL
    #elif QUICK_FILTER == 1
        #undef VISUAL_STYLE
        #define VISUAL_STYLE VISUAL_STYLE_VIVID
    #elif QUICK_FILTER == 2
        #undef VISUAL_STYLE
        #define VISUAL_STYLE VISUAL_STYLE_CINEMATIC
    #elif QUICK_FILTER == 3
        #undef VISUAL_STYLE
        #define VISUAL_STYLE VISUAL_STYLE_MOODY
    #endif
#endif

#endif // VISUAL_STYLE_SETTINGS
