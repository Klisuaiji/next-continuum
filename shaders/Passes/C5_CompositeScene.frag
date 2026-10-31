#extension GL_EXT_gpu_shader4 : enable

#define composite0
#define ShaderStage 10

#include "/InternalLib/Syntax.glsl"

varying vec2 texcoord;

uniform sampler3D cloudNoiseTex;
uniform sampler3D curlNoiseTex;
uniform sampler3D lightPropagationVolume_r;
uniform sampler3D integratedScattering;
uniform sampler3D integratedTransmittance;

uniform sampler2D waveTex;
uniform sampler2D blueNoiseTex;
uniform sampler2D curlNoiseTex2D;

uniform sampler2D skyScatteringTex;
uniform sampler2D skyTransmittanceTex;
uniform sampler2D cloudTexUpscaled;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex12;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor;
uniform sampler2D shadowcolor1;

uniform sampler2D vxDepthTexOpaque;
uniform sampler2D vxDepthTexTrans;
uniform sampler2D depthTexFront;
uniform sampler2D depthTexBack;

uniform sampler2D noisetex;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

uniform vec4 lightningBoltPosition;

uniform vec3 sunPosition; // We might need to add moonPosition back.
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 eyePosition;

uniform vec2 viewDimensions;

uniform float viewWidth;
uniform float viewHeight;
uniform float wetness;
uniform float frameTimeCounter;
uniform float sunAngle;
uniform float eyeAltitude;
uniform float rainStrength;
uniform float nightVision;

uniform int worldTime;
uniform int isEyeInWater;
uniform int frameCounter;
uniform int heldItemId;
uniform int heldItemId2;

uniform ivec2 eyeBrightnessSmooth;

#include "../InternalLib/Utilities.glsl"
#include "../InternalLib/Uniform/Matrices.glsl"
#include "../InternalLib/Debug.glsl"
#include "../InternalLib/Common/Froxels.glsl"
#include "../InternalLib/Common/SpaceConversions.glsl"


/*******************************************************************************
 - Lookups
 ******************************************************************************/

float GetDepth(vec2 coord) {
    return texture2D(depthTexFront, coord).x;
}

vec3 GetAlbedo(vec3 data) {
    return srgbToLinear(data);
}

vec3 GetNormal(float data) {
    return mat3(gbufferModelView) * (ScreenTex(colortex8).rgb * 2.0 - 1.0);
}

void GetLightmaps(float data, out float torchLightmap, out float skyLightmap) {
    vec2 temp = DecodeVec2(data);

    torchLightmap = temp.x;
    skyLightmap = temp.y;
}

vec3 SampleFroxels(vec3 background, vec3 screenCoord) {
	#ifndef VOLUMETRIC_LIGHT 
		return background;
	#endif 
	
	screenCoord.x += (BlueNoiseTemporal(blueNoiseTex, ivec2(screenCoord.xy * viewDimensions), frameCounter) * 2.0 - 1.0) * 0.01;
    screenCoord.y += (BlueNoiseTemporal(blueNoiseTex, ivec2(screenCoord.xy * viewDimensions), frameCounter + 1) * 2.0 - 1.0) * 0.01;

	screenCoord.xyz = ScreenSpaceToFroxelSpace(screenCoord);

    vec3 scattering = texture(integratedScattering, screenCoord).rgb;
    vec3 transmittance = texture(integratedTransmittance, screenCoord).rgb;

    return background * transmittance + scattering;
}

vec3 SampleFroxels(vec3 background, vec2 nCoord, vec3 viewPos) {
	#ifndef VOLUMETRIC_LIGHT 
		return background;
	#endif 

	nCoord.x += (BlueNoiseTemporal(blueNoiseTex, ivec2(nCoord * viewDimensions), frameCounter) * 2.0 - 1.0) * 0.01;
    nCoord.y += (BlueNoiseTemporal(blueNoiseTex, ivec2(nCoord * viewDimensions), frameCounter + 1) * 2.0 - 1.0) * 0.01;

	vec3 froxelCoord = ViewSpaceToFroxelSpace(nCoord, viewPos);

    vec3 scattering = texture(integratedScattering, froxelCoord).rgb;
    vec3 transmittance = texture(integratedTransmittance, froxelCoord).rgb;

    return background * transmittance + scattering;
}

vec3 SampleSky(vec3 background, vec2 nCoord, out vec3 transmittance) {
	nCoord.x += (BlueNoiseTemporal(blueNoiseTex, ivec2(nCoord.xy * viewDimensions), frameCounter) * 2.0 - 1.0) * 0.01;
    nCoord.y += (BlueNoiseTemporal(blueNoiseTex, ivec2(nCoord.xy * viewDimensions), frameCounter + 1) * 2.0 - 1.0) * 0.01;

	vec3 scattering = texture(skyScatteringTex, nCoord).rgb;
	transmittance = texture(skyTransmittanceTex, nCoord).rgb;

	return scattering + background * transmittance;
}

vec3 GetCloudLightningBoltContribution(vec3 position) {
	if (lightningBoltPosition.w < 1.0) return vec3(0.0);

	return 1000000.0 * lightningBoltPosition.w * LIGHTNING_BOLT_LUMINANCE * GetLightColor(43).rgb / pow2(distance(lightningBoltPosition.xz, position.xz));
}

vec3 SampleClouds(vec3 background, vec3 sky, vec2 nCoord, float depth, vec3 viewPos, vec3 worldPos, out vec3 viewPosClouds) {
	#if !defined VOLUMETRIC_CLOUDS
		viewPosClouds = viewPos;
		return background;
	#endif

	float terrainDistance = length(viewPos);
	vec3 viewVector = normalize(viewPos);
	vec3 worldVector = normalize(worldPos);
	vec4 clouds = texture(cloudTexUpscaled, nCoord);

    vec3 skyScattering = vec3(0.0);
    vec3 skyTransmittance = vec3(1.0);

    skyScattering = SampleSky(vec3(0.0), nCoord, skyTransmittance);
	
	float cloudDistance = clouds.a;
	float transmittanceWeightedDis = min(clouds.a / clamp01(0.99 - clouds.b), terrainDistance);
	float combinedDistance = min(terrainDistance, clouds.a);

	if (combinedDistance < terrainDistance || depth >= 1.0) {
		viewPosClouds = transmittanceWeightedDis * viewVector;

		vec3 scattering = SceneData.sunColor * clouds.r;
			 scattering += SceneData.skyColor * clouds.g;
			 scattering += (clouds.g + clouds.r) * GetCloudLightningBoltContribution(combinedDistance * worldVector);

		float transmittance = clouds.b;
		float fogFactor = 1.0 - exp(-cloudDistance * 0.00003);
			  fogFactor *= 1.0 - exp(-0.1 * max0(VOLUMETRIC_CLOUDS_ALTITUDE - cameraPosition.y));

		return mix(background * clouds.b + scattering, sky, fogFactor);
	} else {
		viewPosClouds = terrainDistance * viewVector;
		return background;
	}
}

/*******************************************************************************
 - Includes
 ******************************************************************************/

#include "../InternalLib/Common/Rand.glsl"
#include "../InternalLib/Common/Voxelization.glsl"
#include "../InternalLib/Fragment/Sky.fsh"
#include "../InternalLib/Fragment/SpecularLighting.fsh"
#include "../InternalLib/Fragment/Clouds2D.fsh"
#include "../InternalLib/Fragment/Clouds.fsh"
#include "../InternalLib/Fragment/DiffuseLighting.fsh"
#include "../InternalLib/Fragment/VolumetricRenderer.fsh"

/*******************************************************************************
 - Functions
 ******************************************************************************/

void GetRoughnessF0(float data, out float roughness, out float f0, mat2x3 position, vec3 normal, float skyLightmap, bool isTransparent) {
	float puddles = getRainPuddles(position[1], normal, skyLightmap) * (1.0 - float(isTransparent));
    vec2 temp = DecodeVec2(data);

    roughness = temp.x;
    roughness = mix(roughness, 0.05, puddles);

	f0 = temp.y;
    f0 = mix(f0, 0.021, puddles);
}

vec3 RenderTranslucents(vec3 background, vec4 transparentGeometry, vec3 viewVector, vec3 lightVector, vec3 normal, vec3 worldNormal, vec3 shadows, vec3 sunLightColor, vec3 skyLightColor, float skyLightmap, float torchLightmap, bool isWater, mat2x3 position, mat2x3 backPosition, int materialID) {
	if (IsNetherPortal(materialID)) {
		float edge = exp(10.0 * -distance(backPosition[0], position[0]));
		return background + pow(RGBToLuma(transparentGeometry.rgb * 10.0), 5.0) * transparentGeometry.rgb * 50000.0 + edge * GetLightColor(35).rgb * 10000.0;
	} 

	background *= mix(vec3(1.0), transparentGeometry.rgb, clamp(transparentGeometry.a, 0.9, 1.0) * float(!isWater)); //Absorb Light through transparents.

	vec3 litTransparentGeometry = clamp01(dot(normal, lightVector)) * shadows * sunLightColor; //Light Forward Facing Transparents
	     litTransparentGeometry += skyLightColor * pow2(skyLightmap); //Skylight

	if (IsOutOfBounds(position[1]))
        litTransparentGeometry += CalculateTorchLightmap(GetTorchLightmapDistance(torchLightmap), true);
    else
        litTransparentGeometry += GetLPVContribution(lightPropagationVolume_r, position[1], worldNormal);

	return mix(background, litTransparentGeometry.rgb * transparentGeometry.rgb, transparentGeometry.a);
}

/* DRAWBUFFERS:5 */

void main() {
	InitRand(uint(gl_FragCoord.x + viewWidth * gl_FragCoord.y) + (uint(viewWidth) * uint(viewHeight) * floatBitsToUint(frameTimeCounter)));

	float depth = GetDepth(texcoord);
	float backDepth = texture2D(depthTexBack, texcoord).x;

    mat2x3 position;
    position[0] = CalculateViewSpacePosition(vec3(texcoord, depth));
    position[1] = CalculateWorldSpacePosition(position[0]);

    mat2x3 backPosition;
    backPosition[0] = CalculateViewSpacePosition(vec3(texcoord, backDepth));
    backPosition[1] = CalculateWorldSpacePosition(backPosition[0]);

	vec4 data1 = ScreenTex(colortex1);
	vec3 normal = GetNormal(data1.x);

	vec2 decodeData1Alpha = DecodeVec2(data1.a);
	int materialID = int(floor(decodeData1Alpha.y * 255));

	vec3 viewVector = -normalize(position[0]);
	vec3 worldVector = normalize(position[1] - CameraTransforms.viewMatrixInverse[3].xyz);

	float dither = bayer64(gl_FragCoord.st);

	#ifdef TAA
          dither = fract(frameCounter * 0.109375 + dither);
    #endif

	bool isTransparent = backDepth > depth;
	vec2 coord = texcoord;
	vec3 sky = vec3(0.0);
	vec3 viewAbsorb = vec3(1.0);

	// Refract
	#ifdef REFRACTION
		if (isTransparent) {
			vec3 flatNormal = clamp(normalize(cross(dFdx(position[0]), dFdy(position[0]))), -1.0, 1.0);
			vec3 rayDirection = refract(viewVector, normal - flatNormal, 0.75);
			vec3 refractedPosition = rayDirection * abs(distance(position[1], backPosition[1])) / position[0].z + position[0];
			     refractedPosition = ViewSpaceToScreenSpace(refractedPosition);
			     refractedPosition.z = texture2D(depthTexBack, refractedPosition.xy).x;

	        if(refractedPosition.z > texture2D(depthTexFront, refractedPosition.xy).x) {
				coord = refractedPosition.xy;
				backDepth = refractedPosition.z;

	            backPosition[0] = CalculateViewSpacePosition(refractedPosition);
	            backPosition[1] = CalculateWorldSpacePosition(backPosition[0]);

				float normFactor = inversesqrt(dot(backPosition[0], backPosition[0]));
	            viewVector = normFactor * -backPosition[0];
				worldVector = normalize(backPosition[1] - CameraTransforms.viewMatrixInverse[3].xyz);
	        }
		}
	#endif

	float VoL = dot(worldVector, SceneData.wLightVector);
	float VoS = dot(worldVector, SceneData.wSunVector);

	VolumetricData vd = CalculateVolumetricVariables(viewVector, VoL);
	vec3 backWorldVector = mat3(gbufferModelViewInverse) * -viewVector;
	//Calculate Sky
	
	#if defined DIM_OVERWORLD
		vec3 sunMoonSpot = CalculateSunSpot(VoS) * sky_sunColor + CalculateMoonSpot(-VoS) * sky_moonColor;
		sky += sunMoonSpot;
		sky += calculateStars(backWorldVector, SceneData.wLightVector);
	#elif defined DIM_END
		vec3 endDisk = CalculateEndDisk(curlNoiseTex2D, noisetex, -viewVector, backWorldVector);
		sky += endDisk;
	#endif

	vec3 atmosphericScattering = SampleSky(sky, coord, viewAbsorb);

	sky = atmosphericScattering;
	sky = CalculatePlanarClouds(sky, backWorldVector, VoL);

	//Bring in lit world
	vec3 data2 = max0(DecodeRGBE8(texture2D(colortex2, coord)));
	vec3 solidGeometry = data2.rgb + sky * float(backDepth >= 1.0);

	float roughness, f0, skyLightmap, torchLightmap;
    GetLightmaps(data1.y, torchLightmap, skyLightmap);
    GetRoughnessF0(data1.z, roughness, f0, position, normal, skyLightmap, isTransparent);

	bool isWater = IsWater(materialID);

	//Bring in semis
	vec4 albedo = texture2D(colortex0, texcoord);
		 albedo.rgb = srgbToLinear(albedo.rgb);

	vec3 shadows = vec3(1.0);
	
	shadows = CalculateShadows(WorldSpaceToShadowSpace(position[1]), normal, dither, false, 1.0);
	shadows *= SampleCloudShadowMap(colortex10, position[1]);
	shadows *= SceneData.transitionFading;

	if(isTransparent) {
		vec3 cloudViewPos = vec3(0.0);
		solidGeometry = SampleClouds(solidGeometry, atmosphericScattering, coord, backDepth, backPosition[0], backPosition[1], cloudViewPos);
		solidGeometry = SampleFroxels(solidGeometry, coord, cloudViewPos);
		solidGeometry = RenderTranslucents(solidGeometry, albedo, viewVector, SceneData.lightVector, normal, mat3(gbufferModelViewInverse) * normal, shadows, vd.sunlightColor, SceneData.skyColor, skyLightmap, torchLightmap, isWater, position, backPosition, materialID);
	}

	// Render translucents after water fog because otherwise translucents will just render over fog underwater
	if (isWater || isEyeInWater == 1) {
		solidGeometry = CalculateVolumetricWater(vd, solidGeometry, isEyeInWater == 1 ? gbufferModelViewInverse[3].xyz : position[1], isEyeInWater == 1 ? position[1] : backPosition[1], VoL, dither);
	}

	if (isEyeInWater == 0) {
		if (depth < 1.0) CalculateSpecularReflections(solidGeometry, albedo.rgb, position, viewVector, vec3(texcoord, depth), normal, roughness, f0, skyLightmap, shadows, dither, isTransparent, materialID);
		vec3 endPos = isEyeInWater == 1 ? backPosition[1] : position[1];

		#ifdef DISTANCE_FADE
			float fog = length(position[1].xz) / (CameraTransforms.farPlane * 0.7);
			fog = 1.0 - exp(-0.1 * pow(fog, 10.0));
			fog = clamp01(fog);
				
			if (depth < 1.0) solidGeometry = mix(solidGeometry, sky, fog);
		#endif

		vec3 cloudViewPos = vec3(0.0);
		solidGeometry = SampleClouds(solidGeometry, atmosphericScattering, coord, depth, position[0], position[1], cloudViewPos);
		solidGeometry = SampleFroxels(solidGeometry, coord, cloudViewPos);
	}

	solidGeometry = any(isinf(solidGeometry)) ? vec3(0.0) : solidGeometry;
    solidGeometry = any(isnan(solidGeometry)) ? vec3(0.0) : solidGeometry;

    gl_FragData[0] = vec4(EncodeColor(solidGeometry), texture2D(colortex5, texcoord).a);
}
