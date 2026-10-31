#define final

#include "../InternalLib/Syntax.glsl"

varying vec2 texcoord;

uniform sampler3D colorLookup3D;

uniform sampler2D colortex4;
uniform sampler2D colortex15;
uniform sampler2D lutTexture;
uniform sampler2D blueNoiseTex;

uniform float aspectRatio;
uniform float centerDepthSmooth;
uniform float viewWidth;
uniform float viewHeight;
uniform float nightVision;
uniform float frameTimeCounter;

uniform int frameCounter;

#include "../InternalLib/Uniform/Matrices.glsl"
#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Debug.glsl"
#include "../InternalLib/Fragment/PostProcess.fsh"
#include "../InternalLib/Fragment/ACES.glsl"

/*******************************************************************************
  - Main
 ******************************************************************************/

void main() {
	ColorCorrection m;
	m.lum = vec3(0.2125, 0.7154, 0.0721);
	m.saturation = 1.0 + SAT_MOD;
	m.vibrance = VIB_MOD;
	m.contrast = 1.0 - CONT_MOD * 0.5;
	m.contrastMidpoint = CONT_MIDPOINT;

	m.gain = vec3(1.0, 1.0, 1.0) + GAIN_MOD; //Tint Adjustment
	m.lift = vec3(0.0, 0.0, 0.0) + LIFT_MOD * 0.01; //Tint Adjustment
	m.InvGamma = vec3(GAMMA_CORRECTION);

	vec3 color = srgbToLinear(texture2D(colortex4, texcoord).rgb);

	color = WhiteBalance(color);
	color = Vibrance(color, m);
	color = Saturation(color, m);
	color = Contrast(color, m);
	color = LiftGammaGain(color, m);
	color = linearToSrgb(color);
	color = clamp01(color);

	#ifdef LUT
	color = Lookup(color, lutTexture);
	#endif

	#ifdef LUT_3D
	color = texture(colorLookup3D, color).rgb;
	#endif

	#if defined DEBUG
	color = texture(colortex15, texcoord).rgb;
	#endif

	gl_FragColor = vec4(color, 1.0);
}
