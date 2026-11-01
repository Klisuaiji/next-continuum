// ============================================================
// Next Continuum · Distant Horizon LOD 阴影顶点程序（自研）
// 语义（Bliss/Photon 参考 + Iris compat/dh DHCompatInternal L82 核验）：
//   shadow 程序的 gl_Vertex 已是相机原系（无网格对齐、无 fract snap）；
//   投影链完全沿用本包 Passes/Shadow.vert：gl_ProjectionMatrix(Iris 换入
//   阴影投影) → DistortShadowSpace → z*=0.25，保证与主 shadow pass 同一
//   深度/扭曲体系，deferred 采样端零特判。
// ============================================================
#include "../../InternalLib/Syntax.glsl"
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Uniform/ShadowDistortion.glsl"

varying vec2 dh_texcoord;
varying vec4 dh_color;
varying vec3 dh_shadowNormal;
flat varying int dh_isWater;

void main() {
    dh_texcoord = gl_MultiTexCoord0.st;
    dh_color    = gl_Color;
    dh_isWater  = gl_Color.a < 1.0 ? 1 : 0; // DH LOD 水体顶点色 alpha<1（Bliss 同款接口惯例）

    vec3 viewPos = transMAD(gl_ModelViewMatrix, gl_Vertex.xyz);
    vec3 world   = transMAD(shadowModelViewInverse, viewPos);
    vec3 shadowView = transMAD(shadowModelView, world);

    dh_shadowNormal = (gl_NormalMatrix * gl_Normal) * mat3(shadowModelView);

    gl_Position = shadowView.xyzz * diagonal4(gl_ProjectionMatrix) + gl_ProjectionMatrix[3];
    gl_Position.xy = DistortShadowSpace(gl_Position.xy);
    gl_Position.z *= 0.25;
}
