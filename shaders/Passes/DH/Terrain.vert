// ============================================================
// Next Continuum · Distant Horizon LOD 地形顶点程序（自研）
// 接口约定（Iris+DH）：gl_Vertex 为相机附近块网格坐标，需 fract(cameraPosition)
// 网格对齐；gl_MultiTexCoord0=图集 uv，gl_MultiTexCoord1=光照贴图，
// gl_Color=群系着色，gl_Normal=面法线；投影经 LodSupport（dhProjection）。
// ============================================================
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Syntax.glsl"
#include "../../InternalLib/Common/LodSupport.glsl"

uniform vec3 cameraPosition;

varying vec4 dh_color;
varying vec2 dh_texcoord;
varying vec2 dh_lmcoord;
varying vec3 dh_worldNormal;

void main() {
    vec3 camera_offset = fract(cameraPosition);
    vec3 snapped = floor(gl_Vertex.xyz + camera_offset + 0.5) - camera_offset;

    vec3 viewPos = transMAD(gl_ModelViewMatrix, snapped);
    gl_Position  = lod_projection_matrix * vec4(viewPos, 1.0);

    #ifdef TAA
        gl_Position.xy = SceneData.taaJitter * gl_Position.w + gl_Position.xy;
    #endif

    dh_color       = gl_Color;
    dh_texcoord    = gl_MultiTexCoord0.xy;
    dh_lmcoord     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    dh_worldNormal = mat3(gbufferModelViewInverse) * (mat3(gl_ModelViewMatrix) * gl_Normal);
}
