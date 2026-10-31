#if !defined _TESSENDORF_GLSL_
#define _TESSENDORF_GLSL_

// TODO: Un-hardcode this to accomodate resolutions other than 1024^2

vec2 SampleNormalDist(vec2 rand) {
    float rx = max(rand.x, 1e-7);
    float R = sqrt(-2.0 * log(rx));
    float theta = TAU * rand.y;
    return vec2(R * cos(theta), R * sin(theta));
}

float ComputePhilipsSpectrum(vec2 k) {
    float amplitude = length(k);
    if (amplitude < 1e-6) return 0.0;

    const vec2 wind = vec2(1.0, 1.0);
    const float A = 5500e-9 * (1.0 + 3.0 * rainStrength);
    const float V = 4.0 + rainStrength;
    const float g = 9.80665;
    const float L = pow2(V) / g;

    return A / pow4(amplitude) * exp(-1.0 / pow2(amplitude * L)) * pow2(dot(normalize(k), normalize(wind)));
}

Complex ComputeInitialWaveAmplitudes(vec2 k, vec2 rand) {
    float philips = ComputePhilipsSpectrum(k);

    Complex waveAmplitudes;
    waveAmplitudes.re = inversesqrt(2) * rand.x * sqrt(philips);
    waveAmplitudes.im = inversesqrt(2) * rand.y * sqrt(philips);

    return waveAmplitudes;
}

Complex ComputeWaveAmplitudes(vec2 k, float t) {
    vec2 rand = SampleNormalDist(RandNext2F());
    float w = sqrt(9.80665 * length(k));
    Complex initialAmplitude0 = ComplexMultiply(ComputeInitialWaveAmplitudes(k, rand), PolarToComplex(1.0, w * t));
    Complex initialAmplitude1 = ComplexMultiply(Conjugate(ComputeInitialWaveAmplitudes(-k, rand)), PolarToComplex(1.0, -w * t));

    Complex waveAmplitudes = ComplexAdd(initialAmplitude0, initialAmplitude1);

    return waveAmplitudes;
}

vec2 GetWaveFieldCoord(ivec2 iPos) {
    const vec2 L = vec2(250.0, 250.0);
    iPos -= ivec2(512);

    return vec2(iPos) * L / vec2(1024.0);
}

ivec2 ShiftCoordinates(ivec2 iPos) {
    ivec2 newPos;
    newPos.x = (iPos.x + 512) % 1024;
    newPos.y = (iPos.y + 512) % 1024;

    return newPos;
}

#endif // _TESSENDORF_GLSL_