/* Copyright (C) Continuum Graphics - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Joseph Conover <support@continuum.graphics>, January 2018
 */

const int noiseTextureResolution = 64;
const float invNoiseRes = 1.0 / noiseTextureResolution;

const vec3 LUMA_COEFF = vec3(0.2125, 0.7154, 0.0721);

const float PI = radians(180.0);
const float TAU = radians(360.0);
const float HPI = PI * 0.5;
const float rPI = 1.0 / PI;
const float rTAU = 1.0 / TAU;
const float PHI = sqrt(5.0) * 0.5 + 0.5;

const float goldenAngle = TAU / PHI / PHI;

const float LOG2 = log(2.0);
const float rLOG2 = 1.0 / LOG2;

#define TIME_SPEED 1.0 // [0.0 0.025 0.05 0.075 0.1 0.125 0.15 0.175 0.2 0.225 0.25 0.275 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 5.0 6.0 7.0 8.0 9.0 10.0 12.0 14.0 16.0 18.0 20.0 24.0 28.0 32.0 36.0 40.0]
#define TIME ( frameTimeCounter * TIME_SPEED )

#define diagonal2(m) vec2((m)[0].x, (m)[1].y)
#define diagonal3(m) vec3(diagonal2(m), m[2].z)
#define diagonal4(m) vec4(diagonal3(m), m[2].w)

#define transMAD(mat, v) (     mat3(mat) * (v) + (mat)[3].xyz)
#define  projMAD(mat, v) (diagonal3(mat) * (v) + (mat)[3].xyz)

#define sum2(v) (v.x + v.y)
#define sum3(v) ((v.x + v.y) + v.z)
#define sum4(v) (((v).x + (v).y) + ((v).z + (v).w))

#define fstep(a, b) clamp(((b) - (a)) * 1e35, 0.0, 1.0)
#define fsign(a) (clamp((a) * 1e35, 0.0, 1.0) * 2.0 - 1.0)

#define textureRaw(samplr, coord) texelFetch2D(samplr, ivec2((coord) * vec2(viewWidth, viewHeight)), 0)
#define ScreenTex(samplr) texelFetch2D(samplr, ivec2(gl_FragCoord.st), 0)

#if defined composite0 || defined composite1 || defined deffered0 || defined gbuffers_water || defined gbuffers_textured || defined final || defined gbuffers_hand_water
#define up gbufferModelView[1].xyz
#endif

float RGBToLuma(vec3 rgb) {
    return dot(rgb, LUMA_COEFF);
}

vec3 clampNormal(const vec3 n, const vec3 v) {
    float NoV = clamp(dot(n, -v), 0.0, 1.0);
    return normalize(NoV * v + n);
}

float dotNorm(vec3 v, vec3 n) {
	return dot(v, n) * inversesqrt(dot(v, v));
}

vec2 sincos(float x){
	return vec2(sin(x),cos(x));
}

vec2 circlemap(float i, float n){
	return sincos(i * n * goldenAngle) * sqrt(i);
}

vec2 circlemapSq(float i, float n){
    return sincos(i * n * goldenAngle) * i;
}

vec3 circlemapL(float i, float n){
	return vec3(sincos(i * n * goldenAngle), sqrt(i));
}

vec3 srgbToLinear(vec3 srgb) {
    return mix(
        srgb * 0.07739938080495356, // 1.0 / 12.92 = ~0.07739938080495356
        pow(0.947867 * srgb + 0.0521327, vec3(2.4)),
        step(0.04045, srgb)
    );
}

vec3 linearToSrgb(vec3 linear) {
    return mix(
        linear * 12.92,
        pow(linear, vec3(0.416666666667)) * 1.055 - 0.055, // 1.0 / 2.4 = ~0.416666666667
        step(0.0031308, linear)
    );
}

mat4 GenOrthoMat(float left, float right, float bottom, float top, float nearDis, float farDis) {
    float tx = -(right + left) / (right - left);
    float ty = -(top + bottom) / (top - bottom);
    float tz = -(farDis + nearDis) / (farDis - nearDis);

    return mat4(
        2.0 / (right - left), 0.0, 0.0, 0.0,
        0.0, 2.0 / (top - bottom), 0.0, 0.0,
        0.0, 0.0, -2.0 / (farDis - nearDis), 0.0,
        tx, ty, tz, 1.0
    );
}

mat4 GenPerspectiveMat(float fov, float aspect, float nearDis, float farDis) {
    float f = 1.0 / tan(fov * 0.5 * radians(1.0));
    float rangeInv = 1.0 / (nearDis - farDis);

    return mat4(
        f / aspect, 0.0, 0.0, 0.0,
        0.0, f, 0.0, 0.0,
        0.0, 0.0, (nearDis + farDis) * rangeInv, -1.0,
        0.0, 0.0, nearDis * farDis * rangeInv * 2.0, 0.0
    );
}

mat4 Mat3ToHomogenousMat4(mat3 mat) {
    return mat4(
        vec4(mat[0], 0.0),
        vec4(mat[1], 0.0),
        vec4(mat[2], 0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
}

mat3 GenerateRotationMatrixX(float theta) {
    mat3 rot = transpose(mat3(
        1.0, 0.0,        0.0,
        0.0, cos(theta), -sin(theta),
        0.0, sin(theta), cos(theta)
    ));

    return rot;
}

mat3 GenerateRotationMatrixY(float theta) {
    mat3 rot = transpose(mat3(
        cos(theta),  0, sin(theta),
        0,           1,          0, 
        -sin(theta), 0, cos(theta)
    ));

    return rot;
}

mat3 GenerateRotationMatrixZ(float theta) {
    mat3 rot = transpose(mat3(
        cos(theta), -sin(theta), 0,
        sin(theta), cos(theta),  0,
        0,          0,           1
    ));

    return rot;
}

mat2 GenerateRotationMatrix2D(float theta) {
    return mat2(
        cos(theta), -sin(theta),
        sin(theta), cos(theta)
    );
}

vec3 GenerateUnitVector(vec2 xy) {
    xy.x *= TAU; xy.y = xy.y * 2.0 - 1.0;
    return vec3(sincos(xy.x) * sqrt(1.0 - xy.y * xy.y), xy.y);
}

vec3 GenerateConeVector(float angle, vec2 xy) {
    xy.x *= TAU;
    float cosAngle = cos(angle);
    xy.y = xy.y * (1.0 - cosAngle) + cosAngle;
    return vec3(vec2(cos(xy.x), sin(xy.x)) * sqrt(1.0 - xy.y * xy.y), xy.y);
}

vec3 UniformSampleHemisphere(vec3 normal, vec2 rand){
    // cos(theta) = r1 = y
    // cos^2(theta) + sin^2(theta) = 1 -> sin(theta) = sqrt(1 - cos^2(theta))
    float sinTheta = sqrt(1.0 - rand.x * rand.x);
    float phi = 2.0 * PI * rand.y;
    float x = sinTheta * cos(phi);
    float z = sinTheta * sin(phi);
    
    // Transform the local hemisphere direction to world space aligned with the normal
    vec3 tangent, bitangent;
    if (abs(normal.x) > 0.1) {
        tangent = normalize(cross(normal, vec3(0.0, 1.0, 0.0)));
    } else {
        tangent = normalize(cross(normal, vec3(1.0, 0.0, 0.0)));
    }
    bitangent = normalize(cross(normal, tangent));

    vec3 hemisphereDir = tangent * x + normal * rand.x + bitangent * z;
    return normalize(hemisphereDir);
}

float ManhattanDistance(vec3 vec) {
    return abs(vec.x) + abs(vec.y) + abs(vec.z);
}

float ManhattanDistance(vec2 vec) {
    return abs(vec.x) + abs(vec.y);
}

vec3 GenerateConeVector(vec3 vector, float angle, vec2 xy) {
    vec3 v = GenerateUnitVector(xy);
    float VoD = dot(v, vector);

    float cosAngle = cos(angle);
    float newCosTheta = VoD * (1.0 - cosAngle) + cosAngle;

    return sqrt(1.0 - newCosTheta * newCosTheta) * inversesqrt(1.0 - VoD * VoD) * (v - vector * VoD) + newCosTheta * vector;
}

mat3 getRotMat(vec3 x,vec3 y){
   float d = dot(x,y);
   vec3 cr = cross(y,x);

   float s = length(cr);

   float id = 1.-d;

   vec3 m = cr/s;

   vec3 m2 = m*m*id+d;
   vec3 sm = s*m;

   vec3 w = (m.xy*id).xxy*m.yzz;

   return mat3(
	   m2.x,     w.x-sm.z, w.y+sm.y,
	   w.x+sm.z, m2.y,     w.z-sm.x,
	   w.y-sm.y, w.z+sm.x, m2.z
   );
}

vec3 blackbody(const float t) {
    // http://en.wikipedia.org/wiki/Planckian_locus

    const vec4 vx = vec4(-0.2661239e9, -0.2343580e6, 0.8776956e3,  0.179910  );
    const vec4 vy = vec4(-1.1063814,   -1.34811020,  2.18555832,  -0.20219683);

    const mat3 xyzToSrgb = mat3(
            3.2404542, -1.5371385, -0.4985314,
        -0.9692660,  1.8760108,  0.0415560,
            0.0556434, -0.2040259,  1.0572252
    );

    float it = 1.0 / t;
    float it2 = it * it;

    float x = dot(vx, vec4(it * it2, it2, it, 1.0));
    float x2 = x * x;

    float y = dot(vy, vec4(x * x2, x2, x, 1.0));

    return max(vec3(x / y, 1.0, (1.0 - x - y) / y) * xyzToSrgb, vec3(0.0));
}

vec3 fromYUV (vec3 yuv) {
    const vec2 c2 = vec2(1.8556,1.5748);
    const float c4 = 1. / .7152;
    const vec2 c5 = -vec2(.0722,.2126) * c4;
    const vec2 c1 = -.5* c2;

    vec2 br = yuv.yz * c2 + (c1 + yuv.x);
    return vec3(br.y, yuv.x * c4 + dot(c5, br), br.x);
}

vec3 toYUV (vec3 rgb) {
    const vec2 c2 = vec2(1.8556,1.5748);
    const vec3 c3 = vec3(.2126,.7152,.0722);
    const vec2 c6 = 1. / c2;

    float y = dot(rgb, c3);
    return vec3(y, (rgb.br - y) * c6 +.5);
}

vec2 rotate(vec2 vector, float r) {
    float c = cos(r), s = sin(r);
    return vector * mat2(c, -s, s, c);
}

vec3 hash33(vec3 p){
    p = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p.zxy, p.yxz + 19.27);
    return fract(vec3(p.x * p.y, p.z * p.x, p.y * p.z));
}

float cubesmooth(float x) { return (x * x) * (3.0 - 2.0 * x); }
vec2 cubesmooth(vec2 x) { return (x * x) * (3.0 - 2.0 * x); }
vec3 cubesmooth(vec3 x) { return (x * x) * (3.0 - 2.0 * x); }
vec4 cubesmooth(vec4 x) { return (x * x) * (3.0 - 2.0 * x); }

#define getDepthExp(x) ( (far * (x - near)) / (x * (far - near)) )

#define EncodeColor(x) ((x) * 0.0001)
#define DecodeColor(x) ((x) * 10000.0)

const ivec2[2] CHECKER_OFFSETS_2x1 = ivec2[2](
	ivec2(0, 0),
	ivec2(1, 0)
);

const ivec2[4] CHECKER_OFFSETS_2x2 = ivec2[4](
	ivec2(0, 0),
	ivec2(1, 1),
	ivec2(1, 0),
	ivec2(0, 1)
);

const ivec2[8] CHECKER_OFFSETS_4x2 = ivec2[8](
	ivec2(0, 0),
	ivec2(2, 0),
	ivec2(1, 1),
	ivec2(3, 1),
	ivec2(1, 0),
	ivec2(3, 0),
	ivec2(0, 1),
	ivec2(2, 1)
);

const ivec2[9] CHECKER_OFFSETS_3x3 = ivec2[9](
	ivec2(0, 0),
	ivec2(2, 0),
	ivec2(0, 2),
	ivec2(2, 2),
	ivec2(1, 1),
	ivec2(1, 0),
	ivec2(1, 2),
	ivec2(0, 1),
	ivec2(2, 1)
);

const ivec2[16] CHECKER_OFFSETS_4x4 = ivec2[16](
	ivec2(0, 0),
	ivec2(2, 0),
	ivec2(0, 2),
	ivec2(2, 2),
	ivec2(1, 1),
	ivec2(3, 1),
	ivec2(1, 3),
	ivec2(3, 3),
	ivec2(1, 0),
	ivec2(3, 0),
	ivec2(1, 2),
	ivec2(3, 2),
	ivec2(0, 1),
	ivec2(2, 1),
	ivec2(0, 3),
	ivec2(2, 3)
);

const ivec2[64] CHECKER_OFFSETS_8x8 = ivec2[64](
    ivec2(0, 0),  ivec2(2, 0),  ivec2(4, 0),  ivec2(6, 0),
    ivec2(1, 1),  ivec2(3, 1),  ivec2(5, 1),  ivec2(7, 1),
    ivec2(0, 2),  ivec2(2, 2),  ivec2(4, 2),  ivec2(6, 2),
    ivec2(1, 3),  ivec2(3, 3),  ivec2(5, 3),  ivec2(7, 3),
    ivec2(0, 4),  ivec2(2, 4),  ivec2(4, 4),  ivec2(6, 4),
    ivec2(1, 5),  ivec2(3, 5),  ivec2(5, 5),  ivec2(7, 5),
    ivec2(0, 6),  ivec2(2, 6),  ivec2(4, 6),  ivec2(6, 6),
    ivec2(1, 7),  ivec2(3, 7),  ivec2(5, 7),  ivec2(7, 7),

    ivec2(1, 0),  ivec2(3, 0),  ivec2(5, 0),  ivec2(7, 0),
    ivec2(0, 1),  ivec2(2, 1),  ivec2(4, 1),  ivec2(6, 1),
    ivec2(1, 2),  ivec2(3, 2),  ivec2(5, 2),  ivec2(7, 2),
    ivec2(0, 3),  ivec2(2, 3),  ivec2(4, 3),  ivec2(6, 3),
    ivec2(1, 4),  ivec2(3, 4),  ivec2(5, 4),  ivec2(7, 4),
    ivec2(0, 5),  ivec2(2, 5),  ivec2(4, 5),  ivec2(6, 5),
    ivec2(1, 6),  ivec2(3, 6),  ivec2(5, 6),  ivec2(7, 6),
    ivec2(0, 7),  ivec2(2, 7),  ivec2(4, 7),  ivec2(6, 7)
);

const ivec2[256] CHECKER_OFFSETS_16x16 = ivec2[256](
    ivec2(0, 0),   ivec2(2, 0),   ivec2(4, 0),   ivec2(6, 0),   ivec2(8, 0),   ivec2(10, 0),  ivec2(12, 0),  ivec2(14, 0),
    ivec2(1, 1),   ivec2(3, 1),   ivec2(5, 1),   ivec2(7, 1),   ivec2(9, 1),   ivec2(11, 1),  ivec2(13, 1),  ivec2(15, 1),
    ivec2(0, 2),   ivec2(2, 2),   ivec2(4, 2),   ivec2(6, 2),   ivec2(8, 2),   ivec2(10, 2),  ivec2(12, 2),  ivec2(14, 2),
    ivec2(1, 3),   ivec2(3, 3),   ivec2(5, 3),   ivec2(7, 3),   ivec2(9, 3),   ivec2(11, 3),  ivec2(13, 3),  ivec2(15, 3),
    ivec2(0, 4),   ivec2(2, 4),   ivec2(4, 4),   ivec2(6, 4),   ivec2(8, 4),   ivec2(10, 4),  ivec2(12, 4),  ivec2(14, 4),
    ivec2(1, 5),   ivec2(3, 5),   ivec2(5, 5),   ivec2(7, 5),   ivec2(9, 5),   ivec2(11, 5),  ivec2(13, 5),  ivec2(15, 5),
    ivec2(0, 6),   ivec2(2, 6),   ivec2(4, 6),   ivec2(6, 6),   ivec2(8, 6),   ivec2(10, 6),  ivec2(12, 6),  ivec2(14, 6),
    ivec2(1, 7),   ivec2(3, 7),   ivec2(5, 7),   ivec2(7, 7),   ivec2(9, 7),   ivec2(11, 7),  ivec2(13, 7),  ivec2(15, 7),
    ivec2(0, 8),   ivec2(2, 8),   ivec2(4, 8),   ivec2(6, 8),   ivec2(8, 8),   ivec2(10, 8),  ivec2(12, 8),  ivec2(14, 8),
    ivec2(1, 9),   ivec2(3, 9),   ivec2(5, 9),   ivec2(7, 9),   ivec2(9, 9),   ivec2(11, 9),  ivec2(13, 9),  ivec2(15, 9),
    ivec2(0, 10),  ivec2(2, 10),  ivec2(4, 10),  ivec2(6, 10),  ivec2(8, 10),  ivec2(10, 10), ivec2(12, 10), ivec2(14, 10),
    ivec2(1, 11),  ivec2(3, 11),  ivec2(5, 11),  ivec2(7, 11),  ivec2(9, 11),  ivec2(11, 11), ivec2(13, 11), ivec2(15, 11),
    ivec2(0, 12),  ivec2(2, 12),  ivec2(4, 12),  ivec2(6, 12),  ivec2(8, 12),  ivec2(10, 12), ivec2(12, 12), ivec2(14, 12),
    ivec2(1, 13),  ivec2(3, 13),  ivec2(5, 13),  ivec2(7, 13),  ivec2(9, 13),  ivec2(11, 13), ivec2(13, 13), ivec2(15, 13),
    ivec2(0, 14),  ivec2(2, 14),  ivec2(4, 14),  ivec2(6, 14),  ivec2(8, 14),  ivec2(10, 14), ivec2(12, 14), ivec2(14, 14),
    ivec2(1, 15),  ivec2(3, 15),  ivec2(5, 15),  ivec2(7, 15),  ivec2(9, 15),  ivec2(11, 15), ivec2(13, 15), ivec2(15, 15),

    ivec2(1, 0),   ivec2(3, 0),   ivec2(5, 0),   ivec2(7, 0),   ivec2(9, 0),   ivec2(11, 0),  ivec2(13, 0),  ivec2(15, 0),
    ivec2(0, 1),   ivec2(2, 1),   ivec2(4, 1),   ivec2(6, 1),   ivec2(8, 1),   ivec2(10, 1),  ivec2(12, 1),  ivec2(14, 1),
    ivec2(1, 2),   ivec2(3, 2),   ivec2(5, 2),   ivec2(7, 2),   ivec2(9, 2),   ivec2(11, 2),  ivec2(13, 2),  ivec2(15, 2),
    ivec2(0, 3),   ivec2(2, 3),   ivec2(4, 3),   ivec2(6, 3),   ivec2(8, 3),   ivec2(10, 3),  ivec2(12, 3),  ivec2(14, 3),
    ivec2(1, 4),   ivec2(3, 4),   ivec2(5, 4),   ivec2(7, 4),   ivec2(9, 4),   ivec2(11, 4),  ivec2(13, 4),  ivec2(15, 4),
    ivec2(0, 5),   ivec2(2, 5),   ivec2(4, 5),   ivec2(6, 5),   ivec2(8, 5),   ivec2(10, 5),  ivec2(12, 5),  ivec2(14, 5),
    ivec2(1, 6),   ivec2(3, 6),   ivec2(5, 6),   ivec2(7, 6),   ivec2(9, 6),   ivec2(11, 6),  ivec2(13, 6),  ivec2(15, 6),
    ivec2(0, 7),   ivec2(2, 7),   ivec2(4, 7),   ivec2(6, 7),   ivec2(8, 7),   ivec2(10, 7),  ivec2(12, 7),  ivec2(14, 7),
    ivec2(1, 8),   ivec2(3, 8),   ivec2(5, 8),   ivec2(7, 8),   ivec2(9, 8),   ivec2(11, 8),  ivec2(13, 8),  ivec2(15, 8),
    ivec2(0, 9),   ivec2(2, 9),   ivec2(4, 9),   ivec2(6, 9),   ivec2(8, 9),   ivec2(10, 9),  ivec2(12, 9),  ivec2(14, 9),
    ivec2(1, 10),  ivec2(3, 10),  ivec2(5, 10),  ivec2(7, 10),  ivec2(9, 10),  ivec2(11, 10), ivec2(13, 10), ivec2(15, 10),
    ivec2(0, 11),  ivec2(2, 11),  ivec2(4, 11),  ivec2(6, 11),  ivec2(8, 11),  ivec2(10, 11), ivec2(12, 11), ivec2(14, 11),
    ivec2(1, 12),  ivec2(3, 12),  ivec2(5, 12),  ivec2(7, 12),  ivec2(9, 12),  ivec2(11, 12), ivec2(13, 12), ivec2(15, 12),
    ivec2(0, 13),  ivec2(2, 13),  ivec2(4, 13),  ivec2(6, 13),  ivec2(8, 13),  ivec2(10, 13), ivec2(12, 13), ivec2(14, 13),
    ivec2(1, 14),  ivec2(3, 14),  ivec2(5, 14),  ivec2(7, 14),  ivec2(9, 14),  ivec2(11, 14), ivec2(13, 14), ivec2(15, 14),
    ivec2(0, 15),  ivec2(2, 15),  ivec2(4, 15),  ivec2(6, 15),  ivec2(8, 15),  ivec2(10, 15), ivec2(12, 15), ivec2(14, 15)
);

#include "/InternalLib/UserLibManager.glsl"

#include "/InternalLib/Utilities/Materials.glsl"
#include "/InternalLib/Utilities/Encoding.glsl"
#include "/InternalLib/Utilities/Pow.glsl"
#include "/InternalLib/Utilities/Clamping.glsl"
#include "/InternalLib/Utilities/Noise.glsl"
#include "/InternalLib/Utilities/FastMath.glsl"
#include "/InternalLib/Fragment/ACESTransforms.glsl"
