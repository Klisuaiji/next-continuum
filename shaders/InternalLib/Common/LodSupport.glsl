// ============================================================
// Next Continuum · LOD 抽象层（自研）
// 唯一 LOD 语义入口：包内消费方通过统一名称访问 DH / Voxy。
// Iris 的 DH 专用程序使用 iris_ProjectionMatrix /
// iris_ModelViewMatrix（由 gl_* 内建矩阵重写而来）；
// 普通合成阶段没有可用的 dhProjection uniform，因此深度重建
// 使用 DH near/far + 当前视场构造透视矩阵，不伪造 Iris uniform。
// ============================================================
#if !defined INCLUDE_NC_COMMON_LODSUPPORT
#define INCLUDE_NC_COMMON_LODSUPPORT

#if defined DISTANT_HORIZONS
// ---------------- Distant Horizons ----------------
uniform float dhNearPlane;
uniform float dhFarPlane;
uniform int dhRenderDistance;
uniform sampler2D dhDepthTex0;
uniform sampler2D dhDepthTex1;

#define LOD_PRESENT
#define lod_near_plane dhNearPlane
#define lod_far_plane dhFarPlane
#define lod_depth_tex dhDepthTex0
#define lod_depth_tex_solid dhDepthTex1
#define lod_projection_matrix GenPerspectiveMat(fov, aspectRatio, dhNearPlane, dhFarPlane)
#define lod_projection_matrix_inverse inverse(GenPerspectiveMat(fov, aspectRatio, dhNearPlane, dhFarPlane))
#define lod_render_distance_blocks (dhRenderDistance * 16)

#elif defined VOXY
// ---------------- Voxy ----------------
uniform mat4 vxProj;
uniform mat4 vxProjInv;
uniform mat4 vxProjPrev;
uniform int vxRenderDistance;
uniform sampler2D vxDepthTexOpaque;
uniform sampler2D vxDepthTexTrans;

#define LOD_PRESENT
#define lod_depth_tex vxDepthTexTrans
#define lod_depth_tex_solid vxDepthTexOpaque
#define lod_projection_matrix vxProj
#define lod_projection_matrix_inverse vxProjInv
#define lod_previous_projection_matrix vxProjPrev
#define lod_render_distance_blocks (vxRenderDistance * 16)
// Voxy 通道的合并矩阵维持现状：由 B0_InitSSBOs 重建后写入 CameraTransforms。

#endif // DISTANT_HORIZONS / VOXY

// ---------------- 公共工具 ----------------
bool nc_is_lod_terrain(float depthVanillaFront, float depthLodFront) {
    return depthVanillaFront >= 1.0 && depthLodFront < 1.0;
}

#endif // INCLUDE_NC_COMMON_LODSUPPORT
