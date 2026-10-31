#if !defined _COMPLEX_GLSL_
#define _COMPLEX_GLSL_

struct Complex {
    float re;
    float im;
};

struct ComplexVec3 {
    vec3 re; 
    vec3 im;
};

Complex Conjugate(Complex a) {
    Complex result;
    result.re = a.re;
    result.im = -a.im;

    return result;
}

Complex ComplexMultiply(Complex a, Complex b) {
    Complex result;
    result.re = a.re * b.re - a.im * b.im;
    result.im = a.re * b.im + a.im * b.re;

    return result;
}

Complex ComplexAdd(Complex a, Complex b) {
    Complex result;
    result.re = a.re + b.re;
    result.im = a.im + b.im;

    return result;
}

Complex PolarToComplex(float r, float theta) {
    Complex result;
    result.re = r * cos(theta);
    result.im = r * sin(theta);

    return result;
}

#endif