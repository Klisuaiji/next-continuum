/* Copyright (C) Continuum Graphics - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Joseph Conover <support@continuum.graphics>, February 2018
 */

#define INFO 0 // [0 1]

#include "/UserLib/CameraSettings.glsl"
#include "/UserLib/ToningSettings.glsl"
#include "/UserLib/ParallaxSettings.glsl"
#include "/UserLib/LightingSettings.glsl"
#include "/UserLib/SkySettings.glsl"
#include "/UserLib/VolumetricSettings.glsl"
#include "/UserLib/WaterSettings.glsl"
#include "/UserLib/QuickFilterSettings.glsl"
// Phase 2: 视觉风格参数（依赖 QUICK_FILTER 兼容层，必须在 QuickFilterSettings 之后）
#include "/UserLib/VisualStyleSettings.glsl"
// Phase 2: 水体预设参数
#include "/UserLib/WaterPresetSettings.glsl"
// Phase 1: 高级功能开关（M1-M7）
#include "/UserLib/AdvancedSettings.glsl"