/* Copyright (C) Continuum Graphics - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Joseph Conover <support@continuum.graphics>, Febuary 2018
 */


#include "/InternalLib/Misc/NoiseTexture.glsl"
#include "/UserLib/QuickFilterSettings.glsl"

float GerstnerWave(vec2 coord, vec2 waveDirection, float globalTime, float waveSteepness, float waveAmplitude, float waveLength) {
    const float g = 19.6;

    // Wave number calculation
    float k = TAU / waveLength;
    float w = sqrt(g * k);

    // Count waves
    float x = w * globalTime - k * dot(waveDirection, coord);
    float wave = sin(x) * 0.5 + 0.5;

    return waveAmplitude * pow(wave, waveSteepness);
}

float GetWavesHeight(sampler2D waveTex, vec3 worldPosition, float NoV) {
    float height = texture(waveTex, fract(worldPosition.xz * 0.1)).x * QF_WAVE_HEIGHT - 1.0;

    #ifdef HORIZON_WAVE_FADE
        float fade = 1.0 - exp(-HORIZON_WAVE_FADE_FALLOFF * abs(NoV));
    #else 
        const float fade = 1.0;
    #endif

    return height * fade;
}

vec3 GetWavesNormal(sampler2D waveTex, vec3 position, float NoV) {
    // TODO: Water parallax here.

	const float delta  = 0.01;
	const float iDelta = 1.0 / delta;

	float t = GetWavesHeight(waveTex, position                        , NoV);
	float h = GetWavesHeight(waveTex, position + vec3(delta, 0.0, 0.0), NoV);
	float v = GetWavesHeight(waveTex, position + vec3(0.0, 0.0, delta), NoV);

	float dx = (t - h) * iDelta;
	float dz = (t - v) * iDelta;

    return normalize(vec3(dx, dz, 1.0));
}

vec3 GetWavesLPF(sampler2D waveTex, vec3 position, float NoV) {
    // TODO: Water parallax here.

	const float delta  = 0.25;
	const float iDelta = 1.0 / delta;

	float t = GetWavesHeight(waveTex, position                        , NoV) * 10.0;
	float h = GetWavesHeight(waveTex, position + vec3(delta, 0.0, 0.0), NoV) * 10.0;
	float v = GetWavesHeight(waveTex, position + vec3(0.0, 0.0, delta), NoV) * 10.0;

	float dx = (t - h) * iDelta;
	float dz = (t - v) * iDelta;

    return normalize(vec3(dx, dz, 1.0));
}