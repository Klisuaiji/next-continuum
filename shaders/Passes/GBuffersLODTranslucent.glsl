layout (location = 0) out vec4 outData0;
layout (location = 1) out vec4 outData1;
layout (location = 2) out vec4 outData2;

#define gbuffers_water // some libraries require this.

#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Syntax.glsl"
#include "../InternalLib/Fragment/WaterWaves.fsh"
#include "../InternalLib/Fragment/WaterParallax.fsh"

void voxy_emitFragment(VoxyFragmentParameters parameters) {
    vec2 nCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    vec3 screenCoord = vec3(nCoord, gl_FragCoord.z);
         screenCoord = screenCoord * 2.0 - 1.0;

    float dither = bayer16(gl_FragCoord.xy) * 0.00392157;

    vec4 viewSpacePosition = vxProjInv * vec4(screenCoord, 1.0);
         viewSpacePosition.xyz /= viewSpacePosition.w;
         viewSpacePosition.w = 1.0;

    vec4 worldSpacePosition = vxModelViewInv * viewSpacePosition;

    vec4 baseColor = parameters.sampledColour * parameters.tinting;

    vec3 baseNormal = vec3(
		uint((parameters.face >> 1) == 2), 
		uint((parameters.face >> 1) == 0), 
		uint((parameters.face >> 1) == 1)
	) * (float(int(parameters.face) & 1) * 2.0 - 1.0);

    float roughness = 1.0;
    float f0 = 0.04;

    float material = parameters.customId;
    bool isWater = material == 8.0 || material == 9.0;

    if (isWater) {
        float NoV = dot(vec3(0.0, 1.0, 0.0), normalize(worldSpacePosition.xyz));

        baseColor = vec4(0.0, 0.0, 0.0, 0.0);
        roughness = 0.02 + 0.1 * (1.0 - pow(abs(NoV), 2.0));
        f0 = 0.021;
        baseNormal = GetWavesNormal(waveTex, worldSpacePosition.xyz + cameraPosition, NoV);
        baseNormal = baseNormal.rbg; // ?
    }

    float matFlag = material < 0.0 ? 0.0 : material;

    outData0 = baseColor;
    outData1 = vec4(0.0, EncodeVec2(parameters.lightMap.x + dither, parameters.lightMap.y + dither), EncodeVec2(roughness, f0), EncodeVec2(1.0, matFlag / 255.0));
    outData2 = vec4(baseNormal * 0.5 + 0.5, 0.0);
}