/*******************************************************************************
 - Quick Filter Settings (Phase 2 - Backward Compatibility Layer)
   One-click look presets that bundle water-wave and lighting effects.
   
   PHASE 2 UPDATE: Quick Filter functionality has been split into:
   - Visual Style Settings (VisualStyleSettings.glsl): Color grading presets
   - Water Preset Settings (WaterPresetSettings.glsl): Water optical properties
   
   For backward compatibility, setting QUICK_FILTER will automatically map
   to the corresponding VISUAL_STYLE. New configs should use the new system.
   
   Reference implementation: Continuum 2.1.3 style quick presets (自研重写).
 ******************************************************************************/

#define QUICK_FILTER_NATURAL 0
#define QUICK_FILTER_VIVID 1
#define QUICK_FILTER_CINEMATIC 2
#define QUICK_FILTER_MOODY 3
#define QUICK_FILTER_CLEAR_WATER 4

#define QUICK_FILTER QUICK_FILTER_NATURAL // [QUICK_FILTER_NATURAL QUICK_FILTER_VIVID QUICK_FILTER_CINEMATIC QUICK_FILTER_MOODY QUICK_FILTER_CLEAR_WATER]

// ============================================================================
// Backward Compatibility: Map QUICK_FILTER to VISUAL_STYLE
// ============================================================================
// If QUICK_FILTER is set to non-NATURAL, enable compat mode and map to
// the corresponding VISUAL_STYLE preset. WATER_PRESET remains independent.

#if QUICK_FILTER != QUICK_FILTER_NATURAL
    #define QUICK_FILTER_COMPAT_MODE
    #define LEGACY_WATER_MODE
#endif

// --- Effective water-wave parameters (preset-adjusted) ---
//  These expand to WATER_SPEED_MULT / WAVE_HEIGHT_MULT (injected globally by
//  the loader), so NATURAL == the user's slider values exactly.
#if QUICK_FILTER == QUICK_FILTER_VIVID
    #define QF_WATER_SPEED (WATER_SPEED_MULT * 1.25)
    #define QF_WAVE_HEIGHT (WAVE_HEIGHT_MULT * 1.30)
#elif QUICK_FILTER == QUICK_FILTER_CINEMATIC
    #define QF_WATER_SPEED (WATER_SPEED_MULT * 1.00)
    #define QF_WAVE_HEIGHT (WAVE_HEIGHT_MULT * 1.05)
#elif QUICK_FILTER == QUICK_FILTER_MOODY
    #define QF_WATER_SPEED (WATER_SPEED_MULT * 0.80)
    #define QF_WAVE_HEIGHT (WAVE_HEIGHT_MULT * 0.70)
#elif QUICK_FILTER == QUICK_FILTER_CLEAR_WATER
    #define QF_WATER_SPEED (WATER_SPEED_MULT * 0.50)
    #define QF_WAVE_HEIGHT (WAVE_HEIGHT_MULT * 0.45)
#else /* QUICK_FILTER_NATURAL */
    #define QF_WATER_SPEED WATER_SPEED_MULT
    #define QF_WAVE_HEIGHT WAVE_HEIGHT_MULT
#endif

// --- Effective lighting/color-grading offsets (deltas layered on sliders) ---
//  Only the delta is applied pre-tonemap in C7; the manual grading sliders
//  continue to be applied in Final.frag, so NATURAL produces zero change.
#if QUICK_FILTER == QUICK_FILTER_VIVID
    #define QF_SATURATION 0.15
    #define QF_CONTRAST   0.20
    #define QF_GAIN       0.05
    #define QF_EV         0.10
#elif QUICK_FILTER == QUICK_FILTER_CINEMATIC
    #define QF_SATURATION 0.00
    #define QF_CONTRAST   0.35
    #define QF_GAIN       0.00
    #define QF_EV        -0.05
#elif QUICK_FILTER == QUICK_FILTER_MOODY
    #define QF_SATURATION -0.05
    #define QF_CONTRAST   0.25
    #define QF_GAIN      -0.15
    #define QF_EV        -0.35
#elif QUICK_FILTER == QUICK_FILTER_CLEAR_WATER
    #define QF_SATURATION 0.05
    #define QF_CONTRAST   0.10
    #define QF_GAIN       0.05
    #define QF_EV         0.20
#else /* QUICK_FILTER_NATURAL */
    #define QF_SATURATION 0.0
    #define QF_CONTRAST   0.0
    #define QF_GAIN       0.0
    #define QF_EV         0.0
#endif
