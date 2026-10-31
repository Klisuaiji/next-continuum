/* Copyright (C) Continuum Graphics - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Joseph Conover <support@continuum.graphics>, Febuary 2018
 */

vec3 Raytrace(const vec3 viewSpaceDirection, const vec3 viewSpacePosition, vec3 p, float skyLightmap, bool isHand) {
	const float quality = RAYTRACE_QUALITY;
	int refines = RAYTRACE_REFINES;
	const float maxLength = 1.0 / quality;
	const float minLength = 0.1 / quality;

	float tempLength = -CameraTransforms.nearPlane - viewSpacePosition.z;

	// get screen space direction
	vec3 direction = normalize(ViewSpaceToScreenSpace(viewSpacePosition + viewSpaceDirection * tempLength) - p);
	float rz = 1.0 / abs(direction.z);

	vec3 skyReflection  = texture2D(colortex9, UnprojectSpherical(mat3(gbufferModelViewInverse) * -viewSpaceDirection)).rgb;
	     skyReflection *= pow2(skyLightmap);

	if (isHand) return skyReflection;

	float stepLength = minLength;
	float depth = p.z;
	
	int i = 0;

	while(depth >= p.z && i < RAYTRACE_QUALITY + 4) {
		i++;
		stepLength = clamp((depth - p.z) * rz, minLength, maxLength);
		p += direction * stepLength;
		if(clamp01(p) != p) return skyReflection; //early out when offscreen
		depth = texture2D(depthTexBack, p.xy).x;
	}

	while(--refines > 0) { // binary search
		vec3 reflectp = p + direction * clamp((depth - p.z) * rz, -stepLength, stepLength);
		float reflectdepth = texture2D(depthTexBack, reflectp.xy).x;
		bool isIntersect = reflectdepth < reflectp.z;

		p = isIntersect ? reflectp : p;
		depth = isIntersect ? reflectdepth : depth;

		stepLength *= 0.5;
	}

	vec3 reflection = DecodeRGBE8(texture2D(colortex2, p.xy));
		 reflection = SampleFroxels(reflection, p);
	
	bool visible = abs(p.z - depth) * min(rz, 400.0) <= maxLength;
	return visible ? reflection : skyReflection;
}
