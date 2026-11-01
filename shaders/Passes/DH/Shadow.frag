// ============================================================
// Next Continuum · Distant Horizon LOD 阴影片元程序（自研）
// 输出契约对齐 Passes/Shadow.frag：FragData0=albedo（彩色阴影/吸收），
// FragData1=normal*0.5+05|isWater。水体与 cutout 透明像素 discard，
// LOD 不写体素光照网格（无 blockID 语义），不接 caustics。
// ============================================================
#include "../../InternalLib/Syntax.glsl"
#include "../../InternalLib/Utilities.glsl"

uniform sampler2D texture;

varying vec2 dh_texcoord;
varying vec4 dh_color;
varying vec3 dh_shadowNormal;
flat varying int dh_isWater;

void main() {
    if (dh_isWater == 1) discard;

    vec4 baseColor = texture2D(texture, dh_texcoord) * dh_color;
    if (baseColor.a < 0.1) discard;

    gl_FragData[0] = vec4(baseColor.rgb, baseColor.a);
    gl_FragData[1] = vec4(dh_shadowNormal * 0.5 + 0.5, 0.0);
}
