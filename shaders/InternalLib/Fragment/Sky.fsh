/* Copyright (C) Continuum Graphics - All Rights Reserved
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* Written by Joseph Conover <support@continuum.graphics>, July 2018
*/

/*******************************************************************************
 - Phases
 ******************************************************************************/

float sky_rayleighPhase(float cosTheta) {
	const vec2 mul_add = vec2(0.1, 0.28) * rPI;
	return cosTheta * mul_add.x + mul_add.y; // optimized version from [Elek09], divided by 4 pi for energy conservation
}

float sky_miePhase(float cosTheta, const float g) {
	const float gg = g * g;
	return (gg * -0.25 + 0.25) * pow(-2.0 * (g * cosTheta) + (gg + 1.0), -1.5);
}

vec2 sky_phase(float cosTheta, const float g) {
	return vec2(sky_rayleighPhase(cosTheta), sky_miePhase(cosTheta, g));
}

/*******************************************************************************
 - Sky Functions
 ******************************************************************************/

float calculateStars(vec3 p, vec3 wSunVector) {
	p = p * getRotMat(vec3(0.0, 1.0, 0.0), wSunVector);

    const float res = 2048.0;
	const float starCoverage = 0.01;

	vec3 rp = p * (0.15 * res);

	vec3 id  = floor(rp);
    vec3 q   = id - rp + 0.5;
    vec3 rn  = hash33(id);
    float c  = 1.0 - smoothstep(0.0, 0.5, length(q));
    	  c *= step(rn.x, starCoverage * 0.1);

    return c * 128.0;
}

float calculateStars(vec3 p) {
    const float res = 8192.0;
	const float starCoverage = 0.01;

	vec3 rp = p * (0.15 * res);

	vec3 id  = floor(rp);
    vec3 q   = id - rp + 0.5;
    vec3 rn  = hash33(id);
    float c  = 1.0 - smoothstep(0.0, 0.5, length(q));
    	  c *= step(rn.x, starCoverage * 0.1);

    return c * 16.0;
}

float calculateStarTrails(vec3 p) {
	const int steps = 512;
	const float totalAngle = 0.7; 
	const float anglePerStep = totalAngle / float(steps);

	float stars = 0.0;

	for (int i = 0; i < 128; i++) {
		float theta = i * anglePerStep;
		vec3 newPos =  (GenerateRotationMatrixX(theta) * GenerateRotationMatrixZ(-PI / 4.0) * p);
		stars += calculateStars(newPos) * exp(-0.02 * i) * 20.0;
	}

	return stars;
}

float CalculateSunSpot(float VdotL) {
    const float sunRadius = radians(sunAngularSize);
    const float cosSunRadius = cos(sunRadius);
    const float sunLuminance = 1.0 / ((1.0 - cosSunRadius) * PI);

	return fstep(cosSunRadius, VdotL) * sunLuminance;
}

vec3 CalculateEndDisk(sampler2D curlNoiseTex2D, sampler2D noisetex, const vec3 viewVector, const vec3 worldVector) {
    const vec3 u = vec3(1.0, 1.0, 1.0);
    const vec3 a = vec3(0.397, 0.503, 0.652);

    float VoL = dot(viewVector, SceneData.sunVector);

    vec3 sunDirection = SceneData.wSunVector;
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), sunDirection));
    vec3 upVec = cross(sunDirection, right);
    
    float uC = 0.5 + dot(worldVector, right) * 0.5;
    float vC = 0.5 + dot(worldVector, upVec) * 0.5;
    vec2 texcoord = vec2(uC, vC) * 1.5;

    if (VoL > 0.99 && VoL < 0.9905) {
        return sky_sunColor * 10000.0;
    }

    vec2 curl = texture(curlNoiseTex2D, texcoord + vec2(TIME * 0.01)).xy;
    vec2 curl2 = texture(curlNoiseTex2D, texcoord * 2.0 + vec2(TIME * 0.05)).xy;
	vec2 curl3 = texture(curlNoiseTex2D, texcoord * 8.0 + vec2(TIME * 0.05)).xy;

    float noise = pow(texture(noisetex, texcoord + curl * 0.02).x, 5.0);
          noise += pow(texture(noisetex, texcoord * 2.0 + curl2 * 0.05).x, 5.0);
		  noise += pow(texture(noisetex, texcoord * 5.0 + curl3 * 0.08).x, 5.0) * 0.7;

    return sky_sunColor * noise * exp(-500 * (1.0 - clamp01(VoL + 0.01))) * float(VoL < 0.9905) * 10000.0;
}

//Temporary moon disk untill we added a moon texture
float CalculateMoonSpot(float VdotL) {
    const float moonRadius = radians(moonAngularSize);
    const float cosMoonRadius = cos(moonRadius);
	const float moonLuminance = 1.0 / ((1.0 - cosMoonRadius) * PI);

	return fstep(cosMoonRadius, VdotL) * moonLuminance;
}

/*******************************************************************************
 - Sky Functions
 ******************************************************************************/

// No intersection if returned y component is < 0.0
vec2 rsi(vec3 position, vec3 direction, const float radius) {
	float PoD = dot(position, direction);
	const float radiusSquared = radius * radius;

	float delta = PoD * PoD + radiusSquared - dot(position, position);
	if (delta < 0.0) return vec2(-1.0);
	      delta = sqrt(delta);

	return -PoD + vec2(-delta, delta);
}

vec3 sky_atmosphereDensity(float centerDistance) {
	vec2 rayleighMie = exp(centerDistance * -atmosphere_inverseScaleHeights + atmosphere_scaledPlanetRadius);

	float ozone = exp(-max(0.0, (35000.0 - centerDistance) - atmosphere_planetRadius) * 0.0002)
	            * exp(-max(0.0, (centerDistance - 35000.0) - atmosphere_planetRadius) / 15000.0);

	return vec3(rayleighMie, ozone);
}

// I don't know if "thickness" is the right word, using it because Jodie uses it for that and I can't think of (or find) anything better.
vec3 sky_atmosphereThickness(vec3 position, vec3 direction, float rayLength, const float steps) {
	float stepSize  = rayLength / steps;
	vec3  increment = direction * stepSize;
	position += increment * 0.5;

	vec3 thickness = vec3(0.0);
	for (float i = 0.0; i < steps; ++i, position += increment) {
		thickness += sky_atmosphereDensity(length(position));
	}

	return thickness * stepSize;
}
vec3 sky_atmosphereThickness(vec3 position, vec3 direction, const float steps) {
	float rayLength = dot(position, direction);
	      rayLength = sqrt(rayLength * rayLength + atmosphere_atmosphereRadiusSquared - dot(position, position)) - rayLength;

	return sky_atmosphereThickness(position, direction, rayLength, steps);
}

vec3 sky_atmosphereOpticalDepth(vec3 position, vec3 direction, float rayLength, const float steps) {
	return atmosphere_coefficientsAttenuation * sky_atmosphereThickness(position, direction, rayLength, steps);
}
vec3 sky_atmosphereOpticalDepth(vec3 position, vec3 direction, const float steps) {
	return atmosphere_coefficientsAttenuation * sky_atmosphereThickness(position, direction, steps);
}

vec3 sky_atmosphereTransmittance(vec3 position, vec3 direction, const float steps) {
	return exp2(-sky_atmosphereOpticalDepth(position, direction, steps) * rLOG2);
}

vec3 GetSunColorZom() {
	return sky_atmosphereTransmittance(vec3(0.0, atmosphere_planetRadius, 0.0), mat3(gbufferModelViewInverse) * (sunPosition * 0.01), 8) * sky_sunColor;
}

vec3 GetMoonColorZom() {
	return sky_atmosphereTransmittance(vec3(0.0, atmosphere_planetRadius, 0.0), mat3(gbufferModelViewInverse) * (-sunPosition * 0.01), 8) * sky_moonColor;
}

vec3 sky_atmosphere(vec3 background, vec3 viewVector, vec3 upVector, vec3 sunVector, vec3 moonVector, vec3 sunIlluminance, vec3 moonIlluminance, const int iSteps, inout vec3 transmittance) {
	//const int iSteps = 25; // For very high quality: 50 is enough, could get away with less if mie scale height was lower
	const int jSteps = 3;  // For very high quality: 10 is good, can probably get away with less

	vec3 viewPosition = (atmosphere_planetRadius + eyeAltitude) * upVector;

	vec2 aid = rsi(viewPosition, viewVector, atmosphere_atmosphereRadius);
	if (aid.y < 0.0) return background;
	vec2 pid = rsi(viewPosition, viewVector, atmosphere_planetRadius * 0.998);

	bool pi = pid.y >= 0.0;

	vec2 sd = vec2((pi && pid.x < 0.0) ? pid.y : max(aid.x, 0.0), (pi && pid.x > 0.0) ? pid.x : aid.y);

	float stepSize  = (sd.y - sd.x) / iSteps;
	vec3  increment = viewVector * stepSize;
	vec3  position  = viewVector * sd.x + (increment * 0.3 + viewPosition);

	vec2 phaseSun  = sky_phase(dot(viewVector, sunVector ), atmosphere_mieg);
	vec2 phaseMoon = sky_phase(dot(viewVector, moonVector), atmosphere_mieg);

	vec3 scatteringSun  = vec3(0.0);
	vec3 scatteringMoon = vec3(0.0);
	vec3 scatteringAmbient = vec3(0.0);
		 transmittance = vec3(1.0);

	for (int i = 0; i < iSteps; ++i, position += increment) {
		#if defined DIM_OVERWORLD
		vec3 density          = sky_atmosphereDensity(length(position)) * vec3(1.0, 30.0 * wetness + 1.0, 1.0);
		#elif defined DIM_END
		vec3 density          = sky_atmosphereDensity(length(position)) * vec3(1.0, 30.0, 1.0);
		#elif defined DIM_NETHER 
		vec3 density          = sky_atmosphereDensity(length(position));
		#endif

		if (density.y > 1e35) break;
		vec3 stepAirmass      = density * stepSize;
		vec3 stepOpticalDepth = atmosphere_coefficientsAttenuation * stepAirmass;

		vec3 stepTransmittance       = exp2(-stepOpticalDepth * rLOG2);
		vec3 stepTransmittedFraction = clamp((stepTransmittance - 1.0) / -stepOpticalDepth, 0.0, 1.0);
		vec3 stepScatteringVisible   = transmittance * stepTransmittedFraction;

		scatteringSun  += (atmosphere_coefficientsScattering * (stepAirmass.xy * phaseSun )) * stepScatteringVisible * sky_atmosphereTransmittance(position, sunVector,  jSteps);
		scatteringMoon += (atmosphere_coefficientsScattering * (stepAirmass.xy * phaseMoon)) * stepScatteringVisible * sky_atmosphereTransmittance(position, moonVector, jSteps);
		scatteringAmbient += (atmosphere_coefficientsScattering * (stepAirmass.xy * phaseg0)) * stepScatteringVisible;

		transmittance  *= stepTransmittance;
	}

	vec3 scattering = scatteringSun * sunIlluminance + scatteringMoon * moonIlluminance + scatteringAmbient * rPI * SceneData.skyColor;

	return (!pi ? background * transmittance : vec3(0.0)) + scattering * TAU;
}
