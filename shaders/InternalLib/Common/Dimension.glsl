// InternalLib/Common/Dimension.glsl
// Phase 5: Dimension-specific atmosphere parameters.
//
// The pack detects dimensions via per-dimension program folders, each of
// which defines one of DIM_OVERWORLD / DIM_NETHER / DIM_END at the top of
// every translation unit (see DimOverworld/, DimNether/, DimEnd/).
//
// Mod dimensions (Twilight Forest, Aether, Ad Astra) require dedicated
// dimension program folders registered in dimension.properties before these
// parameters can take effect; they currently fall back to Overworld values.

#ifndef _DIMENSION_GLSL_
#define _DIMENSION_GLSL_

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

DimensionParams getDimensionParams() {
    DimensionParams params;

#if defined(DIM_NETHER)
    params.skyColor           = vec3(0.3, 0.1, 0.1);
    params.fogColor           = vec3(0.5, 0.2, 0.1);
    params.ambientBrightness  = 0.4;
    params.cloudHeight        = 0.0;
    params.hasAtmosphere      = true;
    params.atmosphereColor    = vec3(1.0, 0.5, 0.3);
    params.sunColor           = vec3(0.0);
    params.moonColor          = vec3(0.0);
#elif defined(DIM_END)
    params.skyColor           = vec3(0.6, 0.5, 0.8);
    params.fogColor           = vec3(0.8, 0.7, 0.9);
    params.ambientBrightness  = 0.6;
    params.cloudHeight        = 0.0;
    params.hasAtmosphere      = false;
    params.atmosphereColor    = vec3(0.0);
    params.sunColor           = vec3(0.0);
    params.moonColor          = vec3(0.0);
#else
    // DIM_OVERWORLD and any unrecognized dimension (mod dimensions fall back here)
    params.skyColor           = vec3(0.5, 0.7, 1.0);
    params.fogColor           = vec3(0.8, 0.9, 1.0);
    params.ambientBrightness  = 1.0;
    params.cloudHeight        = 200.0;
    params.hasAtmosphere      = true;
    params.atmosphereColor    = vec3(1.0, 0.95, 0.9);
    params.sunColor           = vec3(1.0, 0.95, 0.85);
    params.moonColor          = vec3(0.9, 0.95, 1.0);
#endif

    return params;
}

bool hasAtmosphere() {
#if defined(DIM_END)
    return false;
#else
    return true;
#endif
}

float getFogDensityMultiplier() {
#if defined(DIM_NETHER)
    return 2.5;
#elif defined(DIM_END)
    return 1.5;
#else
    return 1.0;
#endif
}

#endif // _DIMENSION_GLSL_
