#extension GL_EXT_gpu_shader4 : enable

#define composite2
#define ShaderStage 12

#include "../InternalLib/Syntax.glsl"

const bool colortex4MipmapEnabled = true;

varying vec2 texcoord;

uniform sampler3D displayTransformLut;

uniform sampler2D colortex11;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform sampler2D depthTexFront;
uniform sampler2D depthTexBack;
uniform sampler2D depthtex2;
uniform sampler2D depthtex1;

uniform sampler2D noisetex;

uniform vec3 sunPosition;
uniform vec3 cameraPosition;

uniform float centerDepthSmooth;
uniform float frameTime;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float rainStrength;
uniform float nightVision;

uniform int frameCounter;

#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Uniform/Matrices.glsl"
#include "../InternalLib/Debug.glsl"

/*******************************************************************************
 - Space Conversions
 ******************************************************************************/

vec3 CalculateViewSpacePosition(vec3 screenPos) {
	float fovScale = 1.0;
	screenPos = screenPos * 2.0 - 1.0;

	return projMAD(projMatrixInverse, screenPos) / (screenPos.z * projMatrixInverse[2].w + projMatrixInverse[3].w);
}

vec3 ViewSpaceToScreenSpace(vec3 viewPos) {
	return projMAD(projMatrix, viewPos) / -viewPos.z * 0.5 + 0.5;
}

float ScreenToViewSpaceDepth(float depth) {
   depth = depth * 2.0 - 1.0;
   return -1.0 / (depth * projMatrixInverse[2][3] + projMatrixInverse[3][3]);
}

vec3 CalculateNightVision(vec3 colorInput) {
	vec3 nightVisionColor = vec3(0.0, RGBToLuma(colorInput) * 10.0, 0.0);
	return mix(colorInput, nightVisionColor, nightVision);
}

/*******************************************************************************
  - Functions
 ******************************************************************************/

vec3 CalculateBloom(io vec3 color, float EV) {
	vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);

	const float scale0 = exp2(-2.0);
	const float scale1 = exp2(-3.0);
	const float scale2 = exp2(-4.0);
	const float scale3 = exp2(-5.0);
	const float scale4 = exp2(-6.0);
	const float scale5 = exp2(-7.0);

	vec3 bloom  = vec3(0.0);
		 bloom += DecodeRGBE8(texture2D(colortex3, texcoord * scale0 + vec2(0.0, 0.0))).rgb;
		 bloom += DecodeRGBE8(texture2D(colortex3, texcoord * scale1 + vec2(0.0, 0.25 + pixelSize.y * 2.0))).rgb;
		 bloom += DecodeRGBE8(texture2D(colortex3, texcoord * scale2 + vec2(0.125 + pixelSize.x * 2.0, 0.25 + pixelSize.y * 2.0))).rgb;
		 bloom += DecodeRGBE8(texture2D(colortex3, texcoord * scale3 + vec2(0.1875 + pixelSize.x * 4.0, 0.25 + pixelSize.y * 2.0))).rgb;
		 bloom += DecodeRGBE8(texture2D(colortex3, texcoord * scale4 + vec2(0.125 + pixelSize.x * 2.0, 0.3125 + pixelSize.y * 4.0))).rgb;
		 bloom += DecodeRGBE8(texture2D(colortex3, texcoord * scale5 + vec2(0.140625 + pixelSize.x * 4.0, 0.3125 + pixelSize.y * 4.0))).rgb;

	float bloomEV = EV + BLOOM_EV;

	return DecodeColor(bloom * 0.16666667) * (exp2(bloomEV - 3.0) * 0.5);
}

vec3 vignette(vec3 color, vec2 uv) {
    vec2 pos = (uv - 0.5) * aspectRatio * 2.0;

    float r = length(pos) * VIGNETTE_FALLOFF;
    float attenuation = 1.0 / pow(r * r + 1.0, 2.0);

    // Apply vignette
    return color * attenuation;
}

#include "../InternalLib/Fragment/Camera.fsh"
#include "../InternalLib/Fragment/PostProcess.fsh"
#include "../InternalLib/Fragment/ACES.glsl"

/*******************************************************************************
  - Toning
 ******************************************************************************/

vec3 ApplyDisplayTransform(vec3 stimulus) {
	stimulus = max0(stimulus);
	stimulus += 0.5 / 48.0;
    vec3 encoded = stimulus / (stimulus + 1.0);

    vec3 coord = encoded;
		 coord.y = 1.0 - coord.y;
    return texture(displayTransformLut, coord).rgb;
}

/* DRAWBUFFERS:0 */

void main() {
	float depth = texture2D(depthTexFront, texcoord).x;
	vec3 viewSpacePosition = CalculateViewSpacePosition(vec3(texcoord, depth));
	float normFactor = inversesqrt(dot(viewSpacePosition, viewSpacePosition));
	
	vec3 viewVector = viewSpacePosition * normFactor;
	
	vec3 currentColor = DecodeColor(DecodeRGBE8(texture2D(colortex2, texcoord)));
	float currentLum = texture2D(colortex5, texcoord).a * 10000.0;

	float EV = ComputeEV(currentLum); //No touch

	//Calculate Bloom
	vec3 bloomTiles = CalculateBloom(currentColor, EV);
	currentColor += bloomTiles;
	
	float rain = (1.0 - texture2D(colortex4, texcoord).a);
	float handMask = clamp01(float(texture2D(depthtex2, texcoord).x <= texture2D(depthtex1, texcoord).x));
	
	#ifdef BLOOM
		currentColor += rain * bloomTiles * handMask * RGBToLuma(bloomTiles) * 0.05;
	#else
		currentColor += rain * (currentColor * 0.16666667) * 8.0 * handMask;
	#endif

	#ifdef LENS_FLARE
		GetLensFlare(currentColor);
	#endif

	//Expose Final Color and bloom.
	currentColor *= EV;

	#ifdef VIGNETTE
		currentColor = vignette(currentColor, texcoord);
	#endif

	#ifdef TONING_FILMIC
		currentColor = (currentColor * 0.5) * sRGB_2_AP0;
		currentColor = FilmToneMap(currentColor);
		currentColor = linearToSrgb(currentColor);
	#else
		currentColor = ApplyDisplayTransform(currentColor);
	#endif

	//Write 8 bit final color.
	gl_FragData[0] = vec4(currentColor, 1.0);
}
