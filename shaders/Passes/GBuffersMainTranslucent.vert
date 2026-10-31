#extension GL_EXT_gpu_shader4 : enable

// #define DISABLE_MATRIX_OVERRIDE

#include "../InternalLib/Syntax.glsl"

attribute vec3 mc_Entity;
attribute vec4 at_tangent;
attribute vec2 mc_midTexCoord;

varying vec4 color;
varying vec3 worldSpacePosition;
varying vec2 texcoord;
varying vec2 lmcoord;

flat varying mat3 tbn;
flat varying vec3 lightVector;
flat varying vec3 tbnNormal;
flat varying float material;
flat varying vec2 midCoord;
flat varying vec2 tileSize;
flat varying float parallaxDepth;
flat varying vec2 wrap;

varying vec3 tangentSpaceViewVector;

#if defined DISABLE_MATRIX_OVERRIDE
	uniform mat4 gbufferProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
#endif

uniform vec3 shadowLightPosition;

uniform float viewWidth;
uniform float viewHeight;

uniform int frameCounter;

#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Uniform/TemporalJitter.glsl"

void main() {
    vec3 viewSpacePosition = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
	vec3 tangent = (at_tangent.xyz / at_tangent.w);

	#if defined gbuffers_water
		if (mc_Entity.x < 8.0) {
			vec3 vertexOffset = gl_Normal * (inversesqrt(dot(gl_Normal, gl_Normal)) * 0.003);
			viewSpacePosition += vertexOffset; // Push vertex out. This is for CTM overlays.
		}
	#endif

    color = gl_Color;
    material = mc_Entity.x;

    texcoord = gl_MultiTexCoord0.st;
    lmcoord = gl_MultiTexCoord1.xy * 0.00392157; // 1.0 / 255.0 = ~0.00392157
	midCoord = mc_midTexCoord.xy;

	// size of tile in the atlas (used for wrapping)
	tileSize = abs(gl_MultiTexCoord0.xy - mc_midTexCoord.xy) * 2.0;
	// make depth of parallax independent of tileSize
	parallaxDepth = length(tileSize) * TERRAIN_PARALLAX_DEPTH * 0.0625;

	lightVector = normalize(mat3(gbufferModelViewInverse) * (shadowLightPosition * 0.01));

	tbnNormal = (gl_NormalMatrix * gl_Normal) * mat3(gbufferModelView);
	tangent = (gl_NormalMatrix * tangent) * mat3(gbufferModelView);
	vec3 worldSpaceViewVector = mat3(gbufferModelViewInverse) * viewSpacePosition;
	worldSpacePosition = worldSpaceViewVector + gbufferModelViewInverse[3].xyz;

	tbn = mat3(tangent, cross(tangent, tbnNormal), tbnNormal);
	tangentSpaceViewVector = worldSpaceViewVector * tbn;

	#if !defined gbuffers_hand_water
		gl_Position    = viewSpacePosition.xyzz * diagonal4(CameraTransforms.projectionMatrix) + CameraTransforms.projectionMatrix[3];
	#else 
		gl_Position    = viewSpacePosition.xyzz * diagonal4(gl_ProjectionMatrix) + gl_ProjectionMatrix[3];
	#endif

	#if !defined gbuffers_hand_water && defined TAA
	    gl_Position.xy = SceneData.taaJitter * gl_Position.w + gl_Position.xy;
	#endif
}
