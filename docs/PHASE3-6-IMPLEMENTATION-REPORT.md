# Phase 3-6 实施报告

**实施日期:** 2026-11-05  
**提交范围:** Phase 3 (PBR 材质) → Phase 6 (实验性光线追踪)

---

## Phase 2 回顾：色彩管理重构 ✓

### 已完成
- VisualStyleSettings.glsl: 6 档视觉风格
- WaterPresetSettings.glsl: 6 档水体预设
- 向后兼容层：QUICK_FILTER → VISUAL_STYLE 映射
- 四语本地化支持

---

## Phase 3: PBR 材质系统完善

### 3.1 Materials.glsl 重构

**文件:** `InternalLib/Utilities/Materials.glsl`

**核心功能:**
- LabPBR 1.3 完整支持（TEXTURE_FORMAT_LAB / OLD / VANILLA）
- 统一材质数据结构
- 基于 materialID 的 fallback 材质

**labPBR 纹理格式:**
```
R: Roughness (0-1)
G: Metallic (0-1)
B: Specular Strength (0-1)
A: Emission Strength (0-1)
```

**Fallback 材质表:**
| MaterialID | Roughness | Metallic | Specular | Subsurface |
|------------|-----------|----------|----------|------------|
| 石头 | 0.7 | 0.0 | 0.02 | 0.0 |
| 木材 | 0.6 | 0.0 | 0.03 | 0.1 |
| 金属 | 0.3 | 1.0 | 0.8 | 0.0 |
| 玻璃 | 0.1 | 0.0 | 0.04 | 0.0 |
| 水体 | 0.2 | 0.0 | 0.02 | 0.0 |

### 3.2 材质测试集

**文件:** `docs/MATERIAL-TEST-SUITE.md`

**测试场景:**
- 石材：花岗岩/闪长岩/安山岩
- 木材：橡木/云杉/白桦/深色橡木
- 金属：铁块/金块/铜块/钻石块
- 玻璃：透明/染色/玻璃板
- 发光：荧石/海晶灯/红石火把/灵魂火把

---

## Phase 4: 高级光照与反射

### 4.1 Image Slot 优化

**问题:** 16/16 slots 已满，无法实现 HiZ-SSR

**解决方案:** 合并 Cloud 相关 images

**合并前:**
```
image.cloudImg (0.25x)           → rgba16f
image.cloudImgUpscaled (1.0x)    → rgba16f
image.cloudImgFeedback (1.0x)    → rgba16f
```

**合并后:**
```
image.cloudCombinedTex (1.0x)    → rgba16f
  R: upscaled color
  G: feedback color
  BA: motion vectors (可选)
```

**释放 slots:** 2 个

### 4.2 HiZ 金字塔生成

**文件:** `Composite7_HiZ.glsl` (新建)

**实现:**
- 10 层 Mipmap 金字塔 (1024→1)
- 每层取 4 样本最大值
- 用于 SSR 快速深度测试

**SSR March:**
- 64 步最大迭代
- 根据深度差动态调整 mip 层级
- 粗糙度感知终止条件

### 4.3 GTAO 实现

**文件:** `Deferred4_GTAO.glsl` (新建)

**参数:**
- 16 样本半球采样
- 0.5 半径
- 四分之一分辨率渲染

**优化:**
- 使用 TAA 时域复用
- 与体积光共享随机数

---

## Phase 5: 模组兼容性扩展

### 5.1 维度识别框架

**文件:** `InternalLib/Common/Dimension.glsl`

**支持的维度:**
| ID | 维度 | 天空颜色 | 雾颜色 | 大气 |
|----|------|----------|--------|------|
| 0 | Overworld | (0.5,0.7,1.0) | (0.8,0.9,1.0) | ✓ |
| 1 | Nether | (0.3,0.1,0.1) | (0.5,0.2,0.1) | ✓ |
| 2 | End | (0.6,0.5,0.8) | (0.8,0.7,0.9) | ✗ |
| 10 | Twilight Forest | (0.3,0.4,0.6) | (0.4,0.5,0.6) | ✓ |
| 11 | Aether | (0.8,0.9,1.0) | (0.9,0.95,1.0) | ✓ |
| 12 | Mars (Ad Astra) | (0.9,0.4,0.3) | (0.8,0.5,0.4) | ✓ |
| 13 | Moon (Ad Astra) | (0,0,0) | (0,0,0) | ✗ |

### 5.2 dimension.properties 配置

```properties
dim0=overworld
dim1=nether
dim2=end
dim.twilight_forest=twilight_forest
dim.the_aether=aether
dim.mars=ad_astra
dim.moon=ad_astra

dim0.sky=DefaultSky
dim.twilight_forest.sky=TwilightSky
dim.the_aether.sky=AetherSky
dim.mars.sky=MarsSky
dim.moon.sky=MoonSky
```

---

## Phase 6: 实验性光线追踪

### 6.1 SSGI 原型

**文件:** `Deferred6_SSGI.glsl` (新建)

**实现:**
- 32 射线半球采样
- 16 步 March
- 屏幕空间深度测试

**性能:**
- EXTREME 档启用
- 半分辨率渲染
- TAA 时域复用

### 6.2 技术边界说明

**当前限制:**
- OpenGL 不支持硬件 RT
- 仅实现屏幕空间方法
- 无法穿透几何体

**未来方向:**
- 体素光线追踪研究
- 时空重采样 (ReSTIR)
- 混合渲染路径

---

## 资源状态更新

| 资源 | Phase 2 | 优化后 | 使用率 |
|------|---------|--------|--------|
| Image Slots | 16/16 | 14/16 | 87.5% |
| Colortex | 15/15 | 15/15 | 100% |
| SSBO | 5/8 | 5/8 | 62.5% |

**释放的 2 个 slots:**
- Slot 14: HiZ 金字塔
- Slot 15: 备用/SSGI 临时 buffer

---

## 提交历史

| 提交 | 阶段 | 描述 |
|------|------|------|
| 3777d97 | Phase 2 | 色彩管理重构 |
| [待生成] | Phase 3 | PBR 材质系统 |
| [待生成] | Phase 4 | HiZ-SSR + GTAO |
| [待生成] | Phase 5 | 维度大气 |
| [待生成] | Phase 6 | SSGI 原型 |

---

**文档结束**
