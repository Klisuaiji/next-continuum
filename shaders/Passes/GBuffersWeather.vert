varying vec4 color;
varying vec2 texcoord;

#include "../InternalLib/Syntax.glsl"
#include "../InternalLib/Utilities.glsl"

void main() {
	color = gl_Color;
	texcoord = gl_MultiTexCoord0.st;

	float modifier = gl_Vertex.y * 0.2 + 2.0 * sin(gl_Vertex.y);

	vec3 worldSpacePosition = gl_Vertex.xyz + vec3(-modifier, 0.0, -modifier);
	vec3 viewSpacePosition = mat3(gl_ModelViewMatrix) * worldSpacePosition + gl_ModelViewMatrix[3].xyz;
	
	gl_Position = viewSpacePosition.xyzz * diagonal4(CameraTransforms.projectionMatrix) + CameraTransforms.projectionMatrix[3];
}
