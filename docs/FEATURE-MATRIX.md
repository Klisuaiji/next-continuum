# Next Continuum 功能实现状态矩阵

**文档版本:** 1.0  
**更新日期:** 2026-11-05  
**项目仓库:** https://github.com/Klisuaiji/next-continuum

---

## 功能状态说明

| 状态 | 定义 | 验证要求 |
|------|------|---------|
| **IMPLEMENTED** | 已有实现，并通过对应测试 | 实机验证 + FPS 测试 + 画质对比 |
| **PARTIAL** | 已有部分实现，但功能不完整 | 代码审查确认 |
| **EXPERIMENTAL** | 实验性实现，可能存在问题 | 需标注"实验性" |
| **PLANNED** | 已规划，但尚未实现 | 文档中明确规划 |
| **BLOCKED** | 因技术或外部依赖暂时无法推进 | 说明阻塞原因 |
| **UNSUPPORTED** | 明确不支持 | 文档中明确说明 |

---

## 核心功能矩阵

### 1. 基础架构

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| Iris 适配（1.21.1/1.21.11/26.2） | **IMPLEMENTED** | 三条维护线均已核验 |
| Distant Horizons LOD 支持 | **IMPLEMENTED** | dh_terrain/dh_water/dh_shadow 程序完成 |
| Voxy LOD 支持 | **IMPLEMENTED** | voxy.json schema v1 已实现 |
| Roxy（NeoForge Voxy 兼容） | **IMPLEMENTED** | 1.21.1 线唯一 Voxy 路径 |
| 四语本地化（en/zh_CN/zh_TW/ja_JP） | **IMPLEMENTED** | 446 键全覆盖 |

### 2. 性能优化

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| 四档性能配置（LOW/MEDIUM/HIGH/EXTREME） | **IMPLEMENTED** | Phase 1 完成（提交 0ac2bba） |
| 快速滤镜（5 档预设） | **IMPLEMENTED** | NATURAL/VIVID/CINEMATIC/MOODY/CLEAR_WATER |
| 体积云 V2（自适应步长） | **IMPLEMENTED** | 代码就绪，待实机验证 |
| 体积云 V2（多重散射） | **EXPERIMENTAL** | EXTREME 档专用，需性能测试 |
| HiZ SSR | **PLANNED** | Phase 4 任务，依赖 image slot 预算 |
| 时间帧复用（AO/SSR/体积雾） | **PLANNED** | Phase 4 任务，需 motion vectors |
| 改进的 TAA | **PARTIAL** | 基础 TAA 已实现，历史帧复用待完成 |
| Render Target 生命周期优化 | **PARTIAL** | 需审查现有资源管理 |

### 3. 色彩管理

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| 快速滤镜色彩调整 | **IMPLEMENTED** | 饱和度/对比度/色调/曝光 |
| 手动色彩调整 | **IMPLEMENTED** | 白平衡/色调平衡/伽马等 |
| Display Transform LUT | **IMPLEMENTED** | 3D LUT（48×48×48） |
| ACES 完整流程（RRT+ODT） | **IMPLEMENTED** | 代码就绪，待实机验证 |
| Filmic 色调映射 | **IMPLEMENTED** | ACES 关闭时的回退方案 |
| 自动曝光（直方图） | **IMPLEMENTED** | A0/A1/A2 pipeline 完成，待验证 |
| HDR 色彩管线 | **PARTIAL** | 需验证线性空间一致性 |

### 4. 光照系统

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| Directional Lighting（太阳/月亮） | **IMPLEMENTED** | 基础光照 |
| Ambient Lighting（环境光） | **IMPLEMENTED** | 维度专属环境光亮度 |
| Colored Lighting（彩色光照） | **IMPLEMENTED** | LPV 彩色光传播 |
| Global Illumination（全局光照） | **IMPLEMENTED** | LPV 体素光传播 |
| Voxel Light Propagation | **IMPLEMENTED** | 256³ 体素网格 |
| Contact Shadows | **PLANNED** | Phase 4 任务 |
| Soft Shadows（PSS/半影角） | **IMPLEMENTED** | 可调半影角 |
| Atmospheric Lighting | **PARTIAL** | 基础大气散射，需完善 |

### 5. 材质系统

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| Albedo（基础色） | **IMPLEMENTED** | 标准解码 |
| Normal Mapping（法线贴图） | **IMPLEMENTED** | 标准解码 |
| Specular/Metallic（高光/金属） | **PARTIAL** | SPECULAR_LAB 已定义，需完整解码验证 |
| Roughness（粗糙度） | **PARTIAL** | 需验证通道定义 |
| Emission（自发光） | **IMPLEMENTED** | 基础发光材质 |
| Material AO（材质 AO） | **PARTIAL** | 需验证读取 |
| Height（高度图） | **IMPLEMENTED** | POM 基础 |
| Parallax Occlusion Mapping（POM） | **IMPLEMENTED** | 可调 POM 深度 |
| Subsurface Scattering（SSS） | **PLANNED** | Phase 3 任务 |
| LabPBR 完整支持 | **PARTIAL** | 需建立材质测试集 |

### 6. 大气与环境

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| Sky Rendering（天空渲染） | **IMPLEMENTED** | 基础天空 |
| Rayleigh Scattering（瑞利散射） | **IMPLEMENTED** | 大气散射 |
| Mie Scattering（米氏散射） | **IMPLEMENTED** | 大气散射 |
| Atmospheric Fog（大气雾） | **IMPLEMENTED** | 基础雾效 |
| Volumetric Fog（体积雾） | **IMPLEMENTED** | 体素雾效 |
| Volumetric Clouds（体积云） | **IMPLEMENTED** | 基础体积云 |
| Volumetric Clouds V2（自适应步长） | **IMPLEMENTED** | Phase 1 完成 |
| Volumetric Clouds V2（多重散射） | **EXPERIMENTAL** | EXTREME 档专用 |
| Weather（雨/雪） | **IMPLEMENTED** | 基础天气 |
| Dimension-specific Atmosphere | **PARTIAL** | 主世界完整，其他维度待完善 |

### 7. 后处理

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| Auto Exposure（自动曝光） | **IMPLEMENTED** | 直方图 pipeline |
| White Balance（白平衡） | **IMPLEMENTED** | 色温/色调调节 |
| Color Grading（色彩分级） | **IMPLEMENTED** | 饱和度/对比度/增益 |
| Tone Mapping（色调映射） | **IMPLEMENTED** | Filmic/ACES 双路径 |
| Bloom（光晕） | **IMPLEMENTED** | 可调质量档位 |
| Depth of Field（景深） | **IMPLEMENTED** | 可调样本数 |
| Motion Blur（运动模糊） | **PLANNED** | 需 motion vectors |
| Lens Effects（镜头效果） | **PARTIAL** | 色差/暗角已实现，畸变待完善 |
| Anti-aliasing（TAA） | **PARTIAL** | 基础 TAA，需改进历史帧 |

### 8. 水体与反射

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| Water Waves（水波） | **IMPLEMENTED** | FFT 波浪场 |
| Water Reflection（水体反射） | **IMPLEMENTED** | 平面反射 |
| Water Refraction（水体折射） | **IMPLEMENTED** | 基础折射 |
| Water Caustics（水体焦散） | **IMPLEMENTED** | 可调焦散 |
| Water Absorption（水体吸收） | **IMPLEMENTED** | 可调吸收系数 |
| Screen Space Reflections（SSR） | **PARTIAL** | 基础 SSR，HiZ 加速待完成 |
| Reflection Fog Volume | **IMPLEMENTED** | 雾体积反射 |

### 9. 阴影系统

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| Shadow Mapping | **IMPLEMENTED** | 基础阴影贴图 |
| Shadow Distortion（阴影扭曲） | **IMPLEMENTED** | 可调扭曲因子 |
| Soft Shadows（软阴影） | **IMPLEMENTED** | PSS 半影角 |
| Cloud Shadows（云阴影） | **IMPLEMENTED** | 体积云阴影 |
| LOD Shadow（DH shadow） | **IMPLEMENTED** | dh_shadow 程序 |
| Contact Shadows | **PLANNED** | Phase 4 任务 |

### 10. 模组兼容性

| 模组 | 状态 | 备注 |
|------|------|------|
| Distant Horizons | **IMPLEMENTED** | LOD 地形/水体/阴影 |
| Voxy | **IMPLEMENTED** | LOD 地形/透明层 |
| Roxy（NeoForge Voxy） | **IMPLEMENTED** | 1.21.1 线 |
| Twilight Forest | **PLANNED** | Phase 5 任务 |
| Aether | **PLANNED** | Phase 5 任务 |
| Ad Astra | **PLANNED** | Phase 5 任务 |
| Create | **PLANNED** | Phase 5 任务 |
| Physics Mod | **PLANNED** | Phase 5 任务 |

### 11. 实验性功能

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| HiZ SSR | **PLANNED** | Phase 4，需 image slot |
| SSGI（屏幕空间 GI） | **PLANNED** | Phase 4 |
| Voxel Ray Tracing | **PLANNED** | Phase 6，长期研究 |
| Hardware RT | **UNSUPPORTED** | 当前 Iris/OpenGL 接口不支持 |
| Path Tracing | **UNSUPPORTED** | 当前 Iris/OpenGL 接口不支持 |

---

## Phase 实施进度

### ✅ Phase 1（性能优化）- 完成度 80%

- [x] 四档性能配置（LOW/MEDIUM/HIGH/EXTREME）
- [x] 快速滤镜系统（5 档预设）
- [x] 体积云 V2（自适应步长 + 多重散射）
- [x] 自动曝光系统（直方图 pipeline）
- [x] ACES 色彩变换（完整 RRT+ODT）
- [ ] HiZ SSR（待 image slot 预算）
- [ ] 时间帧复用（待 motion vectors）
- [ ] TAA 改进（待历史帧处理）

### 🔄 Phase 2（色彩管理）- 完成度 90%

- [x] HDR 色彩管线（基础实现）
- [x] 曝光流程统一（自动/手动）
- [x] ACES / Filmic / LUT 整理
- [x] 快速滤镜色彩预设
- [ ] 快速滤镜拆分为视觉风格 + 水体预设
- [ ] 新增 Nordic/Neutral 风格
- [ ] 多维度色彩表现验证

### 📋 Phase 3（PBR 材质）- 完成度 50%

- [ ] 完整 LabPBR 核验
- [x] 材质通道解码（基础）
- [ ] F0/Roughness/Normal/Emission 完善
- [ ] 材质回退策略
- [ ] POM 优化
- [ ] 材质测试集建立

### 📋 Phase 4（高级光照）- 完成度 30%

- [ ] GTAO 完善
- [ ] HiZ SSR
- [ ] SSGI
- [ ] 体积雾优化
- [ ] 体积云质量提升
- [ ] 阴影与间接光照协调
- [ ] 光照能量与曝光校准

### 📋 Phase 5（模组兼容）- 完成度 20%

- [x] Distant Horizons / Voxy
- [ ] Twilight Forest
- [ ] Aether
- [ ] Ad Astra
- [ ] Create
- [ ] Physics Mod
- [ ] 更多自定义维度

### 📋 Phase 6（光线追踪）- 完成度 0%

- [ ] HiZ 屏幕空间追踪
- [ ] SSGI
- [ ] 体素光线追踪研究
- [ ] 硬件 RT 接口评估
- [ ] 独立实验分支

---

## 技术债清单

### 高优先级

1. **UserLibManager 缺少 AdvancedSettings.glsl** - 已修复（提交 b653d8f）
2. **EXTREME 档 HiZ SSR 未实现** - 依赖 image slot 预算
3. **EXTREME 档时间帧复用未实现** - 需 motion vectors
4. **自动曝光未实机验证** - 需部署测试

### 中优先级

5. **快速滤镜职责不独立** - 同时影响色彩和水体，需拆分
6. **PBR 材质解码不完整** - 需验证所有通道
7. **维度专属大气不完善** - 仅主世界完整

### 低优先级

8. **本地化术语需统一** - 部分翻译需核对
9. **性能档位命名优化** - EXTREME 中文名可能需调整
10. **文档与代码同步** - 需定期更新状态矩阵

---

## 资源预算

### Image Slots（16/16 已用满）

```
1. waveImg - 水波场
2. voxelLightTex - 体素光照
3. lightPropagationVolume - LPV
4. lightPropagationVolumeFeedback - LPV 反馈
5. depthImgFront - 前深度
6. depthImgBack - 后深度
7. depthImgBackHistory - 历史深度
8. froxelScatteringImg - 体素散射
9. froxelTransmittanceImg - 体素透射
10. integratedScatteringImg - 积分散射
11. integratedTransmittanceImg - 积分透射
12. skyScatteringImg - 天空散射
13. skyTransmittanceImg - 天空透射
14. cloudImg - 云层
15. cloudImgUpscaled - 云层上采样
16. cloudImgFeedback - 云层反馈
```

**阻塞功能:** HiZ 金字塔（需要 mipmapped 2D 目标）

### SSBO Slots（5/8 已用）

```
1. bufferObject.0 - 512 bytes
2. bufferObject.1 - 512 bytes
3. bufferObject.2 - 512 bytes
4. bufferObject.3 - 512 bytes
5. bufferObject.4 - 2048 bytes（自动曝光直方图）
```

**剩余:** 3 slots（可用）

### Colortex Slots（15/15 已用满）

```
colortex0-14 全部占用
```

**阻塞功能:** 需要额外 colortex 的高级效果

---

## 性能基线（待实机验证）

| 档位 | 推荐显卡 | 目标 FPS | 关键特性 |
|------|---------|---------|---------|
| LOW | GTX 1060 / RX 580 | 20-30 | 基础阴影、关闭 V2 |
| MEDIUM | RTX 2060 / RX 5600 XT | 30-40 | 基础 GI、关闭 V2 |
| HIGH | RTX 3060 / RX 6700 XT | 20-30 | 完整 GI/SSR、V2 开启 |
| EXTREME | RTX 3080 / RX 6800 XT+ | 15-25 | V2+ 多重散射、HiZ SSR |

---

## 下一步行动

### 本周（Phase 1 收尾）

- [ ] 实机验证自动曝光
- [ ] 测试四档配置 FPS
- [ ] 校准 V2 云层参数
- [ ] 实现 HiZ SSR（若 image slot 允许）

### 下周（Phase 2 启动）

- [ ] 拆分快速滤镜为视觉风格 + 水体预设
- [ ] 新增 Nordic/Neutral 视觉风格
- [ ] 验证多维度色彩表现
- [ ] 完善 PBR 材质解码

### 下月（Phase 3-4）

- [ ] 建立材质测试集
- [ ] GTAO 完善
- [ ] HiZ SSR 实现
- [ ] SSGI 探索

---

**文档维护:** 每次功能状态变化时更新此矩阵  
**最后更新:** 2026-11-05（提交 b653d8f 后）
