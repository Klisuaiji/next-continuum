/* Copyright (C) Continuum Graphics - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Joseph Conover <support@continuum.graphics>, January 2018
 */

#define io inout

// Defining the SSBOs in here isn't the cleanest solution. 

layout(std430, binding = 0) buffer cameraTransforms {
    mat4 projectionMatrix;
    mat4 projectionMatrixInverse;
    mat4 viewMatrix;
    mat4 viewMatrixInverse;
    float nearPlane;
    float farPlane;
    float renderDistance;
} CameraTransforms;

layout(std430, binding = 1) buffer cameraTransformsPrevious {
    mat4 projectionMatrix;
    mat4 projectionMatrixInverse;
    mat4 viewMatrix;
    mat4 viewMatrixInverse;
} CameraTransformsPrevious;

layout(std430, binding = 2) buffer cloudTransforms {
    mat4 projectionMatrix;
    mat4 projectionMatrixInverse;
    mat4 viewMatrix;
    mat4 viewMatrixInverse;
} CloudTransforms;

layout(std430, binding = 3) buffer sceneData {
    vec3 sunColor;
    vec3 skyColor;
    vec3 sunVector;
    vec3 moonVector;
    vec3 lightVector;
    vec3 wSunVector;
    vec3 wMoonVector;
    vec3 wLightVector;
    vec2 taaJitter;
    float transitionFading;
    bool sceneChange;
    mat3x4 skySH;
} SceneData;

#if !defined DISABLE_MATRIX_OVERRIDE
    #define gbufferModelView CameraTransforms.viewMatrix
    #define gbufferModelViewInverse CameraTransforms.viewMatrixInverse 
    #define gbufferProjection CameraTransforms.projectionMatrix
    #define gbufferProjectionInverse CameraTransforms.projectionMatrixInverse
    #define far CameraTransforms.farPlane
    #define near CameraTransforms.nearPlane
#endif