/* Copyright (C) Continuum Graphics - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Joseph Conover <support@continuum.graphics>, Febuary 2018
 */

#include "/InternalLib/Misc/NoiseTexture.glsl"

const float rad = radians(105.0);

const mat2 rotateMatrix = mat2(
	cos(rad), -sin(rad),
	sin(rad),  cos(rad)
);

struct VolumetricCloudSettings {
	float minAltitude;
	float maxAltitude;
	float cloudHeight;
	float cloudCoverage;
	float cloudDensity;
	float cloudScale;
};

float remap(float value, const float originalMin, const float originalMax, const float newMin, const float newMax) {
	return (((value - originalMin) / (originalMax - originalMin)) * (newMax - newMin)) + newMin;
}

float powder(float sampleDensity, float VoL) {
	float powder = 1.0 - 0.97 * exp(-sampleDensity);
		  powder = mix(powder * 1.5, 0.8, VoL * 0.5 + 0.5);

	return powder;
}

//Mie constants
#define gMultiplierClouds 0.5
#define mixergClouds 0.9

float phaseg8(float x) {
	const float g = 0.8 * gMultiplierClouds;
	const float g2 = g * g;
	const float g3 = log2((g2 * -0.25 + 0.25) * mixergClouds);
	const float g4 = 1.0 + g2;
	const float g5 = -2.0 * g;

	return exp2(log2(g5 * x + g4) * -1.5 + g3);
}

float phasegm5(float x) {
	const float g = -0.5 * gMultiplierClouds;
	const float g2 = g * g;
	const float g3 = log2((g2 * -0.25 + 0.25) * (1.0 - mixergClouds));
	const float g4 = 1.0 + g2;
    const float g5 = -2.0 * g;

    return exp2(log2(g5 * x + g4) * -1.5 + g3);
}

float phase2lobes(float x) {
    return phaseg8(x) + phasegm5(x);
}

vec4 SampleNoise(sampler2D noiseSampler, vec2 coord) {
	return texture(noiseSampler, coord / float(noiseTextureResolution));
}

float CalculateDensityForLayer(
    vec3 worldPos, 
    const float densityMultiplier,
    const float baseAltitude, 
    const float coverageMultiplier, 
    const float coverageMultiplierRain,
    const float layerThickness,
	const bool isLowQ,
	int octaves,
    float positionScale
) {	
    const float topAltitude = baseAltitude + layerThickness;

    if (worldPos.y < baseAltitude || worldPos.y > topAltitude) return 0.0;

    float normalizedHeight = remap(worldPos.y, baseAltitude, topAltitude, 0.0, 1.0);

    vec2 windDir2D = normalize(VOLUMETRIC_CLOUDS_WIND_DIR.xz);
    vec2 pos2D = worldPos.xz / (positionScale * layerThickness);

	#ifdef DIM_END 
		float theta = atan(pos2D.x, pos2D.y);
		float r = length(pos2D);

		theta += r + TIME * 0.1;

		pos2D = vec2(r * cos(theta), r * sin(theta)); 
	#endif

    float baseNoise = SampleNoise(noisetex, pos2D - windDir2D * CLOUDS_TIME).g;
		  baseNoise += SampleNoise(noisetex, pos2D - windDir2D * CLOUDS_TIME).r;
		  baseNoise += SampleNoise(noisetex, pos2D * 2.0 - windDir2D * CLOUDS_TIME * 2.0).g;
		  baseNoise += SampleNoise(noisetex, pos2D * 2.0 - windDir2D * CLOUDS_TIME * 2.0).r;

	baseNoise /= 4.0;

    float fade = (1.0 - pow2(normalizedHeight));
    float localCoverage = 1.0;

    #if defined VC_LOCAL_COVERAGE
        localCoverage = texture(noisetex, (CLOUDS_TIME * 25.0 * VOLUMETRIC_CLOUDS_WIND_DIR.xz + worldPos.xz) * 1e-5 + 0.5).x;
        localCoverage = clamp01(localCoverage * 3.0 - 0.75 + wetness) * 0.5 + 0.5;
    #endif

	#ifdef DIM_END
		localCoverage *= 2.0;
	#endif

    float coverage = mix(coverageMultiplier, coverageMultiplierRain, wetness) * fade * localCoverage;
    float cloudBase = clamp01(baseNoise - (0.65 - coverage));

	// Early out.
    if (cloudBase <= 0.01) return 0.0;
	if (isLowQ) octaves = 0;

    vec3 windDir3D = 10.0 * normalize(VOLUMETRIC_CLOUDS_WIND_DIR) * positionScale;
    vec3 pos3D = 5.0 * worldPos / layerThickness - windDir3D * CLOUDS_TIME;

    vec3 curlNoise = texture(curlNoiseTex, pos3D * 0.1).xyz;
    float worleyMix = normalizedHeight + 0.5;

    vec2 noiseSample = texture(cloudNoiseTex, pos3D * 0.07).xy * 0.5;
		 noiseSample += texture(cloudNoiseTex, pos3D * 0.1).xy * 0.7;

	float detailNoise = noiseSample.x * (0.5 + 0.25 * (1.0 - worleyMix)) + noiseSample.y * worleyMix * 2.0;

    for (int i = 0; i < octaves; i++) {
		// Scale down successive octaves.
        pos3D *= PI; 
        pos3D.xz *= rotateMatrix;
        windDir3D *= PI; 
        windDir3D.xz *= rotateMatrix;

		// Make the smaller octaves move faster. 
		vec3 wind = windDir3D * i * CLOUDS_TIME;

		// Decrease weight for successive octaves. 
        curlNoise = texture(curlNoiseTex, (pos3D - wind) * 0.25).xyz * exp(-i) * 0.05;
        detailNoise += texture(cloudNoiseTex, (pos3D - wind) * 0.05 + curlNoise).x * exp(-i) * 0.5;
    }

    detailNoise = max0(detailNoise - 0.8);

	// Erode
    float cloudDensity = clamp01(cloudBase - detailNoise * 0.15);
    cloudDensity *= pow2(normalizedHeight * PI);

    return cloudDensity * densityMultiplier * 5.0;
}

float GetVolumetricClouds(vec3 position, const VolumetricCloudSettings vcs, const bool isLowQ) {
	return CalculateDensityForLayer(position, vcs.cloudDensity, vcs.minAltitude, vcs.cloudCoverage, VOLUMETRIC_CLOUDS_COVERAGE_RAIN, vcs.cloudHeight, isLowQ, VOLUMETRIC_CLOUDS_NOISE_OCTAVES, VOLUMETRIC_CLOUDS_SCALE);
}

float CalculateCloudSunVisibility(vec3 position, const VolumetricCloudSettings vcs, const int steps, const bool useDitheredSunlight, const bool useSimplifiedShaping) {
	float stepSize = vcs.cloudHeight / steps;

	vec3 increment = SceneData.wLightVector * stepSize;

	if (useDitheredSunlight)
		position += hash33(position).x * increment;

	float transmittance = 1.0;

	for (int i = 0; i < steps; i++) {
		position += increment;
		float opticalDepth = GetVolumetricClouds(position, vcs, useSimplifiedShaping);
		float stepTransmittance = exp(-opticalDepth);

		transmittance *= stepTransmittance;

		if (transmittance < VOLUMETRIC_CLOUDS_MIN_TRANSMITTANCE_SUN) break;
	}

	transmittance = clamp01(remap(transmittance, VOLUMETRIC_CLOUDS_MIN_TRANSMITTANCE_SUN, 1.0, 0.0, 1.0));

	return transmittance;
}

float CalculateCloudSkyVisibility(vec3 position, const VolumetricCloudSettings vcs, const bool useSimplifiedShaping) {
	const int steps = 32;
	float stepSize = vcs.cloudHeight / steps;

	vec3 increment = vec3(0.0, 1.0, 0.0) * stepSize;

	float transmittance = 1.0;

	for (int i = 0; i < steps; i++) {
		position += increment;
		float opticalDepth = GetVolumetricClouds(position, vcs, useSimplifiedShaping);
		float stepTransmittance = exp(-opticalDepth * 0.075);

		transmittance *= stepTransmittance;

		if (transmittance < VOLUMETRIC_CLOUDS_MIN_TRANSMITTANCE_SUN) break;
	}

	transmittance = clamp01(remap(transmittance, VOLUMETRIC_CLOUDS_MIN_TRANSMITTANCE_SUN, 1.0, 0.0, 1.0));

	return transmittance;
}

vec2 CalculateCloudScattering(vec3 position, float phase, float VoL, const VolumetricCloudSettings vcs, float odSample, const int dirLightSteps, const bool useDitheredSunlight, const bool useSimplifiedShaping) {
	float sunLighting    = CalculateCloudSunVisibility(position, vcs, dirLightSteps, useDitheredSunlight, useSimplifiedShaping) * powder(odSample, VoL) * phase * PI * 2.0;
	float skyLighting    = CalculateCloudSkyVisibility(position, vcs, useSimplifiedShaping) * phaseg0 * PI;

	return vec2(sunLighting, skyLighting);
}

vec4 CalculateVolumetricClouds(
	vec3 worldVector,
	float depth, 
	float dither, 
	float terrainDistance,
	const int steps, 
	const int dirLightSteps, 
	const bool useDitheredSunlight,
	const bool useSimplifiedShaping
) {
	float transmittance = 1.0;
	vec2 scattering = vec2(0.0);

	#ifndef VOLUMETRIC_CLOUDS
		return vec4(0.0, 0.0, 1.0, 1e9);
	#endif

	const float maxAltitude = cloudAltitude + cloudHeight;
	const float cloudScale = cloudAltitude / 1600.0;
	const VolumetricCloudSettings vcs = VolumetricCloudSettings(cloudAltitude, maxAltitude, cloudHeight, cloudCoverage, cloudDensity, cloudScale); // useless. why.

	float VoL = dot(worldVector, SceneData.wLightVector);
	float phase = phase2lobes(VoL);
	float rSteps = 1.0 / steps;

	vec2 planetIntersection = rsi(vec3(0.0, atmosphere_planetRadius + cameraPosition.y, 0.0), worldVector, atmosphere_planetRadius);
 	vec2 outerIntersection = rsi(vec3(0.0, atmosphere_planetRadius + cameraPosition.y, 0.0), worldVector, atmosphere_planetRadius + vcs.maxAltitude);
	if (outerIntersection.y <= 0.0) return vec4(0.0, 0.0, 1.0, 1e9);
    vec2 innerIntersection = rsi(vec3(0.0, atmosphere_planetRadius + cameraPosition.y, 0.0), worldVector, atmosphere_planetRadius + vcs.minAltitude);

	if (planetIntersection.x > 0.0 && cameraPosition.y < vcs.minAltitude) return vec4(0.0, 0.0, 1.0, 1e9);

	// If the player is inside the cloud volume, switch raymarching strategy.
	float startDistance = cameraPosition.y < vcs.minAltitude ? innerIntersection.y : outerIntersection.x;
	float endDistance = cameraPosition.y < vcs.minAltitude ? outerIntersection.y : innerIntersection.x;
		  startDistance = cameraPosition.y > vcs.minAltitude && cameraPosition.y < vcs.maxAltitude ? 0.0 : startDistance;
		  endDistance = cameraPosition.y > vcs.minAltitude && cameraPosition.y < vcs.maxAltitude ? (innerIntersection.y >= 0.0 ? innerIntersection.x : outerIntersection.y) : endDistance;
		  endDistance = cameraPosition.y > vcs.minAltitude && cameraPosition.y < vcs.maxAltitude ? min(endDistance, 2048.0) : endDistance;

	vec3 startPos = startDistance * worldVector;
	vec3 endPos = endDistance * worldVector;
	vec3 increment = (endPos - startPos) / steps;
	vec3 position = cameraPosition + startPos + increment * dither;

	float cloudDistance = length(endPos);

	// show(1.0)

	for (int i = 0; i < steps; i++, position += increment) {
		if (terrainDistance < length(position - cameraPosition) && depth < 1.0) break;

		float odSample = GetVolumetricClouds(position, vcs, useSimplifiedShaping) * vcs.cloudDensity * length(increment);
		float sampleTransmittance = exp2(-odSample * rLOG2);
		if (odSample <= 0.0) continue;

		vec2 cloudScattering = CalculateCloudScattering(position, phase, VoL, vcs, odSample, dirLightSteps, useDitheredSunlight, true);

		scattering += cloudScattering * (-transmittance * sampleTransmittance + transmittance);
		transmittance *= sampleTransmittance;

		if (transmittance <= VOLUMETRIC_CLOUDS_MIN_TRANSMITTANCE) {
			break;
		}
		
		cloudDistance = min(cloudDistance, length((position - cameraPosition)));
	}

	transmittance = clamp01(remap(transmittance, VOLUMETRIC_CLOUDS_MIN_TRANSMITTANCE, 1.0, 0.0, 1.0));

	return vec4(scattering, transmittance, cloudDistance);
}

float SampleCloudShadowMap(sampler2D cloudShadowTex, vec3 worldPos) {
	if (worldPos.y > cloudAltitude + cloudHeight) return 1.0;

	worldPos.y += cameraPosition.y;
    vec4 cloudPos = CloudTransforms.projectionMatrix * CloudTransforms.viewMatrix * vec4(worldPos, 1.0);
    float cloudSample = texture(cloudShadowTex, cloudPos.xy * 0.5 + 0.5).x;

    return cloudSample;
}

float SampleCloudShadowMap(sampler2D cloudShadowTex, vec3 worldPos, vec2 rand) {
	if (worldPos.y > cloudAltitude + cloudHeight) return 1.0;

	worldPos.y += cameraPosition.y;
    vec4 cloudPos = CloudTransforms.projectionMatrix * CloudTransforms.viewMatrix * vec4(worldPos, 1.0);
		 cloudPos.xy += rand * 0.005;
    float cloudSample = texture(cloudShadowTex, cloudPos.xy * 0.5 + 0.5).x;

    return cloudSample;
}

/* ============================================================
 * 2.1.3 新体云（VOLUMETRIC_CLOUDS_V2）
 * 自研重写，参考 2.1.3 volumetricClouds.glsl 的三项核心增量：
 *  1) 自适应非线性步长（近处密、远处疏，幂分布）
 *  2) 多重散射 Henyey-Greenstein 相位（VC2_MULTISCAT_TERMS 项）
 *  3) 改进 powder（深度增亮 x 高度项，云边缘增亮）
 * 复用本文件的密度 GetVolumetricClouds 与太阳/天空透光度 march，不新增 image。
 * ============================================================ */

// Henyey-Greenstein 相位（单 lobe）
float VC2PhaseG(float cosTheta, float g) {
    float gg = g * g;
    return rPI * (0.25 - 0.25 * gg) * pow(gg + 1.0 - 2.0 * g * cosTheta, -1.5);
}

// 多重散射相位：前/后双 lobe，逐次降低 g 并按能量衰减加权
float VC2MultiScatterPhase(float VoL) {
    float accum = 0.0;
    float cn = 1.0;
    for (int i = 0; i < VC2_MULTISCAT_TERMS; ++i) {
        float pF = VC2PhaseG(VoL, VC2_FORWARD_G  * cn);
        float pB = VC2PhaseG(VoL, VC2_BACKWARD_G * cn);
        accum += mix(pB, pF, VC2_MIX_G) * pow(VC2_MULTISCAT_ENERGY, float(i));
        cn *= VC2_MULTISCAT_G_DECAY;
    }
    return accum;
}

// 改进 powder：2.1.3 风格的深度增亮 x 高度项
float VC2Powder(float density, float normalizedHeight, float VoL) {
    float r = pow2(VoL * 0.5 + 0.5);
    float heightTerm = normalizedHeight * (1.0 - r) + r;
    float depthTerm = 1.0 - exp2(-density * 2.0 * rLOG2);
    return depthTerm * heightTerm;
}

vec2 CalculateCloudScatteringV2(
    vec3 position, float multiPhase, float VoL, const VolumetricCloudSettings vcs,
    float odSample, int dirLightSteps, float normalizedHeight
) {
    float sunVisibility = CalculateCloudSunVisibility(position, vcs, dirLightSteps, true, true);
    float skyVisibility = CalculateCloudSkyVisibility(position, vcs, true);

    float sunLighting = sunVisibility * VC2Powder(odSample, normalizedHeight, VoL) * multiPhase * PI * 2.0;
    float skyLighting = skyVisibility * VC2PhaseG(VoL, 0.0) * PI;

    return vec2(sunLighting, skyLighting);
}

vec4 CalculateVolumetricCloudsV2(
    vec3 worldVector, float depth, float dither, float terrainDistance,
    const int steps, const int dirLightSteps
) {
    #ifndef VOLUMETRIC_CLOUDS
        return vec4(0.0, 0.0, 1.0, 1e9);
    #endif

    float transmittance = 1.0;
    vec2 scattering = vec2(0.0);

    const float maxAltitude = cloudAltitude + cloudHeight;
    const float cloudScale = cloudAltitude / 1600.0;
    const VolumetricCloudSettings vcs = VolumetricCloudSettings(
        cloudAltitude, maxAltitude, cloudHeight, cloudCoverage, cloudDensity, cloudScale);

    float VoL = dot(worldVector, SceneData.wLightVector);
    float multiPhase = VC2MultiScatterPhase(VoL);

    // 与旧版一致的行星球面出入点（复用 rsi）
    vec2 planetIntersection = rsi(vec3(0.0, atmosphere_planetRadius + cameraPosition.y, 0.0), worldVector, atmosphere_planetRadius);
    vec2 outerIntersection  = rsi(vec3(0.0, atmosphere_planetRadius + cameraPosition.y, 0.0), worldVector, atmosphere_planetRadius + vcs.maxAltitude);
    if (outerIntersection.y <= 0.0) return vec4(0.0, 0.0, 1.0, 1e9);
    vec2 innerIntersection = rsi(vec3(0.0, atmosphere_planetRadius + cameraPosition.y, 0.0), worldVector, atmosphere_planetRadius + vcs.minAltitude);
    if (planetIntersection.x > 0.0 && cameraPosition.y < vcs.minAltitude) return vec4(0.0, 0.0, 1.0, 1e9);

    float startDistance = cameraPosition.y < vcs.minAltitude ? innerIntersection.y : outerIntersection.x;
    float endDistance   = cameraPosition.y < vcs.minAltitude ? outerIntersection.y : innerIntersection.x;
    startDistance = (cameraPosition.y > vcs.minAltitude && cameraPosition.y < vcs.maxAltitude) ? 0.0 : startDistance;
    endDistance   = (cameraPosition.y > vcs.minAltitude && cameraPosition.y < vcs.maxAltitude)
        ? min((innerIntersection.y >= 0.0 ? innerIntersection.x : outerIntersection.y), 2048.0) : endDistance;

    vec3 startPos = startDistance * worldVector;
    vec3 endPos   = endDistance * worldVector;
    float cloudDistance = length(endPos);

    // 自适应非线性步长：t 在 0..1 上取幂分布（近处密、远处疏）
    float N = float(steps);
    for (int i = 0; i < steps; ++i) {
        float t0 = pow(float(i)     / N, VC2_STEP_POWER);
        float t1 = pow(float(i + 1) / N, VC2_STEP_POWER);
        float tm = mix(t0, t1, dither);

        vec3 position = cameraPosition + mix(startPos, endPos, tm);

        // 地形遮挡：采样点越过不透明地形则停止
        if (terrainDistance < length(position - cameraPosition) && depth < 1.0) break;

        float stepLength = length(mix(startPos, endPos, t1) - mix(startPos, endPos, t0));
        float odSample = GetVolumetricClouds(position, vcs, true) * vcs.cloudDensity * stepLength;
        if (odSample <= 0.0) continue;

        float sampleTransmittance = exp2(-odSample * rLOG2);
        float normalizedHeight = clamp01((position.y - vcs.minAltitude) / vcs.cloudHeight);

        vec2 cloudScattering = CalculateCloudScatteringV2(
            position, multiPhase, VoL, vcs, odSample, dirLightSteps, normalizedHeight);

        scattering += cloudScattering * (transmittance - transmittance * sampleTransmittance);
        transmittance *= sampleTransmittance;

        if (transmittance <= VOLUMETRIC_CLOUDS_MIN_TRANSMITTANCE) break;
        cloudDistance = min(cloudDistance, length(position - cameraPosition));
    }

    transmittance = clamp01(remap(transmittance, VOLUMETRIC_CLOUDS_MIN_TRANSMITTANCE, 1.0, 0.0, 1.0));
    return vec4(scattering, transmittance, cloudDistance);
}
