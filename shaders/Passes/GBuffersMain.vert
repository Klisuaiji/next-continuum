#extension GL_EXT_gpu_shader4 : enable

#define DISABLE_MATRIX_OVERRIDE

#include "/InternalLib/Syntax.glsl"

attribute vec3 mc_Entity;
attribute vec2 mc_midTexCoord;
attribute vec4 at_tangent;

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;

flat varying vec2 midCoord;
flat varying vec2 tileSize;
flat varying float parallaxDepth;
flat varying vec2 wrap;

varying vec3 tangentSpaceViewVector;

flat varying mat3 tbn;
flat varying vec2 entity;
flat varying float material;
flat varying float materialFlag;

#if defined DISABLE_MATRIX_OVERRIDE
	uniform mat4 gbufferProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
#endif

uniform sampler2D texture;

uniform float viewWidth;
uniform float viewHeight;

uniform int frameCounter;

#if defined gbuffers_terrain
	uniform vec3 cameraPosition;
	uniform float frameTimeCounter;
#endif

#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Uniform/TemporalJitter.glsl"

#if defined gbuffers_terrain
	#include "../InternalLib/Common/Voxelization.glsl"
	#include "../InternalLib/Vertex/WavingTerrain.vsh"
	#include "../InternalLib/Vertex/VertexDisplacement.vsh"
#endif

const float pomDepthMultiplier = TERRAIN_PARALLAX_DEPTH * 0.0625;

void main() {
	color = gl_Color;
    material = mc_Entity.x;

    texcoord = gl_MultiTexCoord0.st;
    lmcoord = gl_MultiTexCoord1.xy / 240.0;
	midCoord = mc_midTexCoord.xy;

	entity = mc_Entity.xz;

	#if defined gbuffers_terrain
	    // lit block fix
		lmcoord.x = material == 89.0 || material == 169.0 || material == 124.0
		|| material == 51.0 || material == 10.0 || material == 11.0 ? 1.0 : lmcoord.x;

		materialFlag = 0.0;

		//Flag for plants
		materialFlag =
		material == 18.0 ||
		material == 31.0 ||
		material == 175.0 ||
		material == 176.0 ||
		material == 207.0

		? materialFlag = 1.0 : materialFlag;

		materialFlag = 
		material == 18.0 ||
		material == 161.0

		? materialFlag = 0.5 : materialFlag;
	#endif

	#if (defined gbuffers_terrain || defined gbuffers_hand) && defined TERRAIN_PARALLAX
		wrap = vec2(
			(mc_Entity.x == 81.0) ? 0.0 : 1.0,
			((mc_Entity.x == 81.0) && (gl_Normal.y > 0.1)) ? 0.0 : 1.0
		);

		wrap = (materialFlag > 0.0 || material == 50.0) ? vec2(0.0) : vec2(1.0);

		// size of tile in the atlas (used for wrapping)
		tileSize = abs(gl_MultiTexCoord0.xy - mc_midTexCoord.xy) * 2.0;
		// make depth of parallax independent of tileSize
		parallaxDepth = length(tileSize) * pomDepthMultiplier;
	#endif

	vec3 tangent = at_tangent.xyz / at_tangent.w;
	vec3 normal = gl_Normal;
	vec2 atlasSize = vec2(textureSize2D(texture, 0));

	#if !defined gbuffers_terrain
		normal = (gl_NormalMatrix * normal) * mat3(gbufferModelView);
		tangent = (gl_NormalMatrix * tangent) * mat3(gbufferModelView);
	#endif

	tbn = mat3(tangent, cross(tangent, normal), normal);
	mat3 tbnMod = mat3(tangent * atlasSize.y / atlasSize.x, tbn[1], tbn[2]);

	vec3 viewSpacePosition = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
	tangentSpaceViewVector = (viewSpacePosition * gl_NormalMatrix) * tbnMod;

	vec3 worldSpacePosition = transMAD(gbufferModelViewInverse, viewSpacePosition);

	#if defined gbuffers_terrain
		worldSpacePosition = CalculateVertexDisplacement(worldSpacePosition);
	#endif

	viewSpacePosition.xyz = transMAD(CameraTransforms.viewMatrix, worldSpacePosition);

	#if defined gbuffers_hand || defined gbuffers_armor_glint
		gl_Position = viewSpacePosition.xyzz * diagonal4(gl_ProjectionMatrix) + gl_ProjectionMatrix[3];
		#if defined TAA && defined gbuffers_armor_glint
			gl_Position.xy = SceneData.taaJitter * gl_Position.w + gl_Position.xy;
		#endif
	#else
		gl_Position = viewSpacePosition.xyzz * diagonal4(CameraTransforms.projectionMatrix) + CameraTransforms.projectionMatrix[3];
		#ifdef TAA
			gl_Position.xy = SceneData.taaJitter * gl_Position.w + gl_Position.xy;
		#endif
	#endif
}
