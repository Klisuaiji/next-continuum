// ============================================================
// Next Continuum · Distant Horizon LOD 阴影片元程序（Iris DH generic）
// DH generic program 不提供普通方块图集采样；使用 Iris 传入的顶点颜色。
// LOD 阴影初版不区分 block mini-ID，后续再补材质级 cutout / water 规则。
// ============================================================
#include "../../InternalLib/Syntax.glsl"

varying vec4 dh_color;
varying vec3 dh_shadowNormal;

void main() {
    if (dh_color.a < 0.1) discard;

    gl_FragData[0] = vec4(dh_color.rgb, dh_color.a);
    gl_FragData[1] = vec4(normalize(dh_shadowNormal) * 0.5 + 0.5, 0.0);
}
