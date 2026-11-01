// ============================================================
// Next Continuum · Distant Horizon LOD 水面顶点程序（自研·S2 初版）
// 初版不做波浪顶点位移（与 Voxy LOD 初版能力对齐），仅网格对齐 + 透传。
// ============================================================
#include "../../InternalLib/Utilities.glsl"
#include "../../InternalLib/Syntax.glsl"
#include "../../InternalLib/Common/LodSupport.glsl"

uniform vec3 cameraPosition;

varying vec4 dh_color;
varying vec2 dh_texcoord;
varying vec2 dh_lmcoord;
varying vec3 dh_worldNormal;
varying vec3 dh_worldPos;

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
    dh_worldNormal = normalize(mat3(gbufferModelViewInverse) * (mat3(gl_ModelViewMatrix) * gl_Normal));
    dh_worldPos    = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
}
