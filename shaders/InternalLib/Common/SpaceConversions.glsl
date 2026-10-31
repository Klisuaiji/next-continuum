#if !defined _SPACE_CONVERSIONS_
#define _SPACE_CONVERSIONS_

vec3 CalculateViewSpacePosition(vec3 screenPos) {
	screenPos = (screenPos * 2.0 - 1.0) - vec3(SceneData.taaJitter, 0.0);

	return projMAD(CameraTransforms.projectionMatrixInverse, screenPos) / (screenPos.z * CameraTransforms.projectionMatrixInverse[2].w + CameraTransforms.projectionMatrixInverse[3].w);
}


vec3 CalculateViewSpacePosition(vec3 screenPos, mat4 projectionMatrixInverse) {
    screenPos = screenPos * 2.0 - 1.0;
    vec4 temp = projectionMatrixInverse * vec4(screenPos, 1.0);

    return temp.xyz / temp.w;
}

vec3 CalculateViewSpacePosition(vec2 coord, sampler2D depthSampler) {
	vec3 screenPos = vec3(coord, texture(depthSampler, coord).x) * 2.0 - 1.0 - vec3(SceneData.taaJitter, 0.0);

	return projMAD(CameraTransforms.projectionMatrixInverse, screenPos) / (screenPos.z * CameraTransforms.projectionMatrixInverse[2].w + CameraTransforms.projectionMatrixInverse[3].w);
}


vec3 CalculateViewSpacePositionUnjittered(vec3 screenPos) {
	screenPos = (screenPos) * 2.0 - 1.0;

	return projMAD(CameraTransforms.projectionMatrixInverse, screenPos) / (screenPos.z * CameraTransforms.projectionMatrixInverse[2].w + CameraTransforms.projectionMatrixInverse[3].w);
}

vec3 CalculateWorldSpacePosition(vec3 viewPos) {
	return mat3(CameraTransforms.viewMatrixInverse) * viewPos + CameraTransforms.viewMatrixInverse[3].xyz;
}

vec3 CalculateWorldSpacePosition(vec3 viewPos, mat4 viewMatrixInverse) {
	return mat3(viewMatrixInverse) * viewPos + viewMatrixInverse[3].xyz;
}

vec3 ViewSpaceToScreenSpace(vec3 viewPos) {
	return ((projMAD(CameraTransforms.projectionMatrix, viewPos) / -viewPos.z)) * 0.5 + 0.5 + vec3(SceneData.taaJitter * 0.5, 0.0);
}

float ScreenToViewSpaceDepth(float p) {
	p = p * 2.0 - 1.0;
	vec2 x = CameraTransforms.projectionMatrixInverse[2].zw * p + CameraTransforms.projectionMatrixInverse[3].zw;

	return x.x / x.y;
}

vec2 UnprojectSpherical(vec3 dir) {
    vec2 lonlat = vec2(atan(-dir.x, dir.z), acos(dir.y));
    return lonlat * vec2(rTAU, rPI) + vec2(0.5, 0.0);
}

vec3 ProjectSpherical(vec2 coord) {
	coord *= vec2(TAU, PI);
	vec2 lon = sincos(coord.x) * sin(coord.y);
	return vec3(lon.x, cos(coord.y), lon.y);
}

vec3 ViewSpaceToScreenSpace(vec3 viewPos, mat4 projectionMatrix) {
    vec4 tmp = projectionMatrix * vec4(viewPos, 1.0);
    tmp.xyz = tmp.xyz / tmp.w;
    return tmp.xyz * 0.5 + 0.5;
}

#endif // _SPACE_CONVERSIONS_