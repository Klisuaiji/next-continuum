/*******************************************************************************
 - Volumetric Settings
 ******************************************************************************/

#define VC_MINIMUM 10
#define VC_LOW 16
#define VC_MEDIUM 32
#define VC_HIGH 48
#define VC_ULTRA 64
#define VC_CINEMATIC 128

#define VOLUMETRIC_CLOUDS
#define VOLUMETRIC_CLOUDS_QUALITY VC_MEDIUM // [VC_MINIMUM VC_LOW VC_MEDIUM VC_HIGH VC_ULTRA VC_CINEMATIC]

#define VOLUMETRIC_CLOUDS_DENSITY 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0]
#define VOLUMETRIC_CLOUDS_COVERAGE 0.2 // [0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define VOLUMETRIC_CLOUDS_COVERAGE_RAIN 0.35 // [0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define VOLUMETRIC_CLOUDS_SCALE 2.5 // [0.25 0.5 1.0 1.5 2.0 2.5 3.0 5.0]

#define VOLUMETRIC_CLOUDS_SPEED 0.01 // [0.0 0.01 0.02 0.03 0.04 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]

#define VOLUMETRIC_CLOUDS_ALTITUDE 200 // [60 70 80 90 100 160 200 260 300 350 400 450 500 550 600 650 700 750 800 1600]
#define VOLUMETRIC_CLOUDS_HEIGHT 0.55 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0]
#define VOLUMETRIC_CLOUDS_FALLOFF 0.00045 // [0.0003 0.0006 0.0009 0.0014 0.0016]
#define VOLUMETRIC_CLOUDS_ATTACK 0.015 // [0.1 0.2 0.4 0.6 0.8 1.1 1.2]

#define VOLUMETRIC_CLOUDS_MIN_TRANSMITTANCE 0.2
#define VOLUMETRIC_CLOUDS_MIN_TRANSMITTANCE_SUN 0.1

#define VOLUMETRIC_CLOUDS_WIND_DIR vec3(1.0, 0.0, 1.0)
#define VOLUMETRIC_CLOUDS_NOISE_OCTAVES 1

#define VC_LOCAL_COVERAGE

#define VCL_LOW 5
#define VCL_MEDIUM 10
#define VCL_HIGH 15

#define VOLUMETRIC_CLOUDS_DIRECT_QUALITY VCL_MEDIUM // [VCL_LOW VCL_MEDIUM VCL_HIGH]
#define VOLUMETRIC_CLOUDS_INDIRECT_QUALITY VCL_LOW // [VCL_LOW VCL_MEDIUM VCL_HIGH]

#define VCS_MINIMUM 2
#define VCS_LOW 3
#define VCS_MEDIUM 3
#define VCS_HIGH 5
#define VCS_ULTRA 7
#define VCS_CINEMATIC 9

// --- 2.1.3 新体云增强（VOLUMETRIC_CLOUDS_V2）：自适应非线性步长 + 多重散射 + 改进 powder。
// 默认关：取消下一行注释即在 [CLOUDS] 菜单开启；关闭时完全走旧体云，零回归。
//#define VOLUMETRIC_CLOUDS_V2
#define VC2_MULTISCAT_TERMS 4 // [2 3 4 5 6]
#define VC2_MULTISCAT_G_DECAY 0.5
#define VC2_MULTISCAT_ENERGY 0.5
#define VC2_FORWARD_G 0.8
#define VC2_BACKWARD_G -0.5
#define VC2_MIX_G 0.5
#define VC2_STEP_POWER 2.0 // [1.5 2.0 2.5 3.0]
#define VOLUMETRIC_CLOUDS_SHADOWS
#define CLOUD_SHADOWMAP_RADIUS 2048

#ifdef VOLUMETRIC_CLOUDS_SHADOWS 
#endif

const float cloudAltitude = VOLUMETRIC_CLOUDS_ALTITUDE;
const float cloudScale = cloudAltitude / 1600.0;
const float cloudHeight = 3000.0 * cloudScale * VOLUMETRIC_CLOUDS_HEIGHT;
const float cloudCoverage = VOLUMETRIC_CLOUDS_COVERAGE;
const float cloudDensity = 0.015 / cloudScale * VOLUMETRIC_CLOUDS_DENSITY;

#define CLOUDS_TIME (TIME * VOLUMETRIC_CLOUDS_SPEED)

/*******************************************************************************
 - Volumetric Fog Settings
 ******************************************************************************/

#define VL_MINIMUM 8
#define VL_LOW 16
#define VL_MEDIUM 32
#define VL_HIGH 64
#define VL_ULTRA 128
#define VL_CINEMATIC 256

#define WATER_VL_MINIMUM 2
#define WATER_VL_LOW 4
#define WATER_VL_MEDIUM 8
#define WATER_VL_HIGH 16
#define WATER_VL_ULTRA 32
#define WATER_VL_CINEMATIC 64

#define VOLUMETRIC_LIGHT
#define VL_QUALITY VL_MEDIUM // [VL_MINIMUM VL_LOW VL_MEDIUM VL_HIGH VL_ULTRA VL_CINEMATIC]

#define WATER_VOLUMETRIC_LIGHT
#define WATER_VL_QUALITY WATER_VL_LOW // [VL_MINIMUM VL_LOW VL_MEDIUM VL_HIGH VL_ULTRA VL_CINEMATIC]

#define DISTANCE_FADE

//#define VL_COLOURED_SHADOW

#define FOG_DENSITY_RAYLEIGH 200.0 // [0.0 20.0 40.0 60.0 80.0 100.0 120.0 140.0 160.0 180.0 200.0 220.0 240.0 260.0 280.0 300.0 320.0 340.0 360.0 380.0 400.0 420.0 440.0 460.0 480.0 500.0]
#define FOG_DENSITY_MIE_AMBIENT 200.0 // [0.0 20.0 40.0 60.0 80.0 100.0 120.0 140.0 160.0 180.0 200.0 220.0 240.0 260.0 280.0 300.0 320.0 340.0 360.0 380.0 400.0 420.0 440.0 460.0 480.0 500.0]
#define RAIN_CLOUD_DENSITY 50000.0 // [10000.0 15000.0 20000.0 25000.0 50000.0 100000.0]
#define FOG_DENSITY_AMBIENT_FALLOFF 0.35 // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define FOG_DENSITY_AMBIENT_BASE_HEIGHT 63 // [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100]
#define FOG_MORNING_BASE_HEIGHT 63 // [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100]
#define FOG_MORNING_DENSITY 5000 // [0 250 500 750 1000 1250 1500 1750 2000 2250 2500 2750 3000 3250 3500 3750 4000 4250 4500 4750 5000 5250 5500 5750 6000 6250 6500 6750 7000 7250 7500 7750 8000 8250 8500 8750 9000 9250 9500 9750 10000]
#define FOG_MORNING_FALLOFF 0.75 // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define NETHER_FOG_DENSITY_GLOBAL 1.0 // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define NETHER_FOG_DENSITY_MIE 500.0 // [0.0 100.0 200.0 300.0 400.0 500.0 600.0 700.0 800.0 900.0 1000.0]
#define NETHER_FOG_DENSITY_RAYLEIGH 0.0 // [0.0 100.0 200.0 300.0 400.0 500.0 600.0 700.0 800.0 900.0 1000.0]

#define END_FOG_DENSITY_GLOBAL 1.0 // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define END_FOG_DENSITY_MIE 1000.0 // [0.0 100.0 200.0 300.0 400.0 500.0 600.0 700.0 800.0 900.0 1000.0 2000.0]
#define END_FOG_DENSITY_RAYLEIGH 0.0 // [0.0 100.0 200.0 300.0 400.0 500.0 600.0 700.0 800.0 900.0 1000.0]
#define END_FOG_FALLOFF 0.02 // [0.00 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20]

#define LPV_FOG_STRENGTH_OVERWORLD 1.0 // [0.01 0.02 0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define LPV_FOG_STRENGTH_NETHER 0.1 // [0.01 0.02 0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define LPV_FOG_STRENGTH_END 0.5 // [0.01 0.02 0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]



#if defined DIM_OVERWORLD
    const mat2x3 airCoefficientsScattering  = mat2x3(atmosphere_coefficientRayleigh, atmosphere_coefficientMie);
    const mat2x3 airCoefficientsAttenuation = mat2x3(atmosphere_coefficientRayleigh * 0.2, atmosphere_coefficientMie); // Yeah...
    const float LPV_FOG_STRENGTH = LPV_FOG_STRENGTH_OVERWORLD;
#elif defined DIM_NETHER
    const mat2x3 airCoefficientsScattering  = mat2x3(vec3(1.0), atmosphere_coefficientMie);
    const mat2x3 airCoefficientsAttenuation = mat2x3(vec3(1.0), atmosphere_coefficientMie);
    const float LPV_FOG_STRENGTH = LPV_FOG_STRENGTH_NETHER;
#elif defined DIM_END 
    const mat2x3 airCoefficientsScattering  = mat2x3(vec3(1.0), atmosphere_coefficientMie);
    const mat2x3 airCoefficientsAttenuation = mat2x3(vec3(1.0), atmosphere_coefficientMie);
    const float LPV_FOG_STRENGTH = LPV_FOG_STRENGTH_END;
#endif

/*******************************************************************************
 - Water Settings
 ******************************************************************************/

#define WATER_DENSITY 1.0

const vec3 waterScatterCoefficient = vec3(0.1 * WATER_DENSITY);
const vec3 waterAbsorptionCoefficient = vec3(0.996078, 0.406863, 0.25098) * (0.75 * WATER_DENSITY);
const vec3 waterTransmittanceCoefficient = waterScatterCoefficient + waterAbsorptionCoefficient;
