/*******************************************************************************
 - Advanced Settings (staged feature framework)
   Roadmap toggles from the "2.1.3 -> 2.0 base" porting design. Each feature is
   staged (default OFF, commented) until its compute/render body is implemented
   and verified on a real client. Enabling these currently changes nothing.
   Reference provenance is kept per file so a later 2.1.x rebase stays easy.

   IMPORTANT: do NOT un-comment a toggle below without also implementing the
   matching pass, or the option would show in the menu with no effect.
 ******************************************************************************/

// ---------------------------------------------------------------------------
// M1 - GPU auto-exposure (histogram pipeline)
// Reference: 2.1.3 passes/camera/genHistogram.comp + exposeImage.comp +
//            internalLib/ssbo/autoExposureHistogram.glsl
// Wiring: histogram SSBO (bufferObject.4+) -> luminance stat -> EV, fed to
//         Camera.fsh ComputeEV(); manual camera mode fully bypasses it.
// Status: STAGED (compute body pending, needs in-client verification)
//#define AUTO_EXPOSURE

// ---------------------------------------------------------------------------
// M2 - GTAO four-stage pipeline (replaces the plain AO path)
// Reference: 2.1.3 passes/ambientLighting/ao/GTAO{,BlurX,BlurY,Temporal}.comp
// Wiring: new AO path kept behind this toggle; old AO kept as fallback.
// Status: STAGED (compute body pending)
//#define AO_GTAO

// ---------------------------------------------------------------------------
// M3 - Compositing infrastructure: HiZ pyramid + motion vectors + linear depth
// Reference: 2.1.3 createHiZ.comp / genMotionVector.comp /
//            writeLinearDepths.comp / copyBackGbufferToFront.comp
// Wiring: feeds HiZ-SSR and LodSupport (DH/Voxy) depth.
// Status: STAGED (compute body pending)
//#define HIZ_ACCEL

// ---------------------------------------------------------------------------
// M4 - HiZ-accelerated screen-space ray tracing
// Reference: 2.1.3 continuumLib/raytracer/screenSpaceRaytracer.glsl + HiZ
// Wiring: GPU-driven sorting (RayList/IndirectArgs/bindless) is NOT ported
//         (Iris has no indirect dispatch); uses HiZ march + fixed dispatch.
// Status: STAGED (compute body pending)
//#define HIZ_SSR

// ---------------------------------------------------------------------------
// M5 - Precomputed sky + fog height-density LUT
// Reference: 2.1.3 precomputedSky.glsl / raymarchSky/* /
//            passes/camera/genFogHeightDensitiesLut.comp
// Wiring: couples with clouds / volumetric light / DH fog - implement last.
// Status: STAGED (compute body pending)
//#define PRECOMPUTED_SKY

// ---------------------------------------------------------------------------
// M6 - Full ACES (RRT + ODT + tonescales)
// Reference: 2.1.3 continuumLib/aces/* (5 files); helpers already present in
//            InternalLib/Fragment/ACESSplines.glsl + ACESTransforms.glsl
// Wiring: activate RRT()/ODT_sRGB_D65() in C7 before the filmic/display path.
// Status: STAGED (tonemap body pending)
//#define FULL_ACES
