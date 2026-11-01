// ============================================================
// Next Continuum · LOD 抽象层（自研）
// 唯一 LOD 语义入口：包内所有消费方只通过本文件暴露的统一名字
// 访问 LoD 模组（Distant Horizon / Voxy）的投影与深度。
// 运行时常量 DISTANT_HORIZONS / VOXY 由 Iris 在对应模组在场时注入，
// 二者运行时互斥；静态校验（无宏环境）下本文件展开为 no-op。
// 注：本文件只引用 Iris/DH/Voxy 约定的 uniform 接口名（公开接口事实），
// 实现逻辑独立撰写。
// ============================================================
#if !defined INCLUDE_NC_COMMON_LODSUPPORT
#define INCLUDE_NC_COMMON_LODSUPPORT

#if defined DISTANT_HORIZONS
// ---------------- Distant Horizon ----------------
// 合并投影矩阵由 Iris 直接提供（combined_projection_matrix_*），
// 不需要包内重建透视矩阵。
uniform mat4 dhProjection;
uniform mat4 dhProjectionInverse;
uniform mat4 dhPreviousProjection;
uniform float dhNearPlane;
uniform float dhFarPlane;
uniform int dhRenderDistance;
uniform sampler2D dhDepthTex;    // LoD 半透明面深度
uniform sampler2D dhDepthTex1;   // LoD 不透明面深度

uniform float combined_near;
uniform float combined_far;
uniform vec4 combined_projection_matrix_0;
uniform vec4 combined_projection_matrix_1;
uniform vec4 combined_projection_matrix_2;
uniform vec4 combined_projection_matrix_3;
uniform vec4 combined_projection_matrix_inverse_0;
uniform vec4 combined_projection_matrix_inverse_1;
uniform vec4 combined_projection_matrix_inverse_2;
uniform vec4 combined_projection_matrix_inverse_3;

#define LOD_PRESENT
#define lod_near_plane  dhNearPlane
#define lod_far_plane   dhFarPlane
#define lod_depth_tex          dhDepthTex
#define lod_depth_tex_solid    dhDepthTex1
#define lod_projection_matrix           dhProjection
#define lod_projection_matrix_inverse   dhProjectionInverse
#define lod_previous_projection_matrix  dhPreviousProjection
#define lod_render_distance_blocks (dhRenderDistance * 16)

#define combined_projection_matrix \
    mat4(combined_projection_matrix_0, combined_projection_matrix_1, \
         combined_projection_matrix_2, combined_projection_matrix_3)
#define combined_projection_matrix_inverse \
    mat4(combined_projection_matrix_inverse_0, combined_projection_matrix_inverse_1, \
         combined_projection_matrix_inverse_2, combined_projection_matrix_inverse_3)

#elif defined VOXY
// ---------------- Voxy ----------------
uniform mat4 vxProj;
uniform mat4 vxProjInv;
uniform mat4 vxProjPrev;
uniform int vxRenderDistance;
uniform sampler2D vxDepthTexOpaque;
uniform sampler2D vxDepthTexTrans;

#define LOD_PRESENT
#define lod_depth_tex          vxDepthTexTrans
#define lod_depth_tex_solid    vxDepthTexOpaque
#define lod_projection_matrix           vxProj
#define lod_projection_matrix_inverse   vxProjInv
#define lod_previous_projection_matrix  vxProjPrev
#define lod_render_distance_blocks (vxRenderDistance * 16)
// Voxy 通道的合并矩阵维持现状：由 B0_InitSSBOs 重建后写入 CameraTransforms
// （剪切分量丢失为已知债，见 docs/UPSTREAM-DIFF.md）。

#endif // DISTANT_HORIZONS / VOXY

// ---------------- 公共工具 ----------------
// 判断某像素的最前面几何是否来自 LoD（需两个深度：原版 front 与 LoD front）
bool nc_is_lod_terrain(float depthVanillaFront, float depthLodFront) {
    return depthVanillaFront >= 1.0 && depthLodFront < 1.0;
}

#endif // INCLUDE_NC_COMMON_LODSUPPORT
