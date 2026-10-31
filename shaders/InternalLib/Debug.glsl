#if !defined _DEBUG_
    #define _DEBUG_

    //#define DEBUG

	#define debugOut colorimg15
    #define DEBUG_SCALE 1 // [1 2 3 4 5]

    #ifdef DEBUG
        #if defined comp
            #define DEBUG_IPOS ivec2(gl_GlobalInvocationID.xy * DEBUG_SCALE)
        #elif defined frag
            #define DEBUG_IPOS ivec2(gl_FragCoord.xy * DEBUG_SCALE)
        #elif defined vert
            #define DEBUG_IPOS ivec2(0) // TODO: Passthrough for vertex shaders.
        #elif defined geom
            #define DEBUG_IPOS ivec2(0) // TODO: Passthrough for geometry shaders.
        #else 
            #define DEBUG_IPOS ivec2(0)
        #endif

        layout (rgba8) uniform image2D colorimg15;

        void show(float x) { imageStore(debugOut, DEBUG_IPOS, vec4(x)); }
        void show( vec2 x) { imageStore(debugOut, DEBUG_IPOS, vec4(x, 0.0, 0.0)); }
        void show( vec3 x) { imageStore(debugOut, DEBUG_IPOS, vec4(x, 0.0)); }
        void show( vec4 x) { imageStore(debugOut, DEBUG_IPOS, vec4(x)); }

        void show(  int x) { imageStore(debugOut, DEBUG_IPOS, vec4(float(x))); }
        void show(ivec2 x) { imageStore(debugOut, DEBUG_IPOS, vec4(vec2(x), 0.0, 0.0)); }
        void show(ivec3 x) { imageStore(debugOut, DEBUG_IPOS, vec4(vec3(x), 0.0)); }
        void show(ivec4 x) { imageStore(debugOut, DEBUG_IPOS, vec4(x)); }

        void show( uint x) { imageStore(debugOut, DEBUG_IPOS, vec4(float(x))); }
        void show(uvec2 x) { imageStore(debugOut, DEBUG_IPOS, vec4(vec2(x), 0.0, 0.0)); }
        void show(uvec3 x) { imageStore(debugOut, DEBUG_IPOS, vec4(vec3(x), 0.0)); }
        void show(uvec4 x) { imageStore(debugOut, DEBUG_IPOS, vec4(x)); }

        void show( bool x) { imageStore(debugOut, DEBUG_IPOS, vec4(float(x))); }
        void show(bvec2 x) { imageStore(debugOut, DEBUG_IPOS, vec4(vec2(x), 0.0, 0.0)); }
        void show(bvec3 x) { imageStore(debugOut, DEBUG_IPOS, vec4(vec3(x), 0.0)); }
        void show(bvec4 x) { imageStore(debugOut, DEBUG_IPOS, vec4(x)); }

        void showAt(float x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(x)); }
        void showAt( vec2 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(x, 0.0, 0.0)); }
        void showAt( vec3 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(x, 0.0)); }
        void showAt( vec4 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(x)); }

        void showAt(  int x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(float(x))); }
        void showAt(ivec2 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(vec2(x), 0.0, 0.0)); }
        void showAt(ivec3 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(vec3(x), 0.0)); }
        void showAt(ivec4 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(x)); }

        void showAt( uint x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(float(x))); }
        void showAt(uvec2 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(vec2(x), 0.0, 0.0)); }
        void showAt(uvec3 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(vec3(x), 0.0)); }
        void showAt(uvec4 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(x)); }

        void showAt( bool x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(float(x))); }
        void showAt(bvec2 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(vec2(x), 0.0, 0.0)); }
        void showAt(bvec3 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(vec3(x), 0.0)); }
        void showAt(bvec4 x, ivec2 iCoord) { imageStore(debugOut, iCoord, vec4(x)); }

        #define showAt(x, y) showAt(x, ivec2(y));
        #define show(x) show(x);
    #endif
#endif