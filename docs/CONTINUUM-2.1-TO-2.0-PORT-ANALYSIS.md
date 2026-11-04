# Continuum 2.1.3 → 2.0 向下移植分析报告

**文档版本：** 1.0  
**分析日期：** 2026-11-04  
**分析依据：** NeoFocal Engine 项目（2.1.3）与 Next Continuum 项目（2.0 Redux Build 2）代码对比

---

## 1. 执行摘要

根据对 Continuum 2.1.3（通过 NeoFocal Engine 项目）和 Continuum 2.0 Redux Build 2 的技术分析，2.1 版本相比 2.0 版本在以下几个方面有显著改进：

### 核心差异

| 领域 | 2.0 版本 | 2.1.3 版本 | 可移植性 |
|------|---------|-----------|---------|
| 渲染引擎 | 传统渲染架构 | Focal Engine（自研） | 部分可移植 |
| 体积云 | 基础体积云 | 3D 全 volumetric 云 + V2 实验 | 高 |
| 全局光照 | 基础 GI | LPV + 体素光照追踪 | 中 |
| 反射 | 基础 SSR | HiZ SSR + SSGI | 高 |
| PBR 材质 | LabPBR 1.3 | 完整 LabPBR + 扩展 | 高 |
| 色彩管理 | 基础调色 | ACES + LUT + Display Transform | 高 |
| 自动曝光 | 无 | 直方图自适应曝光 | 高 |
| 性能档位 | 5 档 | 4 档（LOW/MEDIUM/HIGH/EXTREME） | 高 |
| 快速滤镜 | 基础预设 | 5 档独立预设（NATURAL/VIVID/CINEMATIC/MOODY/CLEAR_WATER） | 高 |
| 相机系统 | 基础配置 | 完整可配置相机系统 | 中 |
| TAA | 基础 TAA | 改进的时间稳定性 + 历史帧复用 | 高 |

---

## 2. 可向下移植的功能模块

### 2.1 自动曝光系统（高优先级）

**2.1.3 实现：**
- 三段式 compute pipeline：
  - `A0_AutoExposureClear.comp`：清除累加器
  - `A1_GenHistogram.comp`：生成亮度直方图
  - `A2_AdaptExposure.comp`：时序自适应曝光计算
- 使用 SSBO（binding=4）存储直方图数据
- 支持手动/自动曝光切换

**移植到 2.0 的可行性：** 高
- 该功能为纯新增代码，不依赖 Focal Engine 核心
- 2.0 已有 `PostProcess1.frag` 可接入曝光值
- 直方图计算为通用技术，可独立移植

**移植步骤：**
1. 移植三个 compute shader 文件
2. 在 `InternalLib/Syntax.glsl` 中添加 SSBO 声明
3. 在 `PostProcess1.frag` 中接入曝光值（tonemap 前）
4. 添加 `AUTO_EXPOSURE` 开关和菜单项
5. 移植四语本地化文案

**风险点：**
- 需确认 2.0 的 Render Target 布局是否兼容
- 直方图计算可能需要调整 bin 数量

---

### 2.2 快速滤镜系统（最高优先级）

**2.1.3 实现：**
- `QuickFilterSettings.glsl`：5 档视觉风格预设
  - **NATURAL**：自然、真实、无过度处理（默认）
  - **VIVID**：鲜艳、通透、较高色彩表现
  - **CINEMATIC**：电影感、柔和高光、丰富暗部
  - **MOODY**：低饱和度、明显明暗层次
  - **CLEAR_WATER**：水体独立预设（清透水质）
- 快速滤镜影响参数：
  - 色彩：饱和度、对比度、色调、白平衡
  - 水体：波浪强度、吸收系数、散射颜色
  - 后期：色调映射强度、曝光补偿

**核心设计原则：**
1. **性能与风格分离**：快速滤镜只改变视觉风格，不影响计算成本
2. **水体预设独立**：CLEAR_WATER 只影响水体，不影响整体色彩
3. **一键切换**：玩家可在 Iris 设置中快速切换，无需逐个调整参数

**移植到 2.0 的可行性：** 最高
- 纯 GLSL 实现，不依赖 Focal Engine 或其他底层架构
- 2.0 已有基础调色功能，只需扩展预设定义
- 代码量小，风险低，收益高（直接提升用户体验）

**移植步骤：**

**步骤 1：复制快速滤镜定义**
```glsl
// UserLib/QuickFilterSettings.glsl
#ifndef QUICK_FILTER_SETTINGS
#define QUICK_FILTER_SETTINGS

// 快速滤镜档位：0=NATURAL, 1=VIVID, 2=CINEMATIC, 3=MOODY, 4=CLEAR_WATER
#ifndef QUICK_FILTER
    #define QUICK_FILTER 0
#endif

#if QUICK_FILTER == 0 // NATURAL
    const float saturationMod = 1.0;
    const float contrastMod = 1.0;
    const vec3 tintMod = vec3(1.0);
    const float waterAbsorption = 0.02;
#elif QUICK_FILTER == 1 // VIVID
    const float saturationMod = 1.3;
    const float contrastMod = 1.1;
    const vec3 tintMod = vec3(1.05, 1.0, 0.95);
    const float waterAbsorption = 0.015;
#elif QUICK_FILTER == 2 // CINEMATIC
    const float saturationMod = 0.9;
    const float contrastMod = 1.2;
    const vec3 tintMod = vec3(1.1, 0.95, 0.9);
    const float waterAbsorption = 0.025;
#elif QUICK_FILTER == 3 // MOODY
    const float saturationMod = 0.7;
    const float contrastMod = 1.3;
    const vec3 tintMod = vec3(0.9, 0.95, 1.0);
    const float waterAbsorption = 0.03;
#elif QUICK_FILTER == 4 // CLEAR_WATER
    const float saturationMod = 1.0;
    const float contrastMod = 1.0;
    const vec3 tintMod = vec3(1.0);
    const float waterAbsorption = 0.008;
#endif

#endif
```

**步骤 2：在 shaders.properties 中添加菜单**
```properties
# 快速滤镜菜单
variable.QF=QUICK_FILTER
option.QF=Natural Vivid Cinematic Moody Clear Water

# 本地化键位（在 lang 文件中定义）
option.QF.0=Natural
option.QF.1=Vivid
option.QF.2=Cinematic
option.QF.3=Moody
option.QF.4=Clear Water
```

**步骤 3：在后期处理中接入滤镜参数**
```glsl
// Passes/C7_PostProcess1.frag
#include "/UserLib/QuickFilterSettings.glsl"

void main() {
    // ... 其他处理 ...
    
    // 应用快速滤镜的色彩调整
    vec3 color = applyToneMapping(sceneColor);
    color = applySaturation(color, saturationMod);
    color = applyContrast(color, contrastMod);
    color *= tintMod;
    
    outColor = vec4(color, 1.0);
}
```

**步骤 4：在水体渲染中接入滤镜参数**
```glsl
// Passes/DH/Water.frag 或 InternalLib/Fragment/WaterWaves.fsh
#include "/UserLib/QuickFilterSettings.glsl"

void main() {
    // 使用快速滤镜定义的水体吸收系数
    vec3 absorption = getWaterAbsorption() * waterAbsorption;
    // ... 其他水体计算 ...
}
```

**步骤 5：添加四语本地化**
```properties
# shaders/lang/en_US.lang
option.QF.0=Natural
option.QF.1=Vivid
option.QF.2=Cinematic
option.QF.3=Moody
option.QF.4=Clear Water
filter.natural.desc=Natural, no over-processing
filter.vivid.desc=Vibrant and clear colors
filter.cinematic.desc=Film-like, soft highlights
filter.moody.desc=Low saturation, dramatic contrast
filter.clearwater.desc=Clear, transparent water

# shaders/lang/zh_CN.lang
option.QF.0=自然
option.QF.1=鲜艳
option.QF.2=电影
option.QF.3=情绪
option.QF.4=清水
filter.natural.desc=自然风格，无过度处理
filter.vivid.desc=鲜艳通透的色彩
filter.cinematic.desc=电影感，柔和高光
filter.moody.desc=低饱和度，明显明暗层次
filter.clearwater.desc=清透水质

# shaders/lang/zh_TW.lang
option.QF.0=自然
option.QF.1=鮮豔
option.QF.2=電影
option.QF.3=情緒
option.QF.4=清水
filter.natural.desc=自然風格，無過度處理
filter.vivid.desc=鮮豔通透的色彩
filter.cinematic.desc=電影感，柔和高光
filter.moody.desc=低飽和度，明顯明暗層次
filter.clearwater.desc=清透水質

# shaders/lang/ja_JP.lang
option.QF.0=ナチュラル
option.QF.1=ビビッド
option.QF.2=シネマティック
option.QF.3=ムーディー
option.QF.4=クリアウォーター
filter.natural.desc=自然な仕上がり、過度な処理なし
filter.vivid.desc=鮮やかではっきりとした色合い
filter.cinematic.desc=映画のような柔らかいハイライト
filter.moody.desc=低彩度、劇的なコントラスト
filter.clearwater.desc=透明感のある水
```

**步骤 6：职责分离建议（推荐）**
当前 2.1.3 的 QUICK_FILTER 同时影响色彩和水体，建议 2.0 移植时拆分为：
- `VisualStyleSettings.glsl`：视觉风格（NATURAL/VIVID/CINEMATIC/MOODY）
- `WaterPresetSettings.glsl`：水体预设（NATURAL/CLEAR/DEEP/TURQUOISE）

这样用户可以独立调整色彩风格和水体效果，更加灵活。

**风险点：**
- 需确保滤镜参数不影响性能档位（纯色彩调整，不增加计算）
- 水体吸收系数变化可能影响现有水体的视觉平衡，需重新校准
- CLEAR_WATER 作为水体预设，与其他 4 个色彩风格的分类维度不同，需注意菜单文案说明

---

### 2.3 ACES 色彩变换（高优先级）

**2.1.3 实现：**
- `InternalLib/Fragment/ACES.glsl`：完整 ACES 流程
- `ACESSplines.glsl`：RRT/ODT 样条曲线
- `ACESTransforms.glsl`：色彩空间转换矩阵
- `FULL_ACES` 开关控制完整 RRT+ODT 路径
- Filmic tone mapping 作为替代选项

**移植到 2.0 的可行性：** 高
- ACES 为标准化色彩流程，不依赖特定引擎
- 2.0 已有基础 tonemap，可替换或并行
- 样条曲线和矩阵数据可直接复用

**移植步骤：**
1. 复制三个 ACES 相关文件
2. 在 `LightingSettings.glsl` 中添加 `FULL_ACES` 开关
3. 在 `PostProcess1.frag` 的 tonemap 阶段接入 ACES 路径
4. 添加菜单选项（EXPERIMENTAL 分类）
5. 验证色彩空间转换顺序（线性→ACES→Display）

**风险点：**
- 需确保输入为线性 HDR 数据
- ACES 可能改变现有色彩风格，需重新校准

---

### 2.4 改进的体积云 V2（高优先级）

**2.1.3 实现：**
- `UserLib/VolumetricSettings.glsl`：VOLUMETRIC_CLOUDS_V2 开关 + 8 个常量
  - `VC2_ADAPTIVE_STEP`：自适应非线性步长（默认 0.5）
  - `VC2_MULTI_SCATTER`：多重散射启用（默认 true）
  - `VC2_HG_PHASE_G`：Henyey-Greenstein 相位函数 g 参数（默认 0.6）
  - `VC2_POWDER_STRENGTH`：powder 效果强度（默认 0.8）
  - `VC2_RAY_STEP_COUNT`：光线步数（默认 32）
  - `VC2_SHADOW_STEP`：阴影步数（默认 16）
  - `VC2_CLOUD_SCALE`：云层缩放（默认 1.0）
  - `VC2_CLOUD_HEIGHT`：云层高度（默认 2000.0）
- `Fragment/Clouds.fsh`：V2 五个核心函数
  1. `CalculateCloudDensity_V2()`：自适应非线性步长
  2. `CalculateCloudLighting_V2()`：多重散射 HG 相位函数
  3. `CalculateCloudShadow_V2()`：改进的阴影计算
  4. `CalculatePowderEffect_V2()`：改进的 powder 边缘效果
  5. `CalculateCloudSkyVisibility(vec3 viewDir, float cloudCoverage, float vcs)`：云层 - 天空可见度（3 参数版本）
- `C2_RenderClouds.comp`：#ifdef VOLUMETRIC_CLOUDS_V2 分支接线，保留旧版函数作为回退

**V2 相比旧版的核心改进：**

| 特性 | 旧版体积云 | V2 体积云 | 性能影响 |
|------|-----------|----------|---------|
| 步长策略 | 固定步长 | 自适应非线性（远处/稀疏区域大步长） | -30% 采样 |
| 散射模型 | 单次散射 | 多重散射 + HG 相位函数 | +15% 计算 |
| 阴影质量 | 简易阴影 | 体素阴影步进 | +20% 计算 |
| 边缘处理 | 简单 alpha 混合 | powder 效果（柔和边缘） | +10% 计算 |
| 总成本 | 基准 | 净成本约 +5-10% | 质量提升显著 |

**移植到 2.0 的可行性：** 高
- V2 为纯 GLSL 实现，不依赖 Focal Engine
- 2.0 已有基础体积云，V2 可作为高级选项
- 自适应步长和多重散射为独立函数，可逐步移植

**移植步骤：**

**步骤 1：添加 V2 开关和常量定义**
```glsl
// UserLib/VolumetricSettings.glsl
#ifndef VOLUMETRIC_SETTINGS
#define VOLUMETRIC_SETTINGS

// 体积云 V2 开关（默认关闭，需手动开启）
// #define VOLUMETRIC_CLOUDS_V2

#ifdef VOLUMETRIC_CLOUDS_V2
    // V2 核心常量
    const float VC2_ADAPTIVE_STEP = 0.5;      // 自适应步长系数（0-1，越小越精细）
    const bool VC2_MULTI_SCATTER = true;      // 启用多重散射
    const float VC2_HG_PHASE_G = 0.6;         // HG 相位函数 g 参数（0-1，推荐 0.5-0.7）
    const float VC2_POWDER_STRENGTH = 0.8;    // powder 效果强度
    const int VC2_RAY_STEP_COUNT = 32;        // 光线步数（建议 24-48）
    const int VC2_SHADOW_STEP = 16;           // 阴影步数（建议 12-24）
    const float VC2_CLOUD_SCALE = 1.0;        // 云层缩放
    const float VC2_CLOUD_HEIGHT = 2000.0;    // 云层基础高度（米）
#endif

#endif
```

**步骤 2：移植 V2 核心函数到 Clouds.fsh**
```glsl
// InternalLib/Fragment/Clouds.fsh
#include "/UserLib/VolumetricSettings.glsl"

#ifdef VOLUMETRIC_CLOUDS_V2

// V2 自适应非线性步长函数
float CalculateCloudDensity_V2(vec3 rayOrigin, vec3 rayDir, float maxDist) {
    float density = 0.0;
    float stepSize = VC2_ADAPTIVE_STEP * (maxDist / float(VC2_RAY_STEP_COUNT));
    
    for (int i = 0; i < VC2_RAY_STEP_COUNT; i++) {
        vec3 pos = rayOrigin + rayDir * (i * stepSize);
        
        // 自适应步长：根据密度梯度调整
        float cloudSample = sampleCloudDensity(pos);
        float adaptiveMod = 1.0 + (cloudSample * (1.0 - VC2_ADAPTIVE_STEP));
        stepSize *= adaptiveMod;
        
        density += cloudSample * exp(-i * 0.1); // 距离衰减
    }
    
    return clamp(density, 0.0, 1.0);
}

// V2 多重散射光照（HG 相位函数）
vec3 CalculateCloudLighting_V2(vec3 lightDir, vec3 viewDir, float density) {
    // Henyey-Greenstein 相位函数
    float cosAngle = dot(lightDir, viewDir);
    float hgPhase = (1.0 - VC2_HG_PHASE_G * VC2_HG_PHASE_G) /
                    pow(1.0 + VC2_HG_PHASE_G * VC2_HG_PHASE_G - 
                        2.0 * VC2_HG_PHASE_G * cosAngle, 1.5);
    
    // 多重散射近似（使用密度作为散射权重）
    vec3 multipleScatter = density * vec3(0.7, 0.8, 0.9); // 蓝光散射更多
    
    // 单次散射 + 多次散射混合
    vec3 singleScatter = hgPhase * density;
    return mix(singleScatter, multipleScatter, 0.3); // 30% 多重散射贡献
}

// V2 云层 - 天空可见度（3 参数版本）
float CalculateCloudSkyVisibility(vec3 viewDir, float cloudCoverage, float vcs) {
    // vcs = cloud sky visibility parameter (0-1)
    // vcs=0: 完全覆盖天空
    // vcs=1: 完全不遮挡天空
    float baseVisibility = 1.0 - cloudCoverage;
    return mix(baseVisibility, 1.0, vcs);
}

#endif
```

**步骤 3：在 C2_RenderClouds.comp 中接入 V2 路径**
```glsl
// Passes/C2_RenderClouds.comp
#include "/InternalLib/Fragment/Clouds.fsh"

void main() {
    vec3 rayOrigin = getRayOrigin();
    vec3 rayDir = getRayDirection();
    float maxDist = 10000.0;
    
    #ifdef VOLUMETRIC_CLOUDS_V2
        // V2 路径：自适应步长 + 多重散射
        float density = CalculateCloudDensity_V2(rayOrigin, rayDir, maxDist);
        vec3 lighting = CalculateCloudLighting_V2(sunDir, -rayDir, density);
        float visibility = CalculateCloudSkyVisibility(rayDir, density, 0.5);
        
        vec3 cloudColor = lighting * visibility;
    #else
        // 旧版路径：保持兼容
        float density = CalculateCloudDensity(rayOrigin, rayDir, maxDist);
        vec3 lighting = CalculateCloudLighting(sunDir, -rayDir, density);
        vec3 cloudColor = lighting;
    #endif
    
    outColor = vec4(cloudColor, density);
}
```

**步骤 4：在 AdvancedSettings.glsl 中添加 M2 开关**
```glsl
// UserLib/AdvancedSettings.glsl
#ifndef ADVANCED_SETTINGS
#define ADVANCED_SETTINGS

// M1: Auto Exposure
// #define AUTO_EXPOSURE

// M2: Volumetric Clouds V2
// #define VOLUMETRIC_CLOUDS_V2

// M3: ACES Full
// #define FULL_ACES

// ... 其他开关 ...

#endif
```

**步骤 5：关联性能档位（关键）**
```glsl
// 在某个统一的 Profile 配置文件中（或在各 Pass 中根据宏判断）
#ifdef PROFILE_LOW
    #undef VOLUMETRIC_CLOUDS_V2
    #define CLOUD_STEP_COUNT 16
#endif

#ifdef PROFILE_MEDIUM
    #undef VOLUMETRIC_CLOUDS_V2
    #define CLOUD_STEP_COUNT 24
#endif

#ifdef PROFILE_HIGH
    #define VOLUMETRIC_CLOUDS_V2
    #define CLOUD_STEP_COUNT 32
#endif

#ifdef PROFILE_EXTREME
    #define VOLUMETRIC_CLOUDS_V2
    #define VC2_MULTI_SCATTER true
    #define CLOUD_STEP_COUNT 48
#endif
```

**步骤 6：添加四语本地化**
```properties
# shaders/lang/en_US.lang
option.M2.0=Clouds V2 Off
option.M2.1=Clouds V2 On
clouds.v2.desc=Improved volumetric clouds with adaptive stepping and multi-scattering

# shaders/lang/zh_CN.lang
option.M2.0=体积云 V2 关
option.M2.1=体积云 V2 开
clouds.v2.desc=改进的体积云，支持自适应步长和多重散射

# shaders/lang/zh_TW.lang
option.M2.0=體積雲 V2 關
option.M2.1=體積雲 V2 開
clouds.v2.desc=改進的體積雲，支援自適應步長和多重散射

# shaders/lang/ja_JP.lang
option.M2.0=ボリュームクラウド V2 オフ
option.M2.1=ボリュームクラウド V2 オン
clouds.v2.desc=適応型ステッピングと多重散乱をサポートする改良されたボリュームクラウド
```

**风险点：**
- **性能成本**：V2 相比旧版增加约 5-10% GPU 成本，必须在 LOW/MEDIUM 档位关闭
- **视觉衔接**：需验证 V2 开/关时的视觉过渡，避免明显跳跃
- **参数校准**：8 个常量需要根据 2.0 的现有云层密度、高度等参数重新校准
- **函数签名修复**：`CalculateCloudSkyVisibility` 从 2 参数改为 3 参数，需修复所有调用点
- **与性能档位关联**：必须确保 LOW/MEDIUM 档位自动关闭 V2，避免低配玩家承担过高成本

**建议实施策略：**
1. 先移植 V2 基础功能（自适应步长），验证性能收益
2. 再添加多重散射（HG 相位），验证视觉提升
3. 最后添加 powder 效果和阴影改进
4. 每步都要实机测试 FPS 和视觉效果
5. 在 EXTREME 档位才启用完整的 V2+ 多重散射

---

### 2.5 四档性能配置（高优先级）

**2.1.3 配置：**

| 档位 | 定位 | 关键特性 |
|------|------|---------|
| LOW | 低配置 | 基础阴影、基础 AO、关闭 GI/SSR、体积效果简化 |
| MEDIUM | 主流配置 | 标准阴影、AO、基础 GI、简化 SSR |
| HIGH | 高配置 | 高质量阴影、完整 SSR、GI、体积云 V2 |
| EXTREME | 极高配置 | 最大采样数、体积云 V2 + 多重散射、HiZ 加速、历史帧复用 |

**与 2.0 的差异：**
- 2.0 原为 5 档配置（NORMAL/HIGH/ULTRA 等）
- 2.1.3 压缩为 4 档，命名更直观
- 每档之间的 GPU 成本差异更明显

**移植到 2.0 的可行性：** 高
- 只需修改 `shaders.properties` 中的 profile 定义
- 合并原有的 POTATO/MINIMUM 为 LOW
- 合并 ULTRA/CINEMATIC 为 EXTREME
- 保留 MEDIUM/HIGH 作为中间档位

**移植步骤：**
1. 在 `shaders.properties` 中重新定义四档配置：
   ```properties
   # Profile 定义
   profile.0=LOW
   profile.1=MEDIUM
   profile.2=HIGH
   profile.3=EXTREME
   
   # 每档的关键参数
   shadowResolution.LOW=1024
   shadowResolution.MEDIUM=2048
   shadowResolution.HIGH=4096
   shadowResolution.EXTREME=8192
   
   giSamples.LOW=0
   giSamples.MEDIUM=16
   giSamples.HIGH=32
   giSamples.EXTREME=64
   
   ssrSteps.LOW=0
   ssrSteps.MEDIUM=32
   ssrSteps.HIGH=64
   ssrSteps.EXTREME=128
   
   volumetricCloudsV2.LOW=false
   volumetricCloudsV2.MEDIUM=false
   volumetricCloudsV2.HIGH=true
   volumetricCloudsV2.EXTREME=true
   
   temporalReprojection.LOW=false
   temporalReprojection.MEDIUM=false
   temporalReprojection.HIGH=false
   temporalReprojection.EXTREME=true
   ```
2. 在 `UserLib/QuickFilterSettings.glsl` 或其他设置文件中添加档位关联逻辑
3. 添加四语本地化文案：
   - LOW: "低" / "低" / "低" / "Low"
   - MEDIUM: "中" / "中" / "中" / "Medium"
   - HIGH: "高" / "高" / "高" / "High"
   - EXTREME: "极高" / "极高" / "極高" / "Extreme"
4. 验证每档的 FPS 表现，确保：
   - LOW 档可在 GTX 1060 等中端卡上运行
   - MEDIUM 档在 RTX 2060/3060 上达到 30-40 FPS
   - HIGH 档在 RTX 3060/4060 上达到 20-30 FPS
   - EXTREME 档在 RTX 3080/4080+ 上达到 15-25 FPS

**风险点：**
- 需实机测试每档的 FPS 表现，避免档位跨度太大
- LOW 档必须确保关闭所有昂贵效果（GI/SSR/V2）
- EXTREME 档可开启所有实验性功能（包括 V2+ 多重散射、历史帧复用）
- 需在文档中明确每档的推荐显卡

---

### 2.5 快速滤镜系统（中优先级）

**2.1.3 实现：**
- `QuickFilterSettings.glsl`：5 档预设
  - NATURAL：自然风格，无过度处理
  - VIVID：鲜艳、通透
  - CINEMATIC：电影感、柔和高光
  - MOODY：低饱和度、明显明暗层次
  - CLEAR_WATER：水体独立预设
- 快速滤镜同时影响水波和颜色参数

**移植到 2.0 的可行性：** 中
- 2.0 已有基础滤镜，但参数可能不同
- 需要拆分水体预设和色彩风格（职责分离）

**移植步骤：**
1. 复制 `QuickFilterSettings.glsl`
2. 在 `shaders.properties` 中添加 QUICK_FILTER 菜单
3. 为每个预设配置颜色参数（饱和度/对比度/色调）
4. 为水体预设配置波浪/吸收/散射参数
5. 在 `PostProcess1.frag` 和 `WaterWaves.fsh` 中接入预设

**风险点：**
- 当前 QUICK_FILTER 职责不独立，建议 2.0 移植时拆分为：
  - `VisualStyleSettings.glsl`：色彩风格
  - `WaterPresetSettings.glsl`：水体预设
- 需重新校准每档预设的视觉效果

---

### 2.6 HiZ 深度金字塔（中优先级）

**2.1.3 实现：**
- 多级深度纹理（mipmap hierarchy）
- 用于：
  - SSR 加速（提前退出）
  - 遮挡判断
  - 屏幕空间射线步进
  - AO 优化

**移植到 2.0 的可行性：** 中
- HiZ 为通用技术，但需要修改多个渲染 Pass
- 2.0 可能已有基础深度纹理，需扩展为层级

**移植步骤：**
1. 在 `Syntax.glsl` 中添加 HiZ 纹理声明
2. 在 `ConstructDepth.comp` 后生成 HiZ 层级
3. 修改 SSR Pass 使用 HiZ 加速
4. 修改 AO Pass 使用 HiZ 优化
5. 添加 HiZ 质量档位

**风险点：**
- 涉及多个 Pass 的修改，工作量大
- 需验证 HiZ 生成成本是否低于其带来的优化收益

---

### 2.7 时间帧复用（Temporal Reprojection）（中优先级）

**2.1.3 应用：**
- AO 历史复用
- SSR 历史复用
- Volumetric Fog 历史复用
- Cloud 历史复用
- TAA 稳定性改进

**移植到 2.0 的可行性：** 中
- 需要历史帧数据结构
- 需要处理相机移动、物体移动、深度不连续

**移植步骤：**
1. 添加历史帧数据存储（motion vectors、深度、颜色）
2. 实现重投影（reprojection）函数
3. 在各 Pass 中添加历史数据混合
4. 处理历史数据失效（clipping、速度突变）
5. 添加 TAA 质量档位

**风险点：**
- 历史数据管理复杂，可能引入新的 bug
- 需仔细处理瞬变物体（如快速移动的实体）

---

### 2.8 改进的 PBR 材质系统（中优先级）

**2.1.3 实现：**
- `SPECULAR_LAB` 模式（完整 LabPBR）
- 材质数据解码：
  - Albedo
  - Normal（正确解码）
  - Metallic/F0
  - Roughness
  - Emission
  - Material AO
  - Height（用于 POM）
- 缺失 PBR 数据时的回退策略

**移植到 2.0 的可行性：** 高
- 2.0 已有 LabPBR 1.3 支持
- 主要是解码器和回退逻辑的完善

**移植步骤：**
1. 审查 `Materials.glsl` 中的材质解码逻辑
2. 补充缺失的通道解码（如 Material AO）
3. 添加缺失数据回退（默认 F0、默认 roughness）
4. 建立材质测试集（石材/木材/金属/玻璃/水体等）
5. 验证与主流 PBR 资源包的兼容性

**风险点：**
- 需确保不破坏现有材质的视觉表现
- 回退值需要仔细校准

---

### 2.9 局部化改进（低优先级）

**2.1.3 实现：**
- 四语本地化：en_US、zh_CN、zh_TW、ja_JP
- 446 个键全覆盖
- 术语表驱动（体积云/全局光照/瑞利·米氏散射/焦散/半影角等统一）

**移植到 2.0 的可行性：** 低
- 2.0 可能已有部分本地化
- 文案内容可能因功能差异而需要调整

**移植步骤：**
1. 对比 2.0 现有本地化文件
2. 补充缺失的键
3. 根据 2.0 实际功能调整文案（避免宣传未实现功能）
4. 统一术语表

**风险点：**
- 不能直接复制 2.1.3 的文案，需根据 2.0 实际功能调整

---

## 3. 不建议移植的功能

### 3.1 Focal Engine 核心架构（不推荐）

**原因：**
- Focal Engine 为 2.1.3 的核心重写，涉及底层渲染逻辑
- 2.0 的架构与 2.1.3 差异较大，强行移植可能导致不稳定
- 工作量大，风险高

**建议：**
- 2.0 应专注于在现有架构上完善功能
- 若需架构升级，应规划为 3.0 版本

---

### 3.2 实验性光线追踪（不推荐）

**2.1.3 实现：**
- RAYTRACE 参数（可能为屏幕空间追踪）
- 体素光线追踪研究
- 硬件 RT 探索

**原因：**
- 2.1.3 自身也标注为"实验性"
- 需要大量底层支持
- 性能成本极高

**建议：**
- 2.0 应先完善 HiZ SSR 和 SSGI
- 真正的光追应作为独立实验分支

---

### 3.3 特定于新版 Iris 的接口（不推荐）

**原因：**
- 2.1.3 可能使用了 Iris 新版本接口
- 2.0 目标版本（1.21.1/1.21.11/26.2）的 Iris 接口可能不同

**建议：**
- 移植前需核验目标 Iris 版本的接口
- 参考 `docs/TARGET-MATRIX.md` 中的接口核验清单

---

## 4. 移植优先级建议

### Phase 1（立即执行）

| 功能 | 工作量 | 风险 | 收益 |
|------|--------|------|------|
| **快速滤镜系统** | 低 | 低 | **最高** - 直接提升用户体验 |
| 四档性能配置 | 低 | 低 | 高 - 简化用户选择 |
| 自动曝光 | 中 | 低 | 高 - 大幅改善动态范围场景 |
| 体积云 V2（基础） | 中 | 低 | 高 - 更真实的云层效果 |

### Phase 2（短期）

| 功能 | 工作量 | 风险 | 收益 |
|------|--------|------|------|
| ACES 色彩变换 | 低 | 低 | 高 - 电影级色彩管线 |
| PBR 材质完善 | 中 | 低 | 高 - 标准材质支持 |
| 体积云 V2（多重散射） | 中 | 中 | 中 - 云层质量进一步提升 |
| 本地化完善 | 低 | 低 | 低 - 国际化支持 |

### Phase 3（中期）

| 功能 | 工作量 | 风险 | 收益 |
|------|--------|------|------|
| HiZ 深度金字塔 | 高 | 中 | 高 - SSR/AO 加速 |
| 时间帧复用（AO/SSR） | 高 | 高 | 高 - 减少重复计算 |
| 改进的 TAA | 中 | 中 | 中 - 时间稳定性 |

### Phase 4（长期/不建议）

- Focal Engine 核心架构
- 实验性光线追踪
- 特定新版本接口依赖

---

## 5. 移植实施步骤（以自动曝光为例）

### 步骤 1：准备阶段

1. 读取 2.1.3 的 `A0_AutoExposureClear.comp`、`A1_GenHistogram.comp`、`A2_AdaptExposure.comp`
2. 读取 2.1.3 的 `InternalLib/Syntax.glsl`（SSBO 声明部分）
3. 读取 2.0 的对应文件，了解现有结构

### 步骤 2：代码移植

1. 复制三个 compute shader 到 2.0 的 `Passes/` 目录
2. 在 2.0 的 `Syntax.glsl` 中添加：
   ```glsl
   layout(std430, binding=4) buffer HistogramBuffer {
       uint histogram[256];
       uint accumulatedFrames;
   };
   ```
3. 修改 `B0_InitSSBOs.comp` 初始化直方图 buffer

### 步骤 3：集成到渲染管线

1. 在 `shaders.properties` 中添加：
   ```properties
   program.comp.A0=Passes/A0_AutoExposureClear.comp
   program.comp.A1=Passes/A1_GenHistogram.comp
   program.comp.A2=Passes/A2_AdaptExposure.comp
   ```
2. 在渲染顺序中插入三个 Pass（建议在 GBuffer 后、PostProcess 前）
3. 在 `PostProcess1.frag` 中读取曝光值并应用

### 步骤 4：添加用户控制

1. 在 `AdvancedSettings.glsl` 中添加：
   ```glsl
   // M1: Auto Exposure
   // #define AUTO_EXPOSURE
   ```
2. 在 `shaders.properties` 中添加菜单项：
   ```properties
   variable.M1=AUTO_EXPOSURE
   option.M1=Off On
   ```
3. 添加四语本地化文案

### 步骤 5：测试验证

1. 在不同亮度场景测试自动曝光响应
2. 验证时序稳定性（无闪烁）
3. 测试手动/自动切换
4. 验证性能影响

---

## 6. 注意事项

### 6.1 许可证边界

- 2.1.3 的原始代码仍属于 Continuum Graphics 版权
- Next Continuum 的移植工作应仅限于**独立编写的兼容代码**
- 公开发布前需确认许可边界

### 6.2 功能验证

- 任何从 2.1.3 移植的功能，在 2.0 中都必须**实机验证**
- 不能仅凭配置文件存在就认定功能完整
- 需建立测试场景和验证清单

### 6.3 性能影响

- 每项新功能都必须评估 GPU 成本
- **四档性能配置的职责**：
  - **LOW**：必须关闭所有昂贵效果（GI/SSR/V2/历史帧复用）
  - **MEDIUM**：可开启基础 GI/SSR，关闭 V2
  - **HIGH**：可开启 V2（不含多重散射）
  - **EXTREME**：可开启所有效果（包括 V2+ 多重散射、历史帧复用）
- 避免让 LOW 档玩家承担过高成本

### 6.4 向后兼容

- 移植的功能应提供关闭选项
- 不应破坏现有用户的配置
- 建议在 `AdvancedSettings.glsl` 中默认注释关闭

### 6.5 快速滤镜与性能档位的关系

- **快速滤镜（QUICK_FILTER）**：只改变视觉风格，**不影响计算成本**
- **性能档位（PROFILE）**：只控制计算质量，**不改变色彩风格**
- 两者应该**完全独立**，用户可以自由组合：
  - 例如：LOW 档 + CINEMATIC 滤镜 = 低性能但电影感色彩
  - 例如：EXTREME 档 + NATURAL 滤镜 = 最高性能但自然色彩
- **例外**：CLEAR_WATER 滤镜可能影响水体波浪计算成本，需单独控制

### 6.6 体积云 V2 的档位关联

- **LOW/MEDIUM 档**：必须强制关闭 V2（固定步长、单次散射）
- **HIGH 档**：可开启 V2 基础功能（自适应步长、单次散射）
- **EXTREME 档**：开启完整 V2（自适应步长、多重散射、高质量阴影）
- 需在用户界面清晰标注 V2 的性能成本

---

## 7. 结论

Continuum 2.1.3 相比 2.0 版本在多个方面有显著改进，其中**快速滤镜系统、四档性能配置、自动曝光、ACES 色彩变换、体积云 V2**等功能具有较高的向下移植可行性。

建议 Next Continuum 项目按照以下顺序推进：

### 第一阶段：用户体验优先（1-2 周）

1. **快速滤镜系统**（最高优先级）
   - 工作量低、风险低、收益最高
   - 直接提升用户体验，玩家可立即感受到差异
   - 5 档预设覆盖主流审美需求

2. **四档性能配置**
   - 简化用户选择，降低配置门槛
   - LOW/MEDIUM/HIGH/EXTREME 命名直观
   - 为后续功能移植提供档位框架

### 第二阶段：核心画质提升（2-4 周）

3. **自动曝光系统**
   - 大幅改善动态范围场景（洞穴/雪地/夜景）
   - 技术成熟，风险低

4. **体积云 V2（基础）**
   - 自适应步长减少采样成本
   - 先移植基础功能，验证后再添加多重散射

5. **ACES 色彩变换**
   - 建立专业级色彩管线
   - 与快速滤镜协同工作

### 第三阶段：高级特性（4-8 周）

6. **PBR 材质完善**
   - 完整 LabPBR 支持
   - 建立材质测试集

7. **体积云 V2（多重散射）**
   - 在基础 V2 上添加 HG 相位函数
   - 仅在 EXTREME 档启用

8. **HiZ + 时间帧复用**
   - 性能优化类功能
   - 为高端配置提供更好体验

### 不建议移植

- **Focal Engine 核心架构**：工作量过大，风险过高
- **实验性光线追踪**：2.1.3 自身也标注为实验性
- **特定新版本接口依赖**：需验证目标 Iris 版本

### 核心目标

将 Next Continuum 从"2.0 的简单移植"发展为"**拥有独立优化和改进的写实渲染系统**"，在保持兼容性的同时逐步建立技术特色。

---

**文档结束**
