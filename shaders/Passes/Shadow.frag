#extension GL_EXT_gpu_shader4 : enable
#define shadow

#include "../InternalLib/Syntax.glsl"

varying vec2 texcoord;
varying vec3 worldSpaceViewVector;
varying vec3 worldSpacePosition;
varying vec3 viewSpacePosition;

flat varying mat3 tbn;
flat varying vec3 normal;
flat varying vec4 color;

flat varying int blockID;

uniform sampler2D texture;

uniform sampler2D noisetex;

uniform sampler2D waveTex;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;
uniform float rainStrength;

#include "../InternalLib/Debug.glsl"
#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Fragment/WaterWaves.fsh"

void main() {
    if(!gl_FrontFacing && (blockID == 18 || blockID == 31 || blockID == 175 || blockID == 176)) discard;

    vec4 albedo = texture2D(texture, texcoord) * color;

	#ifdef WHITE_WORLD
		albedo = vec4(vec3(1.0), albedo.a);
	#endif

    float caustics = 1.0;

	albedo = (blockID == 51) ? vec4(0.0) : albedo;

    bool isWater = blockID == 8 || blockID == 9;
    
    if(isWater) {
        albedo = vec4(1.0);

        // https://medium.com/@evanwallace/rendering-realtime-caustics-in-webgl-2a99a29a0b2c
        #ifdef CAUSTICS
            vec3 waterNormal = (tbn * GetWavesLPF(waveTex, worldSpacePosition + cameraPosition, 1.0));
            vec3 newPos = viewSpacePosition + refract(vec3(0.0, 0.0, 1.0), waterNormal, 0.75);

            float oldArea = length(dFdx(viewSpacePosition)) * length(dFdy(viewSpacePosition));
            float newArea = length(dFdx(newPos)) * length(dFdy(newPos));

            caustics = newArea / oldArea * 0.002;
            caustics = pow(caustics, 0.7);
            albedo = vec4(vec3(caustics), 1.0);
        #endif
    }

    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(normal * 0.5 + 0.5, clamp01(float(isWater)));
}
