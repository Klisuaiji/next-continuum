#if !defined _VOXELIZATION_GLSL_
#define _VOXELIZATION_GLSL_

// X and Z dimensions of the voxel volume
#define VOXEL_VOLUME_XZ_DIM 256
#define VOXEL_VOLUME_Y_OFFSET 128
#define VOXEL_VOLUME_HEIGHT 256

vec3 WorldSpaceToVoxelSpace(vec3 worldPosition) {
    worldPosition.xyz += fract(cameraPosition.xyz);
    worldPosition.y  += VOXEL_VOLUME_Y_OFFSET;
    return worldPosition;
}

ivec3 GetVoxelStoragePos(vec3 worldPosition) {
	vec3 voxelPosition = WorldSpaceToVoxelSpace(worldPosition);

    ivec3 iPos = ivec3(floor(voxelPosition));
    return ivec3(
        iPos.x + VOXEL_VOLUME_XZ_DIM / 2,
        iPos.y,
        iPos.z + VOXEL_VOLUME_XZ_DIM / 2
    );
}

vec3 VoxelSpaceToWorldSpace(ivec3 iPos) {
    vec3 pos = vec3(
        iPos.x - VOXEL_VOLUME_XZ_DIM / 2,
        iPos.y,
        iPos.z - VOXEL_VOLUME_XZ_DIM / 2
    );

    pos.y  -= VOXEL_VOLUME_Y_OFFSET;
    pos.xyz -= fract(cameraPosition.xyz);

    return pos;
}

bool IsOutOfBounds(ivec3 iPos) {
    #ifndef COLORED_LIGHTING
        return true;
    #endif 
    
	const int xzRadius = VOXEL_VOLUME_XZ_DIM / 2;
	const ivec3 lowerLimit = ivec3(-xzRadius, 0, -xzRadius);
	const ivec3 upperLimit = ivec3(xzRadius - 1, VOXEL_VOLUME_HEIGHT, xzRadius - 1);

	return clamp(iPos, lowerLimit, upperLimit) != iPos;
}

bool IsOutOfBounds(vec3 worldPos) {
    ivec3 iPos = ivec3(WorldSpaceToVoxelSpace(worldPos));

    return IsOutOfBounds(iPos);
}

vec3 GetLPVContribution(sampler3D LPV, vec3 worldPos, vec3 worldNormal) {
	vec3 voxelPos = WorldSpaceToVoxelSpace(worldPos + worldNormal * 0.5);

	if (IsOutOfBounds(ivec3(voxelPos))) return vec3(0.0);

	voxelPos += vec3(VOXEL_VOLUME_XZ_DIM / 2, 0, VOXEL_VOLUME_XZ_DIM / 2);
	vec3 sampleCoord = (voxelPos) / vec3(VOXEL_VOLUME_XZ_DIM, VOXEL_VOLUME_HEIGHT, VOXEL_VOLUME_XZ_DIM);

	return pow(texture(LPV, sampleCoord).rgb, vec3(1.0)) * float(TORCH_LUMINANCE) * 4 * PI;
}

vec3 GetLPVContribution(sampler3D LPV, vec3 worldPos) {
	return GetLPVContribution(LPV, worldPos, vec3(0.0, 0.0, 0.0));
}

#endif // _VOXELIZATION_GLSL_