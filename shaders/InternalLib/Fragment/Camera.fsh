/* Copyright (C) Continuum Graphics - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Joseph Conover <support@continuum.graphics>, Febuary 2018
 */

#define AUTO_EXPOSURE_MIN_LUM_OVERWORLD 25.0
#define AUTO_EXPOSURE_MAX_LUM_OVERWORLD 1500.0

#define AUTO_EXPOSURE_MIN_LUM_NETHER 25.0
#define AUTO_EXPOSURE_MAX_LUM_NETHER 60.0

#define AUTO_EXPOSURE_MIN_LUM_END 60.0
#define AUTO_EXPOSURE_MAX_LUM_END 120.0

#if defined DIM_OVERWORLD 
    #define AUTO_EXPOSURE_MAX_LUM AUTO_EXPOSURE_MAX_LUM_OVERWORLD
    #define AUTO_EXPOSURE_MIN_LUM AUTO_EXPOSURE_MIN_LUM_OVERWORLD
#elif defined DIM_NETHER
    #define AUTO_EXPOSURE_MAX_LUM AUTO_EXPOSURE_MAX_LUM_NETHER
    #define AUTO_EXPOSURE_MIN_LUM AUTO_EXPOSURE_MIN_LUM_NETHER
#elif defined DIM_END 
    #define AUTO_EXPOSURE_MAX_LUM AUTO_EXPOSURE_MAX_LUM_END
    #define AUTO_EXPOSURE_MIN_LUM AUTO_EXPOSURE_MIN_LUM_END
#endif

float ComputeEV100(const float aperture2, const float shutterTime, const float ISO) {
    return log2(aperture2 / shutterTime * 100.0 / ISO);
}

float ComputeEV100Auto(float avgLuminance) {
    return log2(avgLuminance * 8.0);
}

float ConvertEV100ToExposure(float EV100) {
    return 0.833333 * exp2(-EV100);
}

float ComputeEV(float avgLuminance) {
    const float aperture  = CAMERA_APERTURE;
    const float aperture2 = aperture * aperture;
    const float shutterTime = 1.0 / CAMERA_SHUTTER_SPEED;
    const float ISO = CAMERA_ISO;
    const float EC = CAMERA_EV;

    #if CAMERA_MODE == CAMERA_MANUAL
        float EV100 = ComputeEV100(aperture2, shutterTime, ISO);
    #else
        float EV100 = ComputeEV100Auto(clamp(avgLuminance, AUTO_EXPOSURE_MIN_LUM, AUTO_EXPOSURE_MAX_LUM)); //Dolby Standard Clamp
    #endif

    return ConvertEV100ToExposure(EV100 - EC) * PI;
}
