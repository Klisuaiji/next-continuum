# Continuum 2.0 Redux Build 2 (08.03.2026)

This shaderpack is a modification of Continuum 2.0.5. Unlike the original, this modification does not strictly pursue physical correctness, but it instead focuses on gameplay friendliness and stylization. 

Modern versions of Iris are required to run this shaderpack. **Do not expect this to run on OptiFine!**

## Features

This modification introduces a plethora of optimizations and new features: 

- Colored lighting via light propagation volumes (LPV)
- New water waves using the Tessendorf model
- Optimized volumetric light using froxels
- Approximate subsurface scattering on plants
- New volumetric cloud shaping using precomputed worley/perlin textures
- Support for LOD mods (voxy)
- Support for the nether and end dimensions
- Project-wide optimizations, tweaks and refinements

## Hardware requirements

Requires a modern graphics card supporting at least OpenGL 4.3. Do not expect this to run on integrated graphics.
Minimum (1080p): GTX 950 or equivalent
Recommended (1080p): GTX 1060 or equivalent

## Roadmap 

Below is a non-exhaustive list of features that may or may not be added.

# Medium term goals

- Cleanup for deferred8 and composite5 
- Cleanup internal libraries 
- Remove gbuffer matrix macros and replace them with SSBOS directly instead of using #defines

# Long term goals

- DH support
- Multiple cloud layers
- Investigate new temporal AA solution
- Add contrast adaptive sharpening
- Biome based weather
- Investigate nonlinear projection for cloud shadowmap