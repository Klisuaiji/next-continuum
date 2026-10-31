#if !defined _REPROJECTION_GLSL_
#define _REPROJECTION_GLSL_

vec2 ComputeCameraVelocity(vec3 screenPos) {
	vec3 projection = mat3(gbufferModelViewInverse) * CalculateViewSpacePositionUnjittered(screenPos) + gbufferModelViewInverse[3].xyz;		 
	     projection = (cameraPosition - previousCameraPosition) + projection;
	     projection = mat3(CameraTransformsPrevious.viewMatrix) * projection + CameraTransformsPrevious.viewMatrix[3].xyz;
	     projection = (diagonal3(CameraTransformsPrevious.projectionMatrix) * projection + CameraTransformsPrevious.projectionMatrix[3].xyz) / -projection.z * 0.5 + 0.5;

	return (screenPos.xy - projection.xy);
}

#endif // _REPROJECTION_GLSL_