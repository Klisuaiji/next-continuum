#if !defined _FFT_GLSL_
#define _FFT_GLSL_

shared Complex sharedBuffer[1024];

void RowPreload(ivec2 iPos, Complex inputNumber) {
    sharedBuffer[iPos.x].re = inputNumber.re;
    sharedBuffer[iPos.x].im = inputNumber.im;
}

void RowPreload(ivec2 iPos, sampler2D inputTex) {
    sharedBuffer[iPos.x].re = texelFetch(inputTex, iPos, 0).r;
    sharedBuffer[iPos.x].im = texelFetch(inputTex, iPos, 0).g;
}

void ColumnPreload(ivec2 iPos, sampler2D inputTex) {
    sharedBuffer[iPos.y].re = texelFetch(inputTex, iPos, 0).r;
    sharedBuffer[iPos.y].im = texelFetch(inputTex, iPos, 0).g;
}

Complex FFT(int element, int N, int iteration, bool inverse) {
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

    Complex result;
    result.re = sharedBuffer[index0].re + cosTheta * sharedBuffer[index1].re - sinTheta * sharedBuffer[index1].im;
    result.im = sharedBuffer[index0].im + sinTheta * sharedBuffer[index1].re + cosTheta * sharedBuffer[index1].im;

    return result;
}

#endif // _FFT_GLSL_