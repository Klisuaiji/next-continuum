#if !defined _FROXEL_VOLUME_
#define _FROXEL_VOLUME_

#include "/InternalLib/Uniform/ShadowDistortion.glsl"
#include "/InternalLib/Common/AirVolume.glsl"

float CalculateSkyLightValue() {
	float lightValue = clamp01((eyeBrightnessSmooth.y * 0.00416666666666666666667) * 1.5 - 0.5);

	return lightValue * lightValue;
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

void GenerateFroxels(inout vec3 scattering, inout vec3 transmittance, vec3 worldPosition, ivec3 iPos) {
    float VoL = dot(normalize(worldPosition), SceneData.wLightVector);

    vec3 texSize = vec3(workGroups * gl_WorkGroupSize);

    float stepLength = length(
        FroxelSpaceToWorldSpace(vec3(iPos) / texSize) -
        FroxelSpaceToWorldSpace(vec3(iPos.x / texSize.x, iPos.y / texSize.y, (iPos.z + 1) / texSize.z))
    );

    worldPosition += normalize(worldPosition) * (BlueNoiseTemporal(blueNoiseTex, iPos.xy, frameCounter) * 2.0 - 1.0) * stepLength;

    float sunRise = clamp01((worldTime - 20000.0) / 600.0) + (1.0 - clamp01((worldTime - 200.0) / 1000.0));

    vec3 shadowPosition = WorldSpaceToShadowSpace(worldPosition);
	vec3 sunVisibility = CalculateVolumetricShadows(shadowPosition, worldPosition + cameraPosition, false);
	float skyVisibility = CalculateSkyLightValue();

	scattering = vec3(0.0);
	transmittance = vec3(1.0);

	vec2 phase = sky_phase(VoL, 0.6);
		 phase.y = mix(phase.y, max(phase.y, 1.0 / PI), sunRise);

	vec2 density = vec2(0.0);
	
	#ifdef DIM_OVERWORLD
		density = CalculateOpticalDepth(worldPosition + cameraPosition, sunRise).xy;
	#endif

	#ifdef DIM_NETHER
		density += CalculateNetherOD(worldPosition + cameraPosition);
	#endif

	#ifdef DIM_END
		density += CalculateEndOD(worldPosition + cameraPosition);
	#endif

	vec2 stepAirMass = density * stepLength;
	vec3 stepOpticalDepth = airCoefficientsAttenuation * stepAirMass;

	scattering += airCoefficientsScattering * (stepAirMass.xy * phase) * SceneData.sunColor * sunVisibility * skyVisibility;
	scattering += airCoefficientsScattering[1] * stepAirMass.y * SceneData.sunColor * RenderRainbow(VoL) * sunVisibility * skyVisibility; 
	scattering += airCoefficientsScattering * (stepAirMass.xy * phaseg0) * SceneData.skyColor * skyVisibility;
	scattering += airCoefficientsScattering * stepAirMass.xy * GetLPVContribution(lightPropagationVolume_r, worldPosition) * LPV_FOG_STRENGTH;
	scattering += airCoefficientsScattering * (stepAirMass.xy * phaseg0) * GetLightningBoltContribution(worldPosition);

	#if defined DIM_NETHER
		scattering += airCoefficientsScattering * (stepAirMass.xy * phaseg0) * AMBIENT_LUM_NETHER_TOTAL;
	#elif defined DIM_END
		scattering += airCoefficientsScattering * (stepAirMass.xy * phaseg0) * AMBIENT_LUM_END_TOTAL;
	#endif

	transmittance = stepOpticalDepth;
}


#endif