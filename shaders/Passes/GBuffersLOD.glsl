layout (location = 0) out vec4 outData0;
layout (location = 1) out vec4 outData1;
layout (location = 2) out vec4 outData2;

#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Syntax.glsl"

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
    float f0 = 0.0;

    #ifdef WHITE_WORLD
        baseColor = vec4(vec3(1.0), baseColor.a);
    #endif

    outData0 = baseColor;
    outData1 = vec4(0.0, EncodeVec2(parameters.lightMap.x + dither, parameters.lightMap.y + dither), EncodeVec2(roughness, f0), EncodeVec2(1.0, parameters.customId / 255.0));
    outData2 = vec4(baseNormal * 0.5 + 0.5, 0.0);
}