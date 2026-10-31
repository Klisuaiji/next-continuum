#if !defined _WATER_CAUSTICS_
#define _WATER_CAUSTICS_

float RenderWaterCaustics(vec2 shadowPosition, float waterDepth) {
	#ifndef CAUSTICS 
		return 1.0;
	#endif

	bool isWater = texture(shadowcolor1, shadowPosition).a >= 1.0;
	if (!isWater) return 1.0;

	float blendFactor = clamp01(waterDepth);

	float caustic = texture(shadowcolor, shadowPosition).r;
	return 2.0 * caustic * TAU * blendFactor + (1.0 - blendFactor);
}

#endif
