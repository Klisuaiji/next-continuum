// ============================================================
// Next Continuum · Distant Horizon LOD 水面片元程序（Iris DH 接口）
// 视角相关项使用 view-space 方向；波浪采样使用 camera-relative
// world position + cameraPosition，避免把绝对位置当作视线方向。
// ============================================================
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Syntax.glsl"
#include "../../InternalLib/Fragment/WaterWaves.fsh"

uniform vec3 cameraPosition;
uniform sampler2D waveTex;

varying vec4 dh_color;
varying vec2 dh_lmcoord;
varying vec3 dh_worldNormal;
varying vec3 dh_worldPos;
varying vec3 dh_viewPos;

void main() {
    vec3 worldPosition = dh_worldPos + cameraPosition;
    vec3 viewDirection = normalize(-dh_viewPos);
    float NoV = dot(vec3(0.0, 1.0, 0.0), viewDirection);

    float roughness = 0.02 + 0.1 * (1.0 - pow(abs(NoV), 2.0));
    float f0 = 0.021;

    vec3 normal = GetWavesNormal(waveTex, worldPosition, NoV);
    normal = normal.rbg; // 与现有 LOD 水面法线通道约定一致

    float dither = bayer16(gl_FragCoord.xy) * 0.00392157;

    #ifdef WHITE_WORLD
        gl_FragData[0] = vec4(1.0, 1.0, 1.0, 0.0);
    #else
        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 0.0);
    #endif

    /* DRAWBUFFERS:018 */
    gl_FragData[1] = vec4(0.0,
        EncodeVec2(dh_lmcoord.x + dither, dh_lmcoord.y + dither),
        EncodeVec2(roughness, f0),
        EncodeVec2(1.0, 8.0 / 255.0));
    gl_FragData[2] = vec4(normal * 0.5 + 0.5, 0.0);
}
