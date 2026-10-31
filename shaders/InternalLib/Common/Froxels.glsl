#ifndef FROXELS_GLSL
#define FROXELS_GLSL

// Voxy allows for insane render distances up to 2048 chunks. 
// In order to prevent excessive flickering/dithering near the camera, 
// I use a depth distribution that is nonlinear, i.e. it concentrates samples near the camera
// where they matter most. 

// Contrary to the overworld dimensions, where aerial perspective / distant scattering is an important visual cue, 
// the end distance in the nether and end dimensions is drastically reduced because far-away fog rendering in those dimensions is redundant. 

float DistributeDepth(float linearDepth) {
    float startDistance = 1.0;
    float endDistance = CameraTransforms.farPlane;
    float exponent = 2.0 + CameraTransforms.farPlane * 0.0001;

    #ifndef DIM_OVERWORLD 
        endDistance = 256.0;
        exponent = 2.0;
    #endif

    return endDistance * pow(linearDepth, exponent) + startDistance * (1 - pow(linearDepth, exponent));
}

float InverseDistributeDepth(float distributedDepth) {
    float startDistance = 1.0;
    float endDistance = CameraTransforms.farPlane;
    float exponent = 2.0 + CameraTransforms.farPlane * 0.0001;

    #ifndef DIM_OVERWORLD
        endDistance = 256.0;
        exponent = 2.0;
    #endif

    return pow(
        (distributedDepth - startDistance) / (endDistance - startDistance),
        1.0 / exponent
    );
}


vec3 FroxelSpaceToWorldSpace(vec3 nCoord) {
    float linearDepth = DistributeDepth(nCoord.z);

    vec4 ndc = vec4(nCoord.xy * 2.0 - 1.0, 1.0, 1.0);
    vec4 ray = CameraTransforms.projectionMatrixInverse * ndc;
    ray.xyz /= ray.w;

    vec3 viewDir = normalize(ray.xyz);
    vec3 viewPos = viewDir * linearDepth;

    vec4 worldPos = CameraTransforms.viewMatrixInverse * vec4(viewPos, 1.0);
    return worldPos.xyz;
}


vec3 ScreenSpaceToFroxelSpace(vec3 screenCoord) {
    vec4 ndc = vec4(screenCoord * 2.0 - 1.0, 1.0);
    vec4 viewPos = CameraTransforms.projectionMatrixInverse * ndc;
    viewPos.xyz /= viewPos.w;

    float viewDepth = length(viewPos.xyz);
    float froxelZ = InverseDistributeDepth(viewDepth);

    return vec3(screenCoord.xy, froxelZ);
}

vec3 WorldSpaceToFroxelSpace(vec3 worldPos, mat4 viewMatrix, mat4 projectionMatrix) {
    vec4 viewPos4 = viewMatrix * vec4(worldPos, 1.0);
    vec3 viewPos = viewPos4.xyz;

    float viewDepth = length(viewPos);
    float froxelZ = InverseDistributeDepth(viewDepth);

    vec4 clipPos = projectionMatrix * vec4(viewPos, 1.0);
    vec3 ndc = clipPos.xyz / clipPos.w;

    vec2 uv = ndc.xy * 0.5 + 0.5;

    return vec3(uv, froxelZ);
}

vec3 ViewSpaceToFroxelSpace(vec2 uv, vec3 viewPos) {
    float viewDepth = length(viewPos);
    float froxelZ = InverseDistributeDepth(viewDepth);

    return vec3(uv, froxelZ);
}

#endif // FROXELS_GLSL