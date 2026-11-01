// ============================================================
// Next Continuum · Distant Horizon LOD 地形片元程序（自研）
// 输出契约与 Passes/GBuffersMain.frag / GBuffersLOD.glsl 完全一致：
//   gl_FragData[0] = albedo (colortex0)
//   gl_FragData[1] = 0, lightmap, roughness|f0, shadow|matFlag (colortex1)
//   gl_FragData[2] = world normal *0.5+0.5 (colortex2)
// LOD 表面无视差/法线贴图：roughness=1, f0=0, shadow 中性(0.5), matFlag=0
// ============================================================
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Syntax.glsl"
#include "../../InternalLib/Common/LodSupport.glsl"

uniform sampler2D texture; // 方块图集（DH 绑定原版图集）

varying vec4 dh_color;
varying vec2 dh_texcoord;
varying vec2 dh_lmcoord;
varying vec3 dh_worldNormal;

void main() {
    vec4 baseColor = texture2D(texture, dh_texcoord) * dh_color;
    if (baseColor.a < 0.1) discard;

    #ifdef WHITE_WORLD
        baseColor = vec4(vec3(1.0), baseColor.a);
    #endif

    float dither = bayer16(gl_FragCoord.xy) * 0.00392157;

    gl_FragData[0] = vec4(baseColor.rgb, baseColor.a);
    gl_FragData[1] = vec4(0.0,
        EncodeVec2(dh_lmcoord.x + dither, dh_lmcoord.y + dither),
        EncodeVec2(1.0, 0.0),
        EncodeVec2(0.5, 0.0));
    gl_FragData[2] = vec4(dh_worldNormal * 0.5 + 0.5, 0.0);
}
