// ============================================================
// Next Continuum · Distant Horizon LOD 地形片元程序（Iris DH 接口）
// 使用 Iris DHTerrainTransformer 注入的 dh_sampleTexture() /
// dh_hasTexture()，不把 DH 顶点 UV 当作普通方块图集 UV。
// 输出映射与普通地形一致：colortex0 / colortex1 / colortex8。
// ============================================================
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Syntax.glsl"

varying vec4 dh_color;
varying vec2 dh_lmcoord;
varying vec3 dh_worldNormal;

void main() {
    vec4 lodTexel = dh_hasTexture() ? dh_sampleTexture() : vec4(1.0);
    vec4 baseColor = lodTexel * dh_color;
    if (baseColor.a < 0.1) discard;

    #ifdef WHITE_WORLD
        baseColor = vec4(vec3(1.0), baseColor.a);
    #endif

    float dither = bayer16(gl_FragCoord.xy) * 0.00392157;

    /* DRAWBUFFERS:018 */
    gl_FragData[0] = vec4(baseColor.rgb, baseColor.a);
    gl_FragData[1] = vec4(0.0,
        EncodeVec2(dh_lmcoord.x + dither, dh_lmcoord.y + dither),
        EncodeVec2(1.0, 0.0),
        EncodeVec2(0.5, 0.0));
    gl_FragData[2] = vec4(normalize(dh_worldNormal) * 0.5 + 0.5, 0.0);
}
