// ============================================================
// Next Continuum · Distant Horizon LOD 阴影顶点程序（Iris DH generic）
// Iris 的 DH generic transformer 会提供相机相对顶点、法线和颜色，
// 并把兼容矩阵重写为该 DH pass 实际使用的 iris_* 矩阵。
// DH generic 阶段没有普通方块图集 UV，因此不读取 gl_MultiTexCoord0。
// ============================================================
#include "../../InternalLib/Syntax.glsl"
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Uniform/ShadowDistortion.glsl"

varying vec4 dh_color;
varying vec3 dh_shadowNormal;

void main() {
    dh_color = gl_Color;
    dh_shadowNormal = normalize(gl_NormalMatrix * gl_Normal);

    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    gl_Position.xy = DistortShadowSpace(gl_Position.xy);
    gl_Position.z *= 0.25;
}
