// ============================================================
// Next Continuum · Distant Horizon LOD 水面顶点程序（Iris DH 接口）
// DH transformer 已提供相机相对顶点位置及光照坐标；
// 不再自行 fract/floor 对齐，避免对 DH 网格进行二次位移。
// ============================================================
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Syntax.glsl"

varying vec4 dh_color;
varying vec2 dh_lmcoord;
varying vec3 dh_worldNormal;
varying vec3 dh_worldPos;
varying vec3 dh_viewPos;

void main() {
    vec3 viewPos = transMAD(gl_ModelViewMatrix, gl_Vertex.xyz);
    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef TAA
        gl_Position.xy = SceneData.taaJitter * gl_Position.w + gl_Position.xy;
    #endif

    dh_color = gl_Color;
    dh_lmcoord = gl_MultiTexCoord1.xy;
    dh_worldNormal = normalize(mat3(gl_ModelViewMatrixInverse) * gl_Normal);
    dh_worldPos = transMAD(gl_ModelViewMatrixInverse, viewPos);
    dh_viewPos = viewPos;
}
