#if !defined _FFT3_GLSL_
#define _FFT3_GLSL_

shared ComplexVec3 sharedBuffer[1024];


void RowPreload(ivec2 iPos, Complex inputNumber) {
    sharedBuffer[iPos.x].re.x = inputNumber.re;
    sharedBuffer[iPos.x].im.x = inputNumber.im;
    sharedBuffer[iPos.x].re.yz = vec2(0.0);
    sharedBuffer[iPos.x].im.yz = vec2(0.0);
}

void RowPreload(ivec2 iPos, sampler2D inputTexRe) {
    sharedBuffer[iPos.x].re = texture(inputTexRe, (vec2(iPos) + 0.5) / 1024.0).rgb;
    sharedBuffer[iPos.x].im = vec3(0.0);
}

void RowPreload(ivec2 iPos, sampler2D inputTexRe, sampler2D inputTexIm) {
    sharedBuffer[iPos.x].re = texelFetch(inputTexRe, iPos, 0).rgb;
    sharedBuffer[iPos.x].im = texelFetch(inputTexIm, iPos, 0).rgb;
}

void ColumnPreload(ivec2 iPos, sampler2D inputTexRe, sampler2D inputTexIm) {
    sharedBuffer[iPos.y].re = texelFetch(inputTexRe, iPos, 0).rgb;
    sharedBuffer[iPos.y].im = texelFetch(inputTexIm, iPos, 0).rgb;
}

ComplexVec3 FFT(int element, int N, int iteration, bool inverse) {
    // https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/tr-2008-62.pdf
    // !PERSONAL NOTE: ITERATION STARTS AT 1!!
    int subtransform = int(pow(2, iteration));
    int base = (element / subtransform) * subtransform / 2;
    int offset = element % (subtransform / 2);
    int index0 = base + offset;
    int index1 = index0 + N / 2;

    float theta = -2 * PI * (float(element) / float(subtransform));
          theta = inverse ? theta : -theta;
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);

    ComplexVec3 result;
    result.re = sharedBuffer[index0].re + cosTheta * sharedBuffer[index1].re - sinTheta * sharedBuffer[index1].im;
    result.im = sharedBuffer[index0].im + sinTheta * sharedBuffer[index1].re + cosTheta * sharedBuffer[index1].im;

    return result;
}

#endif // _FFT_GLSL_