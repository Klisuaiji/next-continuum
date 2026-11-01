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
// Status: IMPLEMENTED (bufferObject.4/binding=4 SSBO + A0/A1/A2 compute + C7 feed;
//         enable via the EXPERIMENTAL screen). Needs in-client verification.
//#define AUTO_EXPOSURE

// ---------------------------------------------------------------------------
// M2 - GTAO four-stage pipeline (replaces the plain AO path)
// Reference: 2.1.3 passes/ambientLighting/ao/GTAO{,BlurX,BlurY,Temporal}.comp
// Wiring: new AO path kept behind this toggle; old AO kept as fallback.
// Status: BLOCKED by the 16/16 image-slot ceiling (no free 2D target; see review).
//#define AO_GTAO

// ---------------------------------------------------------------------------
// M3 - Compositing infrastructure: HiZ pyramid + motion vectors + linear depth
// Reference: 2.1.3 createHiZ.comp / genMotionVector.comp /
//            writeLinearDepths.comp / copyBackGbufferToFront.comp
// Wiring: feeds HiZ-SSR and LodSupport (DH/Voxy) depth.
// Status: BLOCKED by the 16/16 image-slot ceiling (needs a mipmapped HiZ target).
//#define HIZ_ACCEL

// ---------------------------------------------------------------------------
// M4 - HiZ-accelerated screen-space ray tracing
// Reference: 2.1.3 continuumLib/raytracer/screenSpaceRaytracer.glsl + HiZ
// Wiring: GPU-driven sorting (RayList/IndirectArgs/bindless) is NOT ported
//         (Iris has no indirect dispatch); uses HiZ march + fixed dispatch.
// Status: BLOCKED - depends on M3 (HiZ), which needs a free render target.
//#define HIZ_SSR

// ---------------------------------------------------------------------------
// M5 - Precomputed sky + fog height-density LUT
// Reference: 2.1.3 precomputedSky.glsl / raymarchSky/* /
//            passes/camera/genFogHeightDensitiesLut.comp
// Wiring: couples with clouds / volumetric light / DH fog - implement last.
// Status: BLOCKED by the image/colortex budget (needs a cubemap/LUT target).
//#define PRECOMPUTED_SKY

// ---------------------------------------------------------------------------
// M6 - Full ACES (RRT + ODT + tonescales)
// Reference: 2.1.3 continuumLib/aces/* (5 files); helpers already present in
//            InternalLib/Fragment/ACESSplines.glsl + ACESTransforms.glsl
// Wiring: activate RRT()/ODT_sRGB_D65() in C7 before the filmic/display path.
// Status: IMPLEMENTED (RRT + ODT_sRGB_D65 activated in ACES.glsl, C7 branch;
//         enable via the EXPERIMENTAL screen). Needs in-client verification.
//#define FULL_ACES
