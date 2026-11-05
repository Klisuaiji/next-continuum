#if !defined _MATERIALS_GLSL_
#define _MATERIALS_GLSL_

#define IsVeg(materialID) (materialID == 18 || materialID == 31 || materialID == 175 || materialID == 176)
#define IsWater(materialID) (materialID == 8 || materialID == 9)
#define IsEmitter(materialID) (materialID >= 32 && materialID <= 160)
#define IsNetherPortal(materialID) (materialID == 35)
#define IsLightningBolt(materialID) (materialID == 43)
#define IsStainedGlass(materialID) (materialID == 44)
#define IsHand(materialID) (materialID == 178)

vec4 GetLightColor(int blockID) {
	vec3 lightColor = vec3(0.0);
    float attenuation = 1.0; // 1.0 indicates the voxel is occupied.

    switch (blockID) {
        case 36: lightColor = normalize(blackbody(6500));          break;
        case 10: lightColor = vec3(1.00, 0.25, 0.00);   break;
        case 11: lightColor = vec3(1.00, 0.25, 0.00);   break;
        case 33: lightColor = normalize(blackbody(1000));   break;
        case 38: lightColor = vec3(1.00, 0.02, 0.02);   break;
        case 34: lightColor = vec3(0.00, 0.25, 1.00);   break;
        case 35: lightColor = vec3(0.5, 0.02, 1.00); break;
        case 32: lightColor = normalize(blackbody(2000));          break;
        case 37: lightColor = normalize(blackbody(3500)); break;
		case 39: lightColor = vec3(0.02, 1.0, 0.02); break;
        case 40: lightColor = vec3(1.0, 0.9, 1.0); break;
        case 41: lightColor = vec3(0.01); break;
        case 42: lightColor = normalize(blackbody(1000)); break;
        case 43: lightColor = vec3(0.2, 0.5, 1.0); break;
    }

    switch (blockID) {
        case 31: attenuation = 0.0; break;
        case 175: attenuation = 0.0; break;
        case 176: attenuation = 0.0; break;
        case 177: attenuation = 0.0; break;
    }

    attenuation = IsEmitter(blockID) || IsWater(blockID) ? 0.0 : attenuation;

	return vec4(lightColor, attenuation);
}

vec3 GetEmitterMask(vec3 albedo, int blockID) {
    vec3 newAlbedo = vec3(0.0);

    switch (blockID) {
        default: newAlbedo = pow(RGBToLuma(albedo), 8.0) * albedo * 50.0 + albedo * 0.5; break;
        case 35: newAlbedo = pow(RGBToLuma(albedo), 8.0) * albedo * 500.0; break;
        case 42: newAlbedo = albedo * PI; break;
        case 43: newAlbedo = albedo * LIGHTNING_BOLT_LUMINANCE; break;
    }

    return newAlbedo;

}

#endif // _MATERIALS_GLSL_