# Phase 2-6 实施计划

**文档版本:** 1.0  
**实施日期:** 2026-11-05  
**参考项目:** Photon Shaders, Alpha Piscium, Noble Shaders, Complementary Unbound

---

## 技术参考总结

### Photon Shaders (sixthsurge)

**核心特性:**
- LabPBR 完整支持（TEXTURE_FORMAT_LAB / OLD）
- LPV 体素彩色光照（仅 Iris Ultra 档）
- GTAO 四分之一分辨率环境光遮蔽
- PCSS 可变半影软阴影
- 粗糙度感知 SSR
- 天气系统驱动云/雾/植被动态

**架构亮点:**
- `shaders/include/` 模块化目录结构
- `material.glsl` 统一材质解码
- `lpv/` 子目录组织体素光照
- 四档配置（Low/Medium/High/Ultra）

### Alpha Piscium (Luna5ama)

**核心特性:**
- ReSTIR 全局光照（时空重采样重要性采样）
- ReBLUR 降噪
- 虚幻引擎天空大气 + 极线采样
- Nubis 高级云渲染
- RTWSM 矩形纹理变形阴影

**开发路线图:**
1.9 镜面光照 → 2.0 体素追踪 → 2.2 体积阴影 → 2.3 局部雾 → 2.7 FSR 3.1 → 2.8 视差映射

### Noble Shaders (BelmuTM)

**核心特性:**
- 性能与画质平衡（GTX 950/R7 370 起）
- 干净清晰的画面风格
- 强大的自定义配置系统
- 支持 DH/Voxy LOD

### Complementary Unbound (EminGT)

**核心特性:**
- 双风格：Reimagined（原版）/ Unbound（写实）
- 彩色光照（Iris 专属）
- 屏幕空间路径追踪（SSPT）
- 多档位（Potato→Ultra）
- 优秀的水体渲染

**架构亮点:**
- 配置文件中明确区分功能开关
- 渐进式质量提升策略

---

## Phase 2 实施：色彩管理重构

### 目标
- 拆分快速滤镜为视觉风格 + 水体预设
- 新增 Nordic/Neutral 风格
- 多维度色彩验证

### 参考实现
- Photon 的材质 - 光照分离设计
- Complementary 的双风格配置

### 实施步骤

#### S1: 创建 VisualStyleSettings.glsl

```glsl
// UserLib/VisualStyleSettings.glsl
#ifndef VISUAL_STYLE_SETTINGS
#define VISUAL_STYLE_SETTINGS

// 视觉风格档位（独立于性能）
#define VISUAL_STYLE_NATURAL 0
#define VISUAL_STYLE_VIVID 1
#define VISUAL_STYLE_CINEMATIC 2
#define VISUAL_STYLE_MOODY 3
#define VISUAL_STYLE_NORDIC 4    // 新增：冷色清透
#define VISUAL_STYLE_NEUTRAL 5   // 新增：忠实原始

#ifndef VISUAL_STYLE
    #define VISUAL_STYLE VISUAL_STYLE_NATURAL
#endif

// 风格参数定义
#if VISUAL_STYLE == VISUAL_STYLE_NATURAL
    #define VS_SATURATION_MOD 1.0
    #define VS_CONTRAST_MOD   1.0
    #define VS_TINT_R         1.0
    #define VS_TINT_G         1.0
    #define VS_TINT_B         1.0
    #define VS_EXPOSURE_MOD   1.0
#elif VISUAL_STYLE == VISUAL_STYLE_VIVID
    #define VS_SATURATION_MOD 1.25
    #define VS_CONTRAST_MOD   1.15
    #define VS_TINT_R         1.05
    #define VS_TINT_G         1.0
    #define VS_TINT_B         0.95
    #define VS_EXPOSURE_MOD   1.05
// ... 其他风格
#endif

#endif
```

#### S2: 创建 WaterPresetSettings.glsl

```glsl
// UserLib/WaterPresetSettings.glsl
#ifndef WATER_PRESET_SETTINGS
#define WATER_PRESET_SETTINGS

// 水体预设（独立于视觉风格）
#define WATER_PRESET_NATURAL 0
#define WATER_PRESET_CLEAR   1
#define WATER_PRESET_DEEP    2
#define WATER_PRESET_TURQUOISE 3
#define WATER_PRESET_CUSTOM  4

#ifndef WATER_PRESET
    #define WATER_PRESET WATER_PRESET_NATURAL
#endif

// 预设参数
#if WATER_PRESET == WATER_PRESET_CLEAR
    #define WP_ABSORPTION_R 0.008
    #define WP_ABSORPTION_G 0.012
    #define WP_ABSORPTION_B 0.018
    #define WP_SCATTERING   0.3
    #define WP_WAVE_HEIGHT  0.5
#elif WATER_PRESET == WATER_PRESET_DEEP
    #define WP_ABSORPTION_R 0.03
    #define WP_ABSORPTION_G 0.025
    #define WP_ABSORPTION_B 0.02
    #define WP_SCATTERING   0.5
    #define WP_WAVE_HEIGHT  1.2
// ... 其他预设
#endif

#endif
```

#### S3: 修改 QuickFilterSettings.glsl

```glsl
// 向后兼容层：保留 QUICK_FILTER 宏但映射到新系统
#ifdef QUICK_FILTER_COMPAT_MODE
    #define VISUAL_STYLE QUICK_FILTER
    #define WATER_PRESET WATER_PRESET_NATURAL
#endif
```

#### S4: 更新 shaders.properties

```properties
# 新增菜单
screen.VISUAL=Visual Style
screen.WATER=Water Preset

variable.VS=VISUAL_STYLE
option.VS=Natural Vivid Cinematic Moody Nordic Neutral

variable.WP=WATER_PRESET
option.WP=Natural Clear Deep Turquoise Custom
```

---

## Phase 3 实施：PBR 材质系统完善

### 目标
- 完整 LabPBR 1.3 支持
- 建立材质测试集
- POM 优化

### 参考实现
- Photon 的 `material.glsl` 架构
- Complementary 的材质分类

### 实施步骤

#### S1: 重构 Materials.glsl

```glsl
// InternalLib/Utilities/Materials.glsl
#ifndef MATERIAL_SYSTEM
#define MATERIAL_SYSTEM

#include "/UserLib/LightingSettings.glsl"

// labPBR 纹理格式
#define TEXTURE_FORMAT_LAB 1
#define TEXTURE_FORMAT_OLD 2
#define TEXTURE_FORMAT_VANILLA 0

#ifndef TEXTURE_FORMAT
    #define TEXTURE_FORMAT TEXTURE_FORMAT_LAB
#endif

// 材质数据结构
struct Material {
    vec3 albedo;
    vec3 normal;
    float roughness;
    float metallic;
    float specular;
    vec3 emission;
    float subsurface;
    float porosity;
    float thickness;
};

// 读取高光贴图（labPBR 规范）
vec4 readSpecularMap(sampler2D specularMap, vec2 uv) {
    #if TEXTURE_FORMAT == TEXTURE_FORMAT_LAB
        // 完整 labPBR: R=roughness, G=metallic, B=specular, A=emission
        return texture(specularMap, uv);
    #elif TEXTURE_FORMAT == TEXTURE_FORMAT_OLD
        // 旧格式：R=roughness, G=metallic, B=emission
        vec4 s = texture(specularMap, uv);
        return vec4(s.rgb, 1.0);
    #else
        // Vanilla: 默认值
        return vec4(0.5, 0.0, 0.02, 0.0);
    #endif
}

// 读取法线贴图
vec3 readNormalMap(sampler2D normalMap, vec2 uv, vec3 tangent, vec3 bitangent, vec3 normal) {
    #ifdef USE_NORMAL_MAPPING
        vec3 n = texture(normalMap, uv).rgb * 2.0 - 1.0;
        n.z += 0.001; // 避免除零
        n = normalize(n);
        
        // 切线空间→世界空间
        mat3 tbn = mat3(tangent, bitangent, normal);
        return normalize(tbn * n);
    #else
        return normal;
    #endif
}

// 材质分类回退（当无 labPBR 纹理时）
Material getFallbackMaterial(int materialID) {
    Material mat;
    
    // 基于 materialID 的硬编码材质
    if (materialID == MAT_STONE) {
        mat.roughness = 0.7;
        mat.metallic = 0.0;
        mat.specular = 0.02;
        mat.subsurface = 0.0;
    } else if (materialID == MAT_METAL) {
        mat.roughness = 0.3;
        mat.metallic = 1.0;
        mat.specular = 0.8;
        mat.subsurface = 0.0;
    } else if (materialID == MAT_WOOD) {
        mat.roughness = 0.6;
        mat.metallic = 0.0;
        mat.specular = 0.03;
        mat.subsurface = 0.1;
    }
    // ... 更多材质
    
    return mat;
}

#endif
```

#### S2: 建立材质测试集文档

创建 `docs/MATERIAL-TEST-SUITE.md` 定义标准测试场景：
- 石材测试：花岗岩/闪长岩/安山岩
- 木材测试：橡木/云杉/白桦
- 金属测试：铁块/金块/铜块
- 玻璃测试：透明/染色
- 发光测试：荧石/海晶灯/红石火把

#### S3: POM 优化

参考 Alpha Piscium 的视差映射计划：
```glsl
// 陡峭视差映射（Steep Parallax Mapping）
vec2 steepParallax(vec2 uv, vec3 viewDir, float height) {
    const int steps = 8; // 可配置
    vec2 delta = viewDir.xy / viewDir.z;
    vec2 stepSize = delta / float(steps);
    
    vec2 currentUV = uv;
    float currentHeight = 1.0;
    
    for (int i = 0; i < steps; i++) {
        float h = texture(heightMap, currentUV).r;
        if (h > currentHeight) break;
        currentHeight -= 1.0 / float(steps);
        currentUV += stepSize;
    }
    
    return currentUV;
}
```

---

## Phase 4 实施：高级光照与反射

### 目标
- HiZ SSR
- GTAO 完善
- SSGI 探索

### 参考实现
- Photon 的粗糙度感知 SSR
- Alpha Piscium 的 ReSTIR GI

### 技术难点
- Image slot 已满（16/16），需要优化

### 解决方案
1. 合并使用率低的 target
2. 使用 SSBO 替代部分 image
3. 动态分配策略

#### S1: HiZ 金字塔生成

```glsl
// 若释放 1 个 image slot 后实现
layout(r32f) uniform image2D hizTex;  // 层级存储在 mip

void generateHiZ(sampler2D depthTex) {
    ivec2 size = imageSize(hizTex);
    
    // Base level: 全屏深度
    for (int y = 0; y < size.y; y += 2) {
        for (int x = 0; x < size.x; x += 2) {
            float d0 = texelFetch(depthTex, ivec2(x, y), 0).r;
            float d1 = texelFetch(depthTex, ivec2(x+1, y), 0).r;
            float d2 = texelFetch(depthTex, ivec2(x, y+1), 0).r;
            float d3 = texelFetch(depthTex, ivec2(x+1, y+1), 0).r;
            
            float maxD = max(max(d0, d1), max(d2, d3));
            imageStore(hizTex, ivec2(x/2, y/2), vec4(maxD));
        }
    }
    
    // Mip levels: 迭代降采样
    int levels = 10; // 1024→1
    for (int level = 1; level < levels; level++) {
        ivec2 mipSize = size >> level;
        for (int y = 0; y < mipSize.y; y++) {
            for (int x = 0; x < mipSize.x; x++) {
                // 从上一层取 4 个样本的最大值
                // ...
            }
        }
    }
}
```

#### S2: HiZ-SSR March

```glsl
vec3 hiZMarch(vec3 origin, vec3 dir, sampler2D hizTex, float depthTex) {
    const int maxSteps = 64;
    const int maxMipLevels = 10;
    
    vec3 currentPos = origin;
    float mipLevel = float(maxMipLevels);
    
    for (int i = 0; i < maxSteps; i++) {
        // 根据当前深度选择 mip 层级
        float depth = texture(hizTex, currentPos.xy, mipLevel).r;
        
        if (currentPos.z < depth) {
            // 命中：细化步长
            mipLevel = max(0.0, mipLevel - 1.0);
        }
        
        currentPos += dir;
    }
    
    return currentPos;
}
```

#### S3: GTAO 实现（参考 Photon）

```glsl
// 四分之一分辨率 AO
vec4 calculateGTAO(vec3 position, vec3 normal) {
    const int samples = 16;
    const float radius = 0.5;
    
    float ao = 0.0;
    
    for (int i = 0; i < samples; i++) {
        // Hemispherical sampling
        vec3 sampleDir = hemisphereSample(i, samples);
        sampleDir = rotateToNormal(sampleDir, normal);
        
        vec3 samplePos = position + sampleDir * radius;
        
        // Depth comparison
        float sampleDepth = getDepth(samplePos);
        if (sampleDepth < position.z) {
            ao += 1.0;
        }
    }
    
    ao /= float(samples);
    return vec4(vec3(1.0 - ao), 1.0);
}
```

---

## Phase 5 实施：模组兼容性扩展

### 目标
- Twilight Forest 维度专属
- Aether 高空环境
- Ad Astra 星球大气

### 参考实现
- Complementary 的维度配置系统
- Photon 的天气 - 生物群系联动

### S1: 维度识别框架

```glsl
// InternalLib/Common/Dimension.glsl
#ifndef DIMENSION_SYSTEM
#define DIMENSION_SYSTEM

#define DIM_OVERWORLD 0
#define DIM_NETHER 1
#define DIM_END 2
#define DIM_TWILIGHT_FOREST 10
#define DIM_AETHER 11
#define DIM_MARS 12
#define DIM_MOON 13

uniform int currentDimension;  // 通过 Iris dimension.properties 设置

// 维度专属参数
struct DimensionParams {
    vec3 skyColor;
    vec3 fogColor;
    float ambientBrightness;
    float cloudHeight;
    bool hasAtmosphere;
    vec3 atmosphereColor;
};

DimensionParams getDimensionParams() {
    DimensionParams params;
    
    #if currentDimension == DIM_OVERWORLD
        params.skyColor = vec3(0.5, 0.7, 1.0);
        params.fogColor = vec3(0.8, 0.9, 1.0);
        params.ambientBrightness = 1.0;
        params.cloudHeight = 200.0;
        params.hasAtmosphere = true;
        params.atmosphereColor = vec3(1.0, 0.95, 0.9);
        
    #elif currentDimension == DIM_TWILIGHT_FOREST
        // 暮色森林：密集树冠，昏暗天空
        params.skyColor = vec3(0.3, 0.4, 0.6);
        params.fogColor = vec3(0.4, 0.5, 0.6);
        params.ambientBrightness = 0.6;
        params.cloudHeight = 120.0;
        params.hasAtmosphere = true;
        params.atmosphereColor = vec3(0.8, 0.75, 0.7);
        
    #elif currentDimension == DIM_AETHER
        // 天堂：高空浮岛，明亮天空
        params.skyColor = vec3(0.8, 0.9, 1.0);
        params.fogColor = vec3(0.9, 0.95, 1.0);
        params.ambientBrightness = 1.3;
        params.cloudHeight = 300.0;
        params.hasAtmosphere = true;
        params.atmosphereColor = vec3(1.0, 0.98, 0.95);
        
    #elif currentDimension == DIM_MARS
        // 火星：稀薄大气，红色天空
        params.skyColor = vec3(0.9, 0.4, 0.3);
        params.fogColor = vec3(0.8, 0.5, 0.4);
        params.ambientBrightness = 0.7;
        params.cloudHeight = 50.0;
        params.hasAtmosphere = true;
        params.atmosphereColor = vec3(1.0, 0.6, 0.5);
        
    #elif currentDimension == DIM_MOON
        // 月球：无大气，黑色天空
        params.skyColor = vec3(0.0, 0.0, 0.0);
        params.fogColor = vec3(0.0, 0.0, 0.0);
        params.ambientBrightness = 0.3;
        params.cloudHeight = 0.0;
        params.hasAtmosphere = false;
        params.atmosphereColor = vec3(0.0);
    #endif
    
    return params;
}

#endif
```

#### S2: dimension.properties 配置

```properties
# shaders/dimension.properties
dim0=overworld
dim1=nether
dim2=end
dim.twilight_forest=twilight_forest
dim.the_aether=aether
dim.mars=ad_astra
dim.moon=ad_astra

# 维度专属着色器注入
dim0.sky=DefaultSky
dim.twilight_forest.sky=TwilightSky
dim.the_aether.sky=AetherSky
dim.mars.sky=MarsSky
dim.moon.sky=MoonSky
```

---

## Phase 6 实施：实验性光线追踪

### 目标
- HiZ 屏幕空间追踪
- SSGI 原型
- 体素光线追踪研究

### 参考实现
- Alpha Piscium 的 ReSTIR（时空重采样）
- Photon 的体素光照传播

### 技术边界
- 当前 Iris/OpenGL 不支持硬件 RT
- 仅能实现屏幕空间和体素方法

### S1: SSGI 基础实现

```glsl
// 屏幕空间全局光照（简化版）
vec3 calculateSSGI(vec3 position, vec3 normal, vec3 viewDir) {
    const int rays = 32;
    const float radius = 2.0;
    
    vec3 gi = vec3(0.0);
    
    for (int i = 0; i < rays; i++) {
        // Hemispherical sampling
        vec3 dir = cosineWeightedHemisphere(i, normal);
        
        // March along direction
        vec3 samplePos = position;
        float stepSize = radius / 16.0;
        
        for (int step = 0; step < 16; step++) {
            samplePos += dir * stepSize;
            
            // Project to screen space
            vec4 screenPos = projectionMatrix * viewMatrix * vec4(samplePos, 1.0);
            screenPos.xyz /= screenPos.w;
            screenPos.xy = screenPos.xy * 0.5 + 0.5;
            
            // Sample color and depth
            if (screenPos.xy >= 0.0 && screenPos.xy <= 1.0) {
                float sceneDepth = texture(depthTex, screenPos.xy).r;
                vec3 sceneColor = texture(colortex0, screenPos.xy).rgb;
                
                // Depth test
                if (abs(sceneDepth - screenPos.z) < 0.01) {
                    gi += sceneColor;
                    break;
                }
            }
        }
    }
    
    return gi / float(rays);
}
```

### S2: 体素光线追踪研究

参考 Photon 的 LPV 架构，探索更精确的体素追踪：
- 体素化场景几何
- 体素网格中追踪光线
- 时空复用减少采样

---

## 资源优化方案

### 当前瓶颈
- Image slots: 16/16 已满

### 解决方案

#### S1: 合并低频 target

```glsl
// 方案：将 cloudImgUpscaled 和 cloudImgFeedback 合并
// 使用单层 texture 的多个 channel
layout(rgba16f) uniform image2D cloudCombinedTex;
// R: upscaled color
// G: feedback color
// B: motion vector X
// A: motion vector Y
```

#### S2: SSBO 替代方案

```glsl
// 对于只读数据，使用 SSBO 而非 image
layout(std430, binding=6) buffer HiZBuffer {
    float hizData[];
};

// 优点：
// - 不占用 image slot
// - 支持原子操作
// - 更好的缓存局部性
```

#### S3: 动态分辨率

```glsl
// 根据性能档位调整 target 分辨率
#ifdef PROFILE_LOW
    const float renderScale = 0.5;
#elif PROFILE_MEDIUM
    const float renderScale = 0.75;
#else
    const float renderScale = 1.0;
#endif

// 在 shaders.properties 中
size.buffer.colortex12 = 0.5 0.5  // 动态调整
```

---

## 实施时间表

| Phase | 预计工时 | 关键依赖 | 风险 |
|-------|---------|---------|------|
| Phase 2 | 2 周 | 无 | 低 |
| Phase 3 | 3 周 | 材质测试集 | 中 |
| Phase 4 | 6 周 | Image slot 优化 | 高 |
| Phase 5 | 4 周 | 维度识别 | 中 |
| Phase 6 | 8 周 | 研究性质 | 高 |

---

## 下一步立即行动

1. **Phase 2 实施**（本周）
   - 创建 VisualStyleSettings.glsl
   - 创建 WaterPresetSettings.glsl
   - 修改 QuickFilter 向后兼容

2. **资源优化**（下周）
   - 审查 image slot 使用率
   - 实施合并方案
   - 释放至少 2 个 slot

3. **Phase 3 启动**（下周）
   - 重构 Materials.glsl
   - 定义材质测试集
   - 验证 LabPBR 解码

---

**文档结束**
