/*******************************************************************************
 - 2D Clouds Settings
 ******************************************************************************/

#define CLOUDS_2D
#define CLOUDS_2D_DENSITY 3.0 //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define CLOUDS_2D_COVERAGE 0.8 // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

/*******************************************************************************
 - Sky Constants
 ******************************************************************************/

#define sky_atmosphereHeight 8228.0 // Physically-based thickness of the atmosphere.
#define sky_earthRadius 6371000.0 // Physically-based radius of the Earth.
#define sky_mieMultiplier 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define sky_ozoneMultiplier 1.0 // 1.0 for physically-based. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define sky_rayleighDistribution 8.0 // Physically-based.
#define sky_mieDistribution 1.2 // Physically-based.
#define sky_sunLuminanceBase 10000.0 // Not physically based. [80000 85000 90000 95000 100000 107000 110000 120000 130000 140000]
#define sky_moonLuminanceBase 20.0 // Not Physically-based. [0.0 0.1 0.2 0.3 0.318 0.4 0.5 0.6 0.7 0.8 0.9 1.0 10.0 20.0 50.0 100.0]
#define sky_sunColorTemperature 5900 // [4000 4500 5000 5500 6000 6500 7000]
#define sky_moonColorTemperature 10000 // [4500 5000 5500 6000 6500 7000 7500 8000 8500]
#define sky_ozoneHeight 30000.0 // Physically-based (Kutz).
#define sky_ozoneCoefficient ( vec3(3.426, 8.298, 0.356) * 6.0e-7 * sky_ozoneMultiplier ) // Physically-based (Kutz).
#define sky_mieCoefficient ( 3.0e-6 * sky_mieMultiplier ) // Good default.

const float sunAngularSize = 0.545;
const float moonAngularSize = 0.545;

const float atmosphere_planetRadius = 6731e3; // Should probably move this to somewhere else.

const vec2  atmosphere_scaleHeights     = vec2(8.0e3, 1.2e3);
const float atmosphere_atmosphereHeight = 110e3;

const float atmosphere_mieg = 0.77;

const float airNumberDensity       = 2.6867774e19; // Couldn't find it for air, so just using value for an ideal gas. Not sure how different it is for actual air.
const float ozoneConcentrationPeak = 8e-6;
const float ozoneNumberDensity     = airNumberDensity * ozoneConcentrationPeak;
const vec3  ozoneCrossSection      = vec3(4.51103766177301E-21, 3.2854797958699E-21, 1.96774621921165E-22);

#if defined DIM_OVERWORLD
    // I HATE MESA FFS WHY
    /* const */ vec3 sky_sunColor =  (blackbody(sky_sunColorTemperature) * sky_sunLuminanceBase);
    /* const */ vec3 sky_moonColor = (blackbody(sky_moonColorTemperature)* sky_moonLuminanceBase);

    const vec3 atmosphere_coefficientRayleigh = vec3(4.593e-6, 1.097e-5, 2.716e-5);
    const vec3 atmosphere_coefficientOzone    = ozoneCrossSection * ozoneNumberDensity;
    const vec3 atmosphere_coefficientMie      = vec3(2.500e-6); // Should be >= 2e-6, depends heavily on conditions. Current value is just one that looks good.
#elif defined DIM_END
    const vec3 sky_sunColor = END_LIGHTING_COLOR * 50.0;
    const vec3 sky_moonColor = (blackbody(sky_moonColorTemperature)* sky_moonLuminanceBase);

    const vec3 atmosphere_coefficientRayleigh = vec3(6.43334e-6, 1.08737e-5, 2.48614e-5);
    const vec3 atmosphere_coefficientOzone    = ozoneCrossSection * ozoneNumberDensity;
    const vec3 atmosphere_coefficientMie      = vec3(100.500e-6);
#elif defined DIM_NETHER 
    const vec3 sky_sunColor = NETHER_LIGHTING_COLOR * 10.0;
    const vec3 sky_moonColor = NETHER_LIGHTING_COLOR * 10.0;

    const vec3 atmosphere_coefficientRayleigh = vec3(6.43334e-6, 1.08737e-5, 2.48614e-5);
    const vec3 atmosphere_coefficientOzone    = ozoneCrossSection * ozoneNumberDensity;
    const vec3 atmosphere_coefficientMie      = vec3(100.500e-6);
#endif

// The rest of these constants are set based on the above constants
const vec2  atmosphere_inverseScaleHeights     = 1.0 / atmosphere_scaleHeights;
const vec2  atmosphere_scaledPlanetRadius      = atmosphere_planetRadius * atmosphere_inverseScaleHeights;
const float atmosphere_atmosphereRadius        = atmosphere_planetRadius + atmosphere_atmosphereHeight;
const float atmosphere_atmosphereRadiusSquared = atmosphere_atmosphereRadius * atmosphere_atmosphereRadius;

const mat2x3 atmosphere_coefficientsScattering  = mat2x3(atmosphere_coefficientRayleigh, atmosphere_coefficientMie);
const mat3   atmosphere_coefficientsAttenuation = mat3(atmosphere_coefficientRayleigh, atmosphere_coefficientMie * 1.11, atmosphere_coefficientOzone); // commonly called the extinction coefficient

#define phaseg0 0.25

// ( Riley, Ebert, Kraus )
//#define sky_rayleighCoefficient vec3(5.8e-6  , 1.35e-5 , 3.31e-5 )
// ( Bucholtz )
//#define sky_rayleighCoefficient vec3(4.847e-6, 1.149e-5, 2.87e-5 )
// ( Thalman, Zarzana, Tolbert, Volkamer )
//#define sky_rayleighCoefficient vec3(5.358e-6, 1.253e-5, 3.062e-5)
// ( Penndorf )
//#define sky_rayleighCoefficient vec3(5.178e-6, 1.226e-5, 3.06e-5)
// ( Jodie )
#define sky_rayleighCoefficient vec3(4.593e-6, 1.097e-5, 2.716e-5)
