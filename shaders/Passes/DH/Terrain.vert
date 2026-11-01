// ============================================================
// Next Continuum · Distant Horizon LOD 地形顶点程序（Iris DH 接口）
// Iris 的 DH transformer 已将顶点位置、法线、颜色和光照坐标
// 转换为 DH 专用输入；gl_MultiTexCoord0 不可用于方块图集 UV。
// ============================================================
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Syntax.glsl"

varying vec4 dh_color;
varying vec2 dh_lmcoord;
varying vec3 dh_worldNormal;

void main() {
    // Iris rewrites these compatibility built-ins to the DH program's
    // iris_ModelViewMatrix / iris_ProjectionMatrix uniforms.
    vec3 viewPos = transMAD(gl_ModelViewMatrix, gl_Vertex.xyz);
    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef TAA
        gl_Position.xy = SceneData.taaJitter * gl_Position.w + gl_Position.xy;
    #endif

    dh_color = gl_Color;
    dh_lmcoord = gl_MultiTexCoord1.xy;
    dh_worldNormal = normalize(mat3(gl_ModelViewMatrixInverse) * gl_Normal);
}
