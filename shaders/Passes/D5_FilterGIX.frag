#include "/InternalLib/Syntax.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform sampler2D colortex8;
uniform sampler2D colortex14;

uniform sampler2D noisetex;
uniform sampler2D blueNoiseTex;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;

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

/* RENDERTARGETS: 7 */

layout (location = 0) out vec4 outData0;

float GetDepthWeight(float centerDepth, vec2 currentCoord) {
    float currentDepth = ScreenToViewSpaceDepth(texture(depthtex1, currentCoord).x);

    if (abs(centerDepth - currentDepth) > 0.5) return 0.0;
    return 1.0;
}

float GetNormalWeight(vec3 centerNormal, vec2 currentCoord) {
    vec3 currentNormal = texture(colortex8, currentCoord).rgb * 2.0 - 1.0;
         currentNormal = mat3(CameraTransforms.viewMatrix) * currentNormal;

    if (any(greaterThan(abs(centerNormal - currentNormal), vec3(0.25)))) return 0.0;

    return 1.0;
}

vec3 FilterGI(vec2 nCoord, vec3 normal, float depth) {
    const float weights[3] = float[3](0.375, 0.25, 0.0625);

    vec3 sum = vec3(0.0);
    float weightSum = 0.0;

    for (int i = -2; i <= 2; i++) {
        vec2 currentCoord = nCoord + vec2(i * 4.0 / viewWidth, 0.0);
        float weight = weights[abs(i)] * GetNormalWeight(normal, currentCoord) * GetDepthWeight(depth, currentCoord);
              weightSum += weight;
        sum += texture(colortex14, currentCoord).rgb * weight;
    }

    return sum / weightSum;
}

void main() {
    ivec2 iPos = ivec2(gl_FragCoord.xy);
    float depth = texture(depthtex1, texcoord).x;
    float depth2 = texture(depthtex2, texcoord).x;

    if (depth >= 1.0 || depth2 > depth) {
        outData0 = vec4(0.0);
        return;
    }

	mat2x3 position;
	position[0] = CalculateViewSpacePosition(vec3(texcoord, depth));
	position[1] = CalculateWorldSpacePosition(position[0]);

    vec3 worldNormal = (texture(colortex8, texcoord).rgb * 2.0 - 1.0);
    vec3 normal = mat3(CameraTransforms.viewMatrix) * worldNormal;

    float dither = BlueNoiseTemporal(blueNoiseTex, iPos, frameCounter);

    vec3 GI = FilterGI(texcoord, normal, position[0].z).rgb;

    outData0 = vec4(GI, 0.0);
}