/* Copyright (C) Continuum Graphics - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Joseph Conover <support@continuum.graphics>, January 2018
 */

//http://gdcvault.com/play/1024478/PBR-Diffuse-Lighting-for-GGX
#define ggxDiffuse_facing LoV * 0.5 + 0.5
#define ggxDiffuse_rough (ggxDiffuse_facing * (0.9 - 0.4 * ggxDiffuse_facing) * clamp01(0.5 / NoH + 1.0))
#define ggxDiffuse_smooth 1.05 * (1.0 - pow5(1.0 - NoL)) * (1.0 - pow5(1.0 - NoV))
#define ggxDiffuse_single (mix(ggxDiffuse_smooth, ggxDiffuse_rough, alpha))

float ggxDiffuseModifier(float alpha, float NoL, float NoV, float NoH, float LoV) {
    return 0.1159 * alpha + ggxDiffuse_single;
}

vec3 ggxDiffuse(vec3 diffuseColor, float NoH, float NoV, float LoV, float NoL, float alpha) {
    float multi = 0.1159 * alpha;
    return diffuseColor * (diffuseColor * multi + ggxDiffuse_single);
}

vec3 ggxDiffuse(vec3 diffuseColor, vec3 V, vec3 L, vec3 N, float alpha) {
    float NoH = dotNorm(V + L, N);
    float NoV = dot(V, N);
    float LoV = dot(L, V);
    float NoL = dot(L, N);
	
    return ggxDiffuse(diffuseColor, NoH, NoV, LoV, NoL, alpha) * clamp01(NoL);
}

#if defined deffered0
#include "/InternalLib/Fragment/SkyLighting.fsh"
#include "/InternalLib/Fragment/SpecularLighting.fsh"
#endif

#if defined deffered0 || defined composite0

#include "/InternalLib/Uniform/ShadowDistortion.glsl"
#include "/InternalLib/Fragment/Shadows.fsh"
#include "/InternalLib/Fragment/WaterWaves.fsh"
#include "/InternalLib/Fragment/Caustics.fsh"
#include "/InternalLib/Fragment/GlobalIllumination.fsh"

float GetTorchLightmapDistance(float lightmap) {
	return clamp((1.0 - lightmap) * 16.0, 1.0, 16.0);
}

vec3 CalculateTorchLightmap(float dist, bool islightmap) {
	const float torchLuminance = TORCH_LUMINANCE; // Correct Lum
    vec3 torchColor = blackbody(TORCH_TEMPERATURE);

    float squareDistance = dist * dist;
  	float atten = (torchLuminance / squareDistance) * (islightmap ? smoothstep(256, 16.0, squareDistance) : 1.0);

	return torchColor * (atten * PI);
}

vec3 CalculateHandlight(float dist, vec3 albedo, vec3 viewVector, vec3 lightVector, vec3 normal, float alpha) {
	bool mask = heldItemId == 32 || heldItemId == 50 || heldItemId == 169 || heldItemId == 198;
	if (!mask) return vec3(0.0);
	dist = max(1.0, dist);

	return CalculateTorchLightmap(dist, false) * ggxDiffuse(albedo, viewVector, lightVector, normal, alpha);
}

float CalculateUndergroundShadowMask(float surfaceSkylight, float eyeSkylight) {
    float surfaceMask = clamp01(surfaceSkylight * 10.0 - 1.0);
    float eyeMask = clamp01(eyeSkylight * 4.0);
    eyeMask = pow4(eyeMask);

    return surfaceMask * (1.0 - eyeMask) + eyeMask;
}

float RenderScreenSpaceShadows(
    vec3 rayOrigin,
    vec3 rayDirection,
    vec3 surfaceNormal,
    float jitter,
    vec3 screenHitPosition,
    bool isVeg
) {
    const int steps = DISTANT_SHADOW_QUALITY;
    float maxRayDistance = -CameraTransforms.nearPlane - rayOrigin.z;

    // Hack for fake SSS. 
    if (isVeg) {
        rayDirection += RandNext3F();
        rayDirection = normalize(rayDirection);
    }

    vec3 screenDirection = normalize(
        ViewSpaceToScreenSpace(rayDirection * maxRayDistance + rayOrigin) - screenHitPosition
    );

    float stepSize = 0.05 / float(steps);
    vec3 rayPosition = screenHitPosition + screenDirection * stepSize * (jitter * 0.5 + 0.5);


    for (int i = 0; i < steps; i++) {
        float sampledDepth = texture(depthTexBack, rayPosition.xy).x;

        // Out of bounds
        if (clamp01(rayPosition.xy) != rayPosition.xy) 
            return 1.0;

        // Intersection
        if (sampledDepth < rayPosition.z && abs(sampledDepth - rayPosition.z) < 0.0001) 
            return 0.0;

        rayPosition += screenDirection * stepSize;
    }

    return 1.0;
}

float RenderContactShadows(
    vec3 rayOrigin,
    vec3 rayDirection,
    vec3 surfaceNormal,
    float jitter,
    vec3 screenHitPosition,
    bool isVeg
) {
    if (isVeg) return 1.0;

    const int steps = CONTACT_SHADOW_QUALITY;
    float maxRayDistance = -CameraTransforms.nearPlane - rayOrigin.z;

    vec3 screenDirection = normalize(
        ViewSpaceToScreenSpace(rayDirection * maxRayDistance + rayOrigin) - screenHitPosition
    );

    float stepSize = 0.1 / (float(steps) * length(rayOrigin));
    vec3 rayPosition = screenHitPosition + screenDirection * stepSize * (jitter * 0.5 + 0.5);

    for (int i = 0; i < steps; i++) {
        float sampledDepth = texture(depthTexBack, rayPosition.xy).x;

        // Out of bounds
        if (clamp01(rayPosition.xy) != rayPosition.xy) 
            return 1.0;

        // Intersection
        if (sampledDepth < rayPosition.z) {
            // Check depth difference 
            float linearDepth = ScreenToViewSpaceDepth(sampledDepth);
            float linearZPos = ScreenToViewSpaceDepth(rayPosition.z);

            if (abs(linearDepth - linearZPos) < 0.01) return 0.0;
        }

        rayPosition += screenDirection * stepSize;
    }

    return 1.0;
}

vec3 GetLightningBoltContributionDiffuse(vec3 position, vec3 normal) {
	if (lightningBoltPosition.w < 1.0) return vec3(0.0);

    vec3 vectorToBolt = lightningBoltPosition.xyz - position;
    vec3 direction = normalize(vectorToBolt);
    float distanceToBolt = length(vectorToBolt);

    float NoL = dot(normal, direction);
	
	return abs(NoL + 0.5) * 100000.0 * lightningBoltPosition.w * LIGHTNING_BOLT_LUMINANCE * GetLightColor(43).rgb / pow2(distanceToBolt);
}

vec3 GetHandLight(vec3 worldPos, vec3 normal) {
    vec3 lightPos = eyePosition - cameraPosition - vec3(0.0, 0.5, 0.0) - mat3(CameraTransforms.viewMatrixInverse) * vec3(-0.5, 0.0, 0.0);
    vec3 lightColor = GetLightColor(heldItemId).xyz;
    vec3 directionToLight = lightPos - worldPos;
    float distanceToLight = distance(worldPos, lightPos);

    return lightColor * TORCH_LUMINANCE * 4 * PI * exp(-distanceToLight);
}

vec3 GetSecondaryHandLight(vec3 worldPos, vec3 normal) {
    vec3 lightPos = eyePosition - cameraPosition - vec3(0.0, 0.5, 0.0) - mat3(CameraTransforms.viewMatrixInverse) * vec3(0.5, 0.0, 0.0);
    vec3 lightColor = GetLightColor(heldItemId2).xyz;
    vec3 directionToLight = lightPos - worldPos;
    float distanceToLight = distance(worldPos, lightPos);

    return lightColor * TORCH_LUMINANCE * 4 * PI * exp(-distanceToLight);
}

vec3 CalculateLighting(vec3 pixelPos, mat2x3 position, vec3 albedo, vec3 viewVector, vec3 normal, vec3 worldNormal, vec2 lightmaps, float normFactor, float roughness, float f0, float jitter, inout vec3 shadows, int materialID) {
    float alpha = roughness * roughness;
	vec3 shadowPosition = WorldSpaceToShadowSpace(position[1]);
    float cloudShadow = SampleCloudShadowMap(colortex10, position[1], RandNext2F());

    vec3 handPosition = position[1] - vec3(0.0, 1.5, 0.0);
    vec3 handVector = normalize(-handPosition);

    bool isVeg = IsVeg(materialID);
    bool isEmitter = IsEmitter(materialID);

    #ifdef UNDERGROUND_LIGHT_LEAK_FIX
        float undergroundLeakFix = CalculateUndergroundShadowMask(lightmaps.y, eyeBrightnessSmooth.y / 240.0);
    #else
        #define undergroundLeakFix 1.0
    #endif

    float VoL = dot(viewVector, SceneData.lightVector);

    shadows *= CalculateShadows(shadowPosition, normal, jitter, isVeg, (1.0 - cloudShadow) * 5.0 + 1.0) * cloudShadow;

    #ifdef CONTACT_SHADOWS_ENABLED
        shadows *= RenderContactShadows(position[0], SceneData.lightVector, normal, jitter, pixelPos, isVeg);
    #endif

    shadowPosition.xy = DistortShadowSpaceProj(shadowPosition.xy);

    float shadowBlendFactor = GetShadowBlendFactor(position[1]);
    
    #ifdef DISTANT_SHADOWS_ENABLED
        shadows = mix(RenderScreenSpaceShadows(position[0], SceneData.lightVector, normal, jitter, pixelPos, isVeg) * vec3(1) * cloudShadow, shadows, shadowBlendFactor);
    #endif

	float hCone = 0.0;

    vec3 diffuse  = ggxDiffuse(albedo, viewVector, SceneData.lightVector, normal, alpha);
         diffuse  = mix(diffuse, albedo * rPI * (sky_miePhase(VoL, 0.66) + 2.0 + (1.5 * shadowBlendFactor)), float(isVeg) * 0.5);

         diffuse *= SceneData.sunColor * SceneData.transitionFading * 2.0; 
         diffuse *= shadows * undergroundLeakFix; //Multiply By Shadows
	#ifdef CAUSTICS
         diffuse *= mix(1.0, RenderWaterCaustics(shadowPosition.xy, abs(texture2D(shadowtex1, shadowPosition.xy).x - texture2D(shadowtex0, shadowPosition.xy).x) * 1024.0), shadowBlendFactor);
	#endif

    // Sky lighting.
	#if defined deffered0
        diffuse += CalculateSkyConeDiffuse(position[0], normal, normFactor, viewVector, alpha, jitter, hCone) * albedo * (lightmaps.y * lightmaps.y); 
        diffuse += GetLightningBoltContributionDiffuse(position[1], worldNormal) * albedo;
        #if defined DIM_OVERWORLD
            diffuse += hCone * albedo * AMBIENT_LUM_OVERWORLD;
        #elif defined DIM_NETHER
            diffuse += hCone * albedo * AMBIENT_LUM_NETHER_TOTAL;
        #elif defined DIM_END
            diffuse += hCone * albedo * AMBIENT_LUM_END_TOTAL;
        #endif

        diffuse += NIGHT_VISION_STRENGTH * albedo * hCone * nightVision;
	#endif

    #ifdef EMITTER_MASKS
        float lightMod = float(!isEmitter);
    #else 
        const float lightMod = 1.0;
    #endif

    // Block lighting.
    if (IsOutOfBounds(position[1])) {
        diffuse += CalculateTorchLightmap(GetTorchLightmapDistance(lightmaps.x), true) * albedo * hCone * lightMod;
    } else {
        diffuse += GetLPVContribution(lightPropagationVolume_r, position[1], worldNormal) * albedo * hCone * lightMod;
    }

    #if defined COLORED_LIGHTING && defined HANDHELD_LIGHTS
        diffuse += GetHandLight(position[1], worldNormal) * albedo * hCone * lightMod;
        diffuse += GetSecondaryHandLight(position[1], worldNormal) * albedo * hCone * lightMod;

        /*#ifdef EMITTER_MASKS
            if (IsHand(materialID) && IsEmitter(heldItemId)) {
                diffuse += GetEmitterMask(albedo, heldItemId) * GetLightColor(heldItemId).rgb * TORCH_LUMINANCE;
            }

            if (IsHand(materialID) && IsEmitter(heldItemId2)) {
                diffuse += GetEmitterMask(albedo, heldItemId2) * GetLightColor(heldItemId2).rgb * TORCH_LUMINANCE;
            }
        #endif*/
    #endif

    #ifdef EMITTER_MASKS
        if (isEmitter) {
            diffuse += GetEmitterMask(albedo, materialID) * GetLightColor(materialID).rgb * TORCH_LUMINANCE * PI;
        }
    #endif

    // GI.
	#ifdef GLOBAL_ILLUMINATION
         diffuse += texture(colortex7, pixelPos.xy).rgb * SceneData.sunColor * albedo * (cloudShadow * (1.0 - isEyeInWater) * undergroundLeakFix);
	#endif

	vec3 specular = CalclulateBRDF(viewVector, SceneData.lightVector, normal, albedo, pow2(alpha), f0) * SceneData.sunColor * shadows * undergroundLeakFix;

    return BlendMaterial(diffuse, max0(specular), albedo, f0);
}

#endif
