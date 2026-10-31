#include "../InternalLib/Syntax.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;
uniform sampler2D depthTexBackHistory;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor;
uniform sampler2D shadowcolor1;
uniform sampler2D colortex14;

uniform sampler2D colortex8;

uniform sampler2D noisetex;
uniform sampler2D blueNoiseTex;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float wetness;
uniform float eyeAltitude;
uniform float rainStrength;

uniform ivec2 eyeBrightnessSmooth;

uniform int worldTime;
uniform int isEyeInWater;
uniform int frameCounter;

#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Uniform/Matrices.glsl"
#include "../InternalLib/Debug.glsl"
#include "../InternalLib/Common/SpaceConversions.glsl"
#include "../InternalLib/Common/Reprojection.glsl"
#include "../InternalLib/Uniform/ShadowDistortion.glsl"
#include "../InternalLib/Fragment/GlobalIllumination.fsh"

/* RENDERTARGETS: 14 */

layout (location = 0) out vec4 outData0;

void main() {
    ivec2 iPos = ivec2(gl_FragCoord.xy);
    float depth = texture(depthtex1, texcoord).x;

    if (depth >= 1.0) {
        outData0 = vec4(0.0);
        return;
    }

	mat2x3 position;
	position[0] = CalculateViewSpacePosition(vec3(texcoord, depth));
	position[1] = CalculateWorldSpacePosition(position[0]);

    vec3 worldNormal = (texture(colortex8, texcoord).rgb * 2.0 - 1.0);
    vec3 normal = mat3(CameraTransforms.viewMatrix) * worldNormal;

    vec2 cameraVelocity = ComputeCameraVelocity(vec3(texcoord, depth));
    vec2 reprojectedCoord = texcoord - cameraVelocity;

    float dither = BlueNoiseTemporal(blueNoiseTex, iPos, frameCounter);

    vec3 currentGI = CalculateGlobalIllumination(position, normal, dither);
    vec3 previousGI = texture(colortex14, reprojectedCoord).rgb;

    float blendFactor = 0.85 * float(clamp01(reprojectedCoord) == reprojectedCoord) * float(!SceneData.sceneChange);
    vec3 GI = mix(currentGI, previousGI, blendFactor);

    outData0 = vec4(GI, 0.0);
}