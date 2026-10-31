/* Copyright (C) Continuum Graphics - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Joseph Conover <support@continuum.graphics>, January 2018
 */

#include "/InternalLib/Uniform/ShadowDistortion.glsl"
#include "/InternalLib/Fragment/Caustics.fsh"

vec3 TransmittedScatteringIntegral(const float opticalDepth, const vec3 coeff) {
    const vec3 a = -coeff / log(2.0);
    const vec3 b = -1.0 / coeff;
    const vec3 c =  1.0 / coeff;

    return exp2(a * opticalDepth * rLOG2) * b + c;
}

float TransmittedScatteringIntegral(const float opticalDepth, const float coeff) {
    const float a = -coeff / log(2.0);
    const float b = -1.0 / coeff;
    const float c =  1.0 / coeff;

    return exp2(a * opticalDepth * rLOG2) * b + c;
}

float CalculateSkyLightValue() {
	float lightValue = clamp01((eyeBrightnessSmooth.y * 0.00416666666666666666667) * 1.5 - 0.5);

	return lightValue * lightValue;
}

struct VolumetricData {
	vec3 sunlightColor;
	vec3 skylightColor;

	vec2 phases;
};

VolumetricData CalculateVolumetricVariables(vec3 viewVector, float VoL) {
	VolumetricData vd;
	vd.phases = vec2(sky_rayleighPhase(VoL), sky_miePhase(VoL, atmosphere_mieg));

	vd.sunlightColor = SceneData.sunColor;
	vd.skylightColor = SceneData.skyColor * CalculateSkyLightValue();

	return vd;
}

float CalculateRainOD(float centerDistance, const float pr) {
    float maxCenterDist = -max0(centerDistance - pr) * rLOG2;
    return exp2(maxCenterDist * 0.001) * 500.0 * wetness;
}

// Optical depths functions.
vec2 CalculateOpticalDepth(float height, float sunRise) {

	vec2 od = exp2(height * -atmosphere_inverseScaleHeights);
		 od.y += CalculateRainOD(height, 0.0);

	return od;
}

vec3 CalculateVolumetricShadowing(vec3 shadowPosition) {
	#ifndef VL_COLOURED_SHADOW
		float shadow = float(texture2D(shadowtex1, shadowPosition.xy).x > shadowPosition.z);

		return vec3(shadow);
	#endif

	float shadowSolid = float(texture2D(shadowtex1, shadowPosition.xy).x > shadowPosition.z);
	float shadowGlass = float(texture2D(shadowtex0, shadowPosition.xy).x > shadowPosition.z);

	vec4 shadowColor = texture2D(shadowcolor, shadowPosition.xy);
	vec4 shadowColor1 = texture2D(shadowcolor1, shadowPosition.xy);

	shadowColor.rgb = mix(shadowColor.rgb, vec3(1.0), (shadowColor1.a - 0.4) * 1.66666666666666667);

	return mix(vec3(shadowGlass), shadowColor.rgb, clamp01(shadowSolid - shadowGlass));
}

vec3 CalculateVolumetricShadows(vec3 shadowPosition, vec3 worldPosition, bool isWater) {
	shadowPosition.xy = DistortShadowSpaceProj(shadowPosition.xy);

	if (any(greaterThan(abs(shadowPosition), vec3(1.0)))) return vec3(1.0);

	vec3 sunVisibility = CalculateVolumetricShadowing(shadowPosition);
		 sunVisibility *= SampleCloudShadowMap(colortex10, worldPosition - cameraPosition);

	if(!isWater) return sunVisibility;

	float waterDepth = texture2D(shadowtex0, shadowPosition.xy).x * 8.0 - 4.0;
		  waterDepth = waterDepth * shadowProjectionInverse[2].z + shadowProjectionInverse[3].z;
		  waterDepth = (transMAD(shadowModelView, worldPosition - cameraPosition)).z - waterDepth;

	if(waterDepth >= 0.0) return sunVisibility;

	return sunVisibility * exp2(waterTransmittanceCoefficient * waterDepth * rLOG2);
}

#define partialWaterAbsorption \
	( exp2(-waterTransmittanceCoefficient * distFront * float(isEyeInWater == 1) * rLOG2) )

vec3 CalculateDistantWater(vec3 background, vec3 start, vec3 end) {
	float rayDistance = length(end - start);
	vec3 transmit = exp(-rayDistance * waterAbsorptionCoefficient);

	return background * transmit;
}


vec3 CalculateVolumetricWater(VolumetricData vd, vec3 background, vec3 start, vec3 end, float VoL, float dither) {
	#ifndef WATER_VOLUMETRIC_LIGHT
		return CalculateDistantWater(background, start, end);
	#endif

	const int steps    = WATER_VL_QUALITY;
	const float rSteps = 1.0 / steps;

	if (length(start.xz) > shadowDistance) {
		return CalculateDistantWater(background, start, end);
	}

	vec3 worldIncrement = (end - start) * rSteps;
	vec3 worldPosition  = dither * worldIncrement + start;
	     worldPosition += cameraPosition;

	float opticalDepth = length(worldIncrement);
	float phase = sky_miePhase(VoL, 0.5);

	vec3 scatterCoeff = waterScatterCoefficient * TransmittedScatteringIntegral(opticalDepth, waterAbsorptionCoefficient);
	vec3 stepTransmittance = exp2(waterTransmittanceCoefficient * -opticalDepth * rLOG2);

	vec3 shadowStart 	 = WorldSpaceToShadowSpace(start);
	vec3 shadowIncrement = (WorldSpaceToShadowSpace(end) - shadowStart) * rSteps;
	vec3 shadowPosition  = dither * shadowIncrement + shadowStart;

	vec3 scatter = vec3(0.0);
	vec3 transmittance = vec3(1.0);

	vd.sunlightColor *= SceneData.transitionFading;

	for(int i = 0; i < steps; ++i, worldPosition += worldIncrement, shadowPosition += shadowIncrement) {
		vec2 distortedShadowPos = DistortShadowSpaceProj(shadowPosition.xy);
		vec3 sunVisibility  = CalculateVolumetricShadows(shadowPosition, worldPosition, true);
			 sunVisibility *= RenderWaterCaustics(distortedShadowPos, abs(texture2D(shadowtex1, distortedShadowPos).x - texture2D(shadowtex0, distortedShadowPos).x) * 1024.0);

		scatter += (vd.sunlightColor * sunVisibility * phase + vd.skylightColor * 0.1) * transmittance * GetShadowBlendFactor(worldPosition - cameraPosition); // Need to add a sunlight phase back here.
		transmittance *= stepTransmittance;
	}

	scatter *= scatterCoeff;

	return max0(background * transmittance + scatter);
}
#undef partialWaterAbsorption
