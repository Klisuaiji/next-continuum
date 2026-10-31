#if !defined _AIR_VOLUME_COMMON_
#define _AIR_VOLUME_COMMON_

struct VolumetricData {
	vec3 sunlightColor;
	vec3 skylightColor;

	vec2 phases;
};

VolumetricData CalculateVolumetricVariables(float VoL) {
	VolumetricData vd;
	vd.phases = vec2(sky_rayleighPhase(VoL), sky_miePhase(VoL, 0.5));

	vd.sunlightColor = SceneData.sunColor;
	vd.skylightColor = SceneData.skyColor;

	return vd;
}

float CalculateRainOD(vec3 worldPos) {
	if (worldPos.y > VOLUMETRIC_CLOUDS_ALTITUDE) return 0.0;

	    // --- 2D base noise ---
    vec2 windDir2D = normalize(VOLUMETRIC_CLOUDS_WIND_DIR.xz);
    vec2 pos2D = worldPos.xz / (VOLUMETRIC_CLOUDS_SCALE * cloudHeight);

    float baseNoise = SampleNoise(noisetex, pos2D - windDir2D * CLOUDS_TIME).g;
		  baseNoise += SampleNoise(noisetex, pos2D - windDir2D * CLOUDS_TIME).r;
		  baseNoise += SampleNoise(noisetex, pos2D * 2.0 - windDir2D * CLOUDS_TIME * 2.0).g;
		  baseNoise += SampleNoise(noisetex, pos2D * 2.0 - windDir2D * CLOUDS_TIME * 2.0).r;

		  baseNoise /= 4.0;

	float localCoverage = 1.0;

    #ifdef VC_LOCAL_COVERAGE
        localCoverage = texture(noisetex, (CLOUDS_TIME * 25.0 + worldPos.xz) * 1e-5 + 0.5).x;
        localCoverage = clamp01(localCoverage * 3.0 - 0.75 + wetness) * 0.5 + 0.5;
    #endif

	float coverageFade = clamp01(exp(-0.005 * (VOLUMETRIC_CLOUDS_ALTITUDE - worldPos.y)));
	float coverage = mix(VOLUMETRIC_CLOUDS_COVERAGE, VOLUMETRIC_CLOUDS_COVERAGE_RAIN, wetness) * coverageFade * localCoverage;

    float cloudBase = clamp01(baseNoise - (0.7 - coverage));

	cloudBase *= (texture(cloudNoiseTex, worldPos * 0.004 + 10.0 *  CLOUDS_TIME * vec3(0.1, 1.0, 0.1)).r);

	return cloudBase * RAIN_CLOUD_DENSITY * wetness;
}

// Optical depths functions.
vec2 CalculateOpticalDepth(vec3 pos, float sunRise) {
	vec2 od = vec2(0.0);
		 od = vec2(clamp01(exp2(-pos.y * FOG_DENSITY_AMBIENT_FALLOFF + FOG_DENSITY_AMBIENT_BASE_HEIGHT))) * vec2(FOG_DENSITY_RAYLEIGH, FOG_DENSITY_MIE_AMBIENT);
		 od.y += clamp01(exp2(-pos.y * FOG_MORNING_FALLOFF + FOG_MORNING_BASE_HEIGHT)) * FOG_MORNING_DENSITY * sunRise;
		 od.y += CalculateRainOD(pos);

	return od;
}

vec2 CalculateNetherOD(vec3 pos) {
	pos.y -= TIME * 2.0;
	pos.xz += pos.y * 0.5;
	vec3 curl = texture(curlNoiseTex, pos * 0.005).rgb * 0.2;
	     curl += texture(curlNoiseTex, pos * 0.01).rgb * 0.1;
		 curl += texture(curlNoiseTex, pos * 0.05).rgb * 0.02;
	vec2 od = vec2(texture(cloudNoiseTex, pos * 0.02 * vec3(1.0, 0.0, 1.0) + curl + TIME * 0.02).r);
		 od = pow(od * 1.5, vec2(8.0));

	od *= vec2(NETHER_FOG_DENSITY_RAYLEIGH, NETHER_FOG_DENSITY_MIE);

	return od;
}

vec2 CalculateEndOD(vec3 pos) {
	vec3 curl = texture(curlNoiseTex, pos * 0.01).rgb * 0.2;
	vec2 od = vec2(texture(cloudNoiseTex, pos * 0.01 + curl + TIME * 0.01).r);
		 od = pow(od * 1.5, vec2(8.0)) + 0.5;

	od *= vec2(END_FOG_DENSITY_RAYLEIGH, END_FOG_DENSITY_MIE) * exp(-END_FOG_FALLOFF * max0(pos.y));

	return od;
}

vec3 RenderRainbow(float cosTheta) {
	vec3 rainbow = vec3(0.0);
	float x = clamp01(-cosTheta);

	rainbow += vec3(1.0, 0.0, 0.0) * clamp01(-1500 * pow(x - 0.5, 2.0) + 1);
	rainbow += vec3(1.0, 0.5, 0.0) * clamp01(-1500 * pow(x - 0.51, 2.0) + 1);
	rainbow += vec3(0.0, 1.0, 0.0) * clamp01(-1500 * pow(x - 0.52, 2.0) + 1);
	rainbow += vec3(0.0, 0.5, 1.0) * clamp01(-1500 * pow(x - 0.53, 2.0) + 1);
	rainbow += vec3(0.5, 0.0, 1.0) * clamp01(-1500 * pow(x - 0.54, 2.0) + 1);
	
	return rainbow * 0.2 * wetness;
}

vec3 GetLightningBoltContribution(vec3 position) {
	if (lightningBoltPosition.w < 1.0) return vec3(0.0);
	
	return 100000.0 * lightningBoltPosition.w * LIGHTNING_BOLT_LUMINANCE * GetLightColor(43).rgb / pow2(distance(lightningBoltPosition.xz, position.xz));
}

#endif // _AIR_VOLUME_COMMON_