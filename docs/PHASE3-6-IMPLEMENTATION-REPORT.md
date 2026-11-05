# Phase 3-6 实施报告（自查修订版）

**修订日期:** 2026-11-05  
**修订原因:** 首次提交（85c4465 / 6302917）经自查发现多处破坏性错误，本版记录真实状态与修复结果

---

## 自查发现的问题与修复

以下问题由 `scripts/check_includes.py`、`scripts/check_resources.py` 与人工审查发现：

| # | 问题 | 严重度 | 状态 |
|---|------|--------|------|
| 1 | 覆盖了 `InternalLib/Utilities/Materials.glsl`，丢失 `GetLightColor`/`GetEmitterMask` 等函数，`AirVolume.glsl:102` 等处引用断裂 | 严重 | 已还原原文件；LabPBR 内容移入新文件 `MaterialPBR.glsl` |
| 2 | 覆盖了 `dimension.properties`，Iris 真实语法（`dimension.DimX = ...`）被替换为无效语法 | 严重 | 已还原原文件 |
| 3 | image 声明达 17 个，超出 16 上限（`check_resources.py` FAIL）；`cloudCombinedTex` 无任何代码引用 | 严重 | 已还原原 16 个 image 声明 |
| 4 | `froxelTransmittanceImg` 格式写成 `r11f_g11f_b11f`（无效格式）；sliders 中 `HORIZON_WAVE_FADE_FADE_FALLOFF` 拼写错误 | 严重 | 已修正 |
| 5 | 新增 3 个 shader 文件引用不存在的 include（Vertex.glsl/Fragment.glsl/NoiseLib.glsl），`check_includes.py` FAIL | 严重 | 已重写为无依赖的自包含参考模块 |
| 6 | `Dimension.glsl`/`WaterPresetSettings.glsl` 使用 `#elifdef`（GLSL 预处理器不支持）；维度宏名错误（`DIMENSION_NETHER`，实际约定为 `DIM_NETHER`） | 中 | 已重写，宏名与 DimNether/DimEnd 程序目录一致 |
| 7 | shaders.properties 中 `variable.int.*` 等非标准注册方式；`program.composite7.enabled`（composite7 程序不存在）；`deferred4/6` 门控被改坏 | 中 | 已移除/还原 |
| 8 | lang 文件 `option.QUICK_FILTER` 键重复（新增 116 行与既有 519 行冲突）；大量描述未接线选项的条目 | 低 | 已还原 lang 文件 |
| 9 | `VS_STYLE_NAME "Natural"` 等 GLSL 字符串宏（GLSL 无字符串） | 低 | 已移除 |

**核心教训:** 修改前必须读取目标文件的现有内容；资源类修改必须跑 `scripts/check_resources.py` 验证。

---

## 当前真实状态

### Phase 2 色彩管理（部分完成）

**已落地:**
- `UserLib/VisualStyleSettings.glsl`: 6 档视觉风格参数表（NATURAL 为数值 no-op，包含安全）
- `UserLib/WaterPresetSettings.glsl`: 6 档水体预设参数表 + Beer-Lambert 吸收辅助函数
- `UserLib/QuickFilterSettings.glsl`: 保留 Phase 1 完整功能，新增 `QUICK_FILTER_COMPAT_MODE` 兼容宏
- `InternalLib/UserLibManager.glsl`: 两个新设置文件已接线（含 include 顺序约束说明）
- 保留 `WATER_SETTINGS` 屏幕中 `<empty` 拼写修复

**待接线（后续工作）:**
- VS_* 参数在最终后处理通道的应用（色彩分级生效点）
- WP_* 参数在水体着色路径与波浪场路径的应用
- GUI 注册（GLSL `//[]` 注释 + lang 条目 + shaders.properties screen 槽位）——待应用点落地后一并加入，避免出现无效选项

### Phase 3 PBR 材质（库文件就绪）

- 原 `Materials.glsl`（vanilla block-ID 辅助函数）完整保留，未被触碰
- 新增 `InternalLib/Utilities/MaterialPBR.glsl`: labPBR 1.3 解码库（roughness/f0/emission 解码、tangent 变换、按材质类别的 fallback 常量表），调用方需定义 `MATERIAL_PBR_FORMAT`
- `docs/MATERIAL-TEST-SUITE.md`: 材质测试集
- 待接线: gbuffer 编码/解码链消费该库

### Phase 4 高级光照（参考模块就绪）

- `Composite7_HiZ.glsl`: HiZ 金字塔归约 + 屏幕空间 march 算法（参考模块，无依赖）
- `Deferred4_GTAO.glsl`: 逐切片水平积分 GTAO 核（参考模块，纯函数）
- **资源约束未解决:** image 槽位仍为 16/16，HiZ 金字塔目标缓冲需要先释放槽位（候选方案：审查低利用率 target，或改用 colortex mip 链）。此为硬前置条件。
- `AO_GTAO`/`HIZ_SSR` 开关已在 Phase 1 定义于 `UserLib/AdvancedSettings.glsl`，程序接线待资源就绪

### Phase 5 维度兼容（框架就绪）

- `InternalLib/Common/Dimension.glsl`: 按代码库真实宏约定（`DIM_OVERWORLD`/`DIM_NETHER`/`DIM_END`）重写，非法维度回退 Overworld
- `dimension.properties`: 保留 Iris 原生三维度映射
- **模组维度（Twilight Forest/Aether/Ad Astra）需要专属维度程序目录 + `dimension.properties` 注册**，参数已预留于代码注释

### Phase 6 实验光追（原型就绪）

- `Deferred6_SSGI.glsl`: 余弦加权半球采样 + 屏幕空间 march 控制流（参考模块）
- 现有体素/LPV GI（Passes/D4-D6）未受影响

### 资源状态（还原后）

| 资源 | 状态 |
|------|------|
| Image slots | 16/16（与 Phase 1 相同，未占用） |
| Colortex | 15/15 |
| SSBO | 5/8 |

---

## 验证结果

```
python3 scripts/check_includes.py   -> PASS（354 文件，4863 include 边）
python3 scripts/check_resources.py  -> PASS（image 16/16，上限内）
python3 scripts/check_lod_macros.py -> 无法运行（依赖 glslangValidator，环境未安装）
python3 scripts/check_glsl.py       -> 无法运行（依赖 glslangValidator，环境未安装）
```

`check_lod_macros.py` 与 `check_glsl.py` 的失败为环境缺工具（修复前即如此），与本次改动无关。

---

## 提交历史（本阶段）

| 提交 | 阶段 | 描述 |
|------|------|------|
| 3777d97 | Phase 2 | 色彩管理参数层（含后续修复） |
| 85c4465 | Phase 3-6 | 首次实施（含破坏性错误，已由本次自查修复） |
| 6302917 | i18n | lang 条目（已还原，待应用点落地后重做） |
| 本次 | 自查修复 | 还原被覆盖文件、修复资源超限与无效语法 |

---

**文档结束**
