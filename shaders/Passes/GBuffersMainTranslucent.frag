#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_texture_lod : enable

#define ShaderStage 9
// #define DISABLE_MATRIX_OVERRIDE

#include "../InternalLib/Syntax.glsl"

varying vec4 color;
varying vec3 worldSpacePosition;
varying vec2 texcoord;
varying vec2 lmcoord;

flat varying mat3 tbn;
flat varying vec3 lightVector;
flat varying vec3 tbnNormal;
flat varying float material;
flat varying vec2 midCoord;
flat varying vec2 tileSize;
flat varying float parallaxDepth;
flat varying vec2 wrap;

varying vec3 tangentSpaceViewVector;

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;

uniform sampler2D noisetex;
uniform sampler2D waveTex;

#if defined DISABLE_MATRIX_OVERRIDE
	uniform mat4 gbufferProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
#endif

uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float rainStrength;

uniform int frameCounter;

#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Fragment/TerrainParallax.fsh"
#include "../InternalLib/Debug.glsl"

#if defined gbuffers_water
	#include "../InternalLib/Fragment/WaterWaves.fsh"
    #include "../InternalLib/Fragment/WaterParallax.fsh"
#endif

vec4 RenderFancyNetherPortal(const vec2 coord, const mat2 texD, const sampler2D atlasTex) {
    vec3 step = normalize(tangentSpaceViewVector);
         step = length(step.xy * texD) * step;
            
    bool fix = step.z < -1e-5; // prevent infinite loops at extreme grazing angles (needs to be inside the loop to make retarded nvidia drivers happy)
    vec3 p = vec3(coord, 0.0);
    
    vec4 albedo = vec4(0.0);
    const int steps = 32;

    for(int i = 0; i < steps; i++) {
        albedo += texture2DGradARB(atlasTex, wrapCoord(p.xy), texD[0], texD[1]) * exp(-i * 0.01);
        p += step;
    } 

	albedo.a = 0.5;
    
    return albedo / float(steps);
}

/* DRAWBUFFERS:108 */

void main() {
    bool isWater = material == 8.0 || material == 9.0;

	mat2 texD = mat2(dFdx(texcoord), dFdy(texcoord));

	vec3 tangentVector = -normalize(tangentSpaceViewVector);

	vec3 viewVector = -normalize(worldSpacePosition);
	float dither = bayer64(gl_FragCoord.xy);
    
    #ifdef TAA
	      dither = fract(frameCounter * 0.109375 + dither);
    #endif

    vec4 data0 = texture2DGradARB(texture,  texcoord, texD[0], texD[1]);
	vec4 data1 = texture2DGradARB(normals,  texcoord, texD[0], texD[1]);
	vec4 data2 = texture2DGradARB(specular, texcoord, texD[0], texD[1]);

    vec4 albedo = data0 * color;

	if (material == 35) {
        albedo = RenderFancyNetherPortal(texcoord, texD, texture);
    } 

	#ifdef WHITE_WORLD
		albedo = vec4(1.0);
	#endif

    float roughness = 1.0 - data2.z;
    float f0 = data2.x;

	vec3 normal = clampNormal(data1.xyz * 2.0 - 1.0, tangentVector);
		 normal = data1.xyz == vec3(0, 0, 0) ? vec3(0, 0, 1) : normal;

    #if defined gbuffers_water
        if (isWater) {
            float NoV = dot(vec3(0.0, 1.0, 0.0), normalize(worldSpacePosition.xyz));

            albedo = vec4(0.0, 0.0, 0.0, 0.0);
            roughness = 0.02 + 0.1 * (1.0 - pow(abs(NoV), 2.0));
            f0 = 0.021;
			normal = GetWavesNormal(waveTex, GetWaterParallaxCoord(waveTex, worldSpacePosition + cameraPosition, -tangentVector), NoV);
        }
    #endif

	normal = tbn * normal;

	float matFlag = material < 0.0 ? 0.0 : material;

    #if !defined gbuffers_hand_water
        gl_FragData[0] = vec4(EncodeNormal(normal), EncodeVec2(lmcoord.x, lmcoord.y), EncodeVec2(roughness, f0), EncodeVec2(1.0, matFlag / 255.0));
    #endif
    
	gl_FragData[1] = vec4(albedo.rgb, albedo.a);
	gl_FragData[2] = vec4(normal * 0.5 + 0.5, 0.0);
}