#extension GL_EXT_gpu_shader4 : enable
#define deffered0
#define ShaderStage 0

#include "../InternalLib/Syntax.glsl"

varying vec2 texcoord;

uniform sampler3D cloudNoiseTex;
uniform sampler3D curlNoiseTex;
uniform sampler3D lightPropagationVolume_r;

uniform sampler2D waveTex;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex4;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex10;

uniform sampler2D vxDepthTexOpaque;
uniform sampler2D depthTexBack;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor;
uniform sampler2D shadowcolor1;
uniform sampler2D noisetex;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform vec4 lightningBoltPosition;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 eyePosition;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float wetness;
uniform float eyeAltitude;
uniform float rainStrength;
uniform float nightVision;

uniform ivec2 eyeBrightnessSmooth;

uniform int worldTime;
uniform int isEyeInWater;
uniform int frameCounter;
uniform int heldItemId;
uniform int heldItemId2;

#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Uniform/Matrices.glsl"
#include "../InternalLib/Debug.glsl"

/*******************************************************************************
 - Settings
 ******************************************************************************/

/*
const int colortex0Format = RGBA8; //Albedo
const int colortex1Format = RGBA16; //Big Data
const int colortex2Format = RGBA8; //Color Pass
const int colortex3Format = RGBA8; //SkyDome/BloomTiles
const int colortex4Format = RGBA8; //TAA Feedback
const int colortex5Format = RGBA16F; //Loddable Color/Previous Lum
const int colortex6Format = RGBA16F;
const int colortex7Format = R11F_G11F_B10F; // GI
const int colortex8Format = RGB16;
const int colortex9Format = RGB16F;
const int colortex10Format = R16F;
const int colortex12Format = R32F;
const int colortex13Format = RG16F;
const int colortex14Format = R11F_G11F_B10F;

const bool shadowtex0Mipmap = false;
const bool shadowtex1Mipmap = false;
const bool shadowcolor0Mipmap = false;
const bool shadowcolor1Mipmap = false;

const bool colortex0Clear = false;
const bool colortex1Clear = false;
const bool colortex3Clear = false;
const bool colortex4Clear = false;
const bool colortex5Clear = false;
const bool colortex6Clear = false;
const bool colortex7Clear = false;
const bool colortex8Clear = false;
const bool colortex9Clear = false;
const bool colortex10Clear = false;
const bool colortex11Clear = false;
const bool colortex12Clear = false;
const bool colortex13Clear = false;
const bool colortex14Clear = false;
const bool colortex15Clear = true;

const float sunPathRotation = -25.0;

const float ambientOcclusionLevel = 0.0;

const float eyeBrightnessHalflife = 1.0;

const float wetnessHalflife = 180.0;
const float drynessHalflife = 180.0;
*/

/*******************************************************************************
 - Lookups
 ******************************************************************************/

float GetDepth(vec2 coord) {
    return texture2D(depthTexBack, coord).x;
}

vec3 GetAlbedo(vec3 data) {
    return srgbToLinear(data);
}

vec3 GetNormal(float data, out vec3 worldNormal) {
    worldNormal = (texture(colortex8, texcoord).rgb * 2.0 - 1.0);
    return mat3(gbufferModelView) * worldNormal;
}


void GetLightmaps(float data, out float torchLightmap, out float skyLightmap) {
    vec2 temp = DecodeVec2(data);

    torchLightmap = temp.x;
    skyLightmap = temp.y;
}

vec3 FromSH(vec4 cR, vec4 cG, vec4 cB, vec3 lightDir) {
    const float sqrt1OverPI = sqrt(rPI);
    const float sqrt3OverPI = sqrt(3.0 * rPI);
    const vec2 halfnhalf = vec2(0.5, -0.5);
    const vec2 sqrtOverPI = vec2(sqrt1OverPI, sqrt3OverPI);
    const vec4 foo = halfnhalf.xyxy * sqrtOverPI.xyyy;

    vec4 sh = foo * vec4(1.0, lightDir.yzx);

    // know to work
    return vec3(
        dot(sh,cR),
        dot(sh,cG),
        dot(sh,cB)
    );
}


/*******************************************************************************
 - Includes
 ******************************************************************************/

#include "../InternalLib/Common/SpaceConversions.glsl"
#include "../InternalLib/Common/Rand.glsl"
#include "../InternalLib/Common/Voxelization.glsl"
#include "../InternalLib/Fragment/Sky.fsh"
#include "../InternalLib/Fragment/Clouds2D.fsh"
#include "../InternalLib/Fragment/Clouds.fsh"
#include "../InternalLib/Fragment/DiffuseLighting.fsh"

/*******************************************************************************
 - Functions
 ******************************************************************************/

void GetRoughnessF0(float data, out float roughness, out float f0, mat2x3 position, vec3 normal, float skyLightmap) {
	float puddles = getRainPuddles(position[1], normal, skyLightmap);
    vec2 temp = DecodeVec2(data);

    roughness = temp.x;
    roughness = mix(roughness, 0.05, puddles);

	f0 = temp.y;
    f0 = mix(f0, 0.021, puddles);
}

/* DRAWBUFFERS:23 */

void main() {
    InitRand(uint(gl_FragCoord.x + viewWidth * gl_FragCoord.y) + (uint(viewWidth) * uint(viewHeight) * floatBitsToUint(frameTimeCounter)));

    float depth = GetDepth(texcoord);
    float luminancePassthrough = texture2D(colortex4, texcoord).a;

	float dither = bayer64(gl_FragCoord.st);

    #ifdef TAA
          dither = fract(frameCounter * 0.109375 + dither);
    #endif

    if(depth >= 1.0) { // Write to passthrough buffer and return early if the fragment belongs to the sky.
        gl_FragData[0] = vec4(0.0);
        return;
    }

	mat2x3 position;
	position[0] = CalculateViewSpacePosition(vec3(texcoord, depth));
	position[1] = CalculateWorldSpacePosition(position[0]);

    float normFactor = inversesqrt(dot(position[0], position[0]));
    vec3 viewVector = normFactor * -position[0];

    vec4 data0 = ScreenTex(colortex0);
    vec4 data1 = ScreenTex(colortex1);
	
	vec3 worldNormal = vec3(0.0);
    vec3 albedo     = GetAlbedo(data0.xyz);
    vec3 normal     = GetNormal(data1.x, worldNormal);

    float roughness, f0, skyLightmap, torchLightmap;
    GetLightmaps(data1.y, torchLightmap, skyLightmap);
    GetRoughnessF0(data1.z, roughness, f0, position, normal, skyLightmap);

	vec2 decodeData1Alpha = DecodeVec2(data1.a);

    int materialID = int(floor(decodeData1Alpha.y * 255));
    vec3 shadows = vec3(decodeData1Alpha.x * 2.0 - 1.0);

    vec3 finalColor = CalculateLighting(vec3(texcoord, depth), position, albedo, viewVector, normal, worldNormal, vec2(torchLightmap, skyLightmap), normFactor, roughness, f0, dither, shadows, materialID);

    gl_FragData[0] = EncodeRGBE8(finalColor);
}