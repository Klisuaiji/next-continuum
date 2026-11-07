// ============================================================
// Continua 1.0 · Distant Horizons LOD 地形片元程序（Iris 1.21.1）
// Iris 1.8.x 不提供 DH 纹理 API：dh_hasTexture() / dh_sampleTexture()
// 属于新版 Iris 的 DISTANT_HORIZONS_TEXTURES 分支（该宏在本平台不存在）。
// DH 顶点数据已把方块颜色烘焙进 gl_Color，因此直接以顶点色作为 albedo，
// 与 Complementary Reimagined 的 dh_terrain 实现一致。
// 输出映射与普通地形一致：colortex0 / colortex1 / colortex8。
// ============================================================
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Syntax.glsl"

varying vec4 dh_color;
varying vec2 dh_lmcoord;
varying vec3 dh_worldNormal;

void main() {
    vec4 baseColor = dh_color;
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
