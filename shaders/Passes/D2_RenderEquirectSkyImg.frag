#include "../InternalLib/Syntax.glsl"

in vec2 texcoord;

uniform sampler3D cloudNoiseTex;
uniform sampler3D curlNoiseTex;

uniform sampler2D skyScatteringTex;
uniform sampler2D skyTransmittanceTex;

uniform sampler3D lightPropagationVolume_r;

uniform sampler2D vxDepthTexOpaque;
uniform sampler2D depthTexFront, depthTexBack;

uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex9;
uniform sampler2D colortex10;

uniform sampler2D shadowtex0, shadowtex1;
uniform sampler2D shadowcolor, shadowcolor1;

uniform sampler2D noisetex;
uniform sampler2D blueNoiseTex;

uniform mat4 shadowModelView, shadowModelViewInverse;
uniform mat4 shadowProjection, shadowProjectionInverse;

uniform vec4 lightningBoltPosition;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;

uniform vec2 viewDimensions;

uniform ivec2 eyeBrightnessSmooth;

uniform float eyeAltitude;
uniform float wetness;
uniform float frameTimeCounter;

uniform int frameCounter;
uniform float viewWidth, viewHeight;
uniform int heldItemId;
uniform int worldTime;
uniform int isEyeInWater;

#define composite0 // stupid library requires this.

#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Debug.glsl"
#include "../InternalLib/Uniform/Matrices.glsl"
#include "../InternalLib/Common/SpaceConversions.glsl"
#include "../InternalLib/Common/Rand.glsl"
#include "../InternalLib/Fragment/Sky.fsh"
#include "../InternalLib/Fragment/Clouds2D.fsh"
#include "../InternalLib/Common/Voxelization.glsl"
#include "../InternalLib/Fragment/Clouds.fsh"
#include "../InternalLib/Common/AirMarcher.glsl"

vec3 CalculateSkyDome(float dither, vec2 texcoord) {
	vec3 sphericalProjection = ProjectSpherical(texcoord) * vec3(1.0, 1.0, -1.0);
	vec3 sphericalProjectionView = mat3(gbufferModelView) * sphericalProjection;
	vec3 sphericalViewVector = -sphericalProjectionView;

	vec3 sunVector = sunPosition * 0.01;
	vec3 upVector = upPosition * 0.01;

	vec3 viewAbsorb = vec3(1.0);

    vec3 skyDome = sky_atmosphere(vec3(0.0), sphericalViewVector, upVector, SceneData.sunVector, -SceneData.sunVector, sky_sunColor, sky_moonColor, 8, viewAbsorb);

	#ifdef REFLECT_2D_CLOUDS
		skyDome = CalculatePlanarClouds(skyDome, -sphericalProjection, dot(sphericalViewVector, sunVector));
	#endif

	#ifdef REFLECT_3D_CLOUDS
		vec4 clouds = CalculateVolumetricClouds(-sphericalProjection, 1.0, dither, 1e9, REFLECTED_CLOUDS_QUALITY, REFLECTED_CLOUDS_QUALITY_DIRECT, true, true);
		vec3 cloudScattering = clouds.r * SceneData.sunColor + clouds.b * SceneData.skyColor;
		float cloudTransmittance = clouds.b;

		float fogFactor = 1.0 - exp(-clouds.a * 0.0003);

		skyDome = mix(skyDome * cloudTransmittance + cloudScattering, skyDome, fogFactor);
	#endif

	#ifdef REFLECT_FOG_VOLUME
		vec3 scattering = vec3(0.0);
		vec3 transmittance = vec3(1.0);

		MarchAirVolume(scattering, transmittance, vec3(0.0), -CameraTransforms.farPlane * sphericalProjection, dither);

		skyDome = skyDome * transmittance + scattering;
	#endif

	vec3 prevSkyDome = texture(colortex9, texcoord).rgb;

	float blendFactor = 0.98 * float(!SceneData.sceneChange);

	skyDome = mix(skyDome, prevSkyDome, blendFactor);

	return skyDome;
}


/* DRAWBUFFERS: 9 */

layout (location = 0) out vec4 skyDome;

void main() {
    InitRand(uint(gl_FragCoord.x + viewWidth * gl_FragCoord.y) + (uint(viewWidth) * uint(viewHeight) * floatBitsToUint(frameTimeCounter)));

    ivec2 iPos = ivec2(gl_FragCoord);

    float dither = BlueNoiseTemporal(blueNoiseTex, iPos, frameCounter);
    skyDome = vec4(CalculateSkyDome(dither, texcoord), 0.0);
}