#if !defined _AIR_MARCHER_
#define _AIR_MARCHER_

#include "/InternalLib/Common/AirVolume.glsl"
#include "/InternalLib/Common/Froxels.glsl"

void MarchAirVolume(inout vec3 scattering, inout vec3 transmittance, vec3 start, vec3 end, float dither) {
    scattering = vec3(0.0);
    transmittance = vec3(1.0);

    #ifndef VOLUMETRIC_LIGHT 
        return;
    #endif

    const int steps = 32;

    vec3 rayDir = normalize(end - start);
    float sunRise = clamp01((worldTime - 20000.0) / 600.0) + (1.0 - clamp01((worldTime - 200.0) / 1000.0));
    float VoL = dot(rayDir, SceneData.wLightVector);
    
	vec2 phase = sky_phase(VoL, 0.6);
		 phase.y = mix(phase.y, max(phase.y, 1.0 / PI), sunRise);

    const float dt = 1.0 / steps;
    float t = 0.0;
    for (int i = 0; i < steps; i++, t += dt) {
        vec3 rayPosition = rayDir * DistributeDepth(t);
        float stepLength = length(rayPosition - rayDir * DistributeDepth(t + dt));

        rayPosition += stepLength * (dither * 2.0 - 1.0);

        vec2 density = CalculateOpticalDepth(rayPosition + cameraPosition, sunRise);
        vec2 stepAirMass = density * stepLength;

        vec3 stepOpticalDepth = airCoefficientsAttenuation * stepAirMass;
        vec3 stepTransmittance = exp(-stepOpticalDepth);
        vec3 stepTransmittedFraction = clamp01((1.0 - stepTransmittance) / stepOpticalDepth);
        vec3 stepVisibleFraction = transmittance * stepTransmittedFraction;

        float cloudShadow = SampleCloudShadowMap(colortex10, rayPosition);

        scattering += airCoefficientsScattering * (stepAirMass * phase) * SceneData.sunColor * stepVisibleFraction * cloudShadow;
        scattering += airCoefficientsScattering * (stepAirMass * phaseg0) * (SceneData.skyColor + GetLightningBoltContribution(rayPosition)) * stepVisibleFraction;
        
        #ifdef REFLECT_LPV_INSIDE_FOG_VOLUME
            scattering += airCoefficientsScattering * stepAirMass * GetLPVContribution(lightPropagationVolume_r, rayPosition) * stepVisibleFraction * LPV_FOG_STRENGTH;
        #endif

        transmittance *= stepTransmittance;
    }
}

#endif // _AIR_MARCHER_