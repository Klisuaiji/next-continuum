// ============================================================
// Next Continuum · Distant Horizon LOD 水面片元程序（自研·S2 尾注）
// 波浪法线取 GetWavesNormal(waveTex, worldPos + cameraPosition, NoV)，
// 与 Passes/GBuffersLODTranslucent.glsl（Voxy 通道）完全同源同参；
// roughness/f0 公式亦对齐 Voxy 通道。DH 的 dh_water 程序组即水面。
// ============================================================
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Syntax.glsl"
#include "../../InternalLib/Common/LodSupport.glsl"
#include "../../InternalLib/Fragment/WaterWaves.fsh"

uniform sampler2D texture;
uniform sampler2D waveTex;
uniform vec3 cameraPosition;

varying vec4 dh_color;
varying vec2 dh_texcoord;
varying vec2 dh_lmcoord;
varying vec3 dh_worldNormal;
varying vec3 dh_worldPos;

void main() {
    float NoV = dot(vec3(0.0, 1.0, 0.0), normalize(dh_worldPos + cameraPosition));

    float roughness = 0.02 + 0.1 * (1.0 - pow(abs(NoV), 2.0));
    float f0 = 0.021;

    vec3 normal = GetWavesNormal(waveTex, dh_worldPos + cameraPosition, NoV);
    normal = normal.rbg; // 对齐 Voxy 通道同源处理

    float dither = bayer16(gl_FragCoord.xy) * 0.00392157;

    #ifdef WHITE_WORLD
        gl_FragData[0] = vec4(1.0, 1.0, 1.0, 0.0);
    #else
        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 0.0); // 水体 albedo 置空，与 Voxy 通道一致
    #endif

    gl_FragData[1] = vec4(0.0,
        EncodeVec2(dh_lmcoord.x + dither, dh_lmcoord.y + dither),
        EncodeVec2(roughness, f0),
        EncodeVec2(1.0, 8.0 / 255.0));
    gl_FragData[2] = vec4(normal * 0.5 + 0.5, 0.0);
}
