# Phase 3 材质测试集

**文档版本:** 1.0  
**测试目的:** 验证 PBR 材质系统正确解码和渲染

---

## 测试环境

- **着色器版本:** Continuum 2.0 Redux Phase 3
- **PBR 格式:** labPBR 1.3
- **测试材质:** TEXTURE_FORMAT_LAB

---

## 石材测试

### 花岗岩 (Granite)

**材质参数:**
- Roughness: 0.75
- Metallic: 0.0
- Specular: 0.02
- Subsurface: 0.0

**预期效果:**
- 粗糙表面，无金属反射
- 低强度镜面高光
- 无次表面散射

### 闪长岩 (Diorite)

**材质参数:**
- Roughness: 0.65
- Metallic: 0.0
- Specular: 0.02
- Subsurface: 0.0

**预期效果:**
- 中等粗糙度
- 白色晶体反光

### 安山岩 (Andesite)

**材质参数:**
- Roughness: 0.7
- Metallic: 0.0
- Specular: 0.02
- Subsurface: 0.0

---

## 木材测试

### 橡木 (Oak Wood)

**材质参数:**
- Roughness: 0.6
- Metallic: 0.0
- Specular: 0.03
- Subsurface: 0.1

**预期效果:**
- 温暖色调
- 轻微次表面散射（透光感）

### 云杉 (Spruce Wood)

**材质参数:**
- Roughness: 0.65
- Metallic: 0.0
- Specular: 0.03
- Subsurface: 0.1

### 白桦 (Birch Wood)

**材质参数:**
- Roughness: 0.55
- Metallic: 0.0
- Specular: 0.03
- Subsurface: 0.08

---

## 金属测试

### 铁块 (Iron Block)

**材质参数:**
- Roughness: 0.35
- Metallic: 1.0
- Specular: 0.8
- Subsurface: 0.0

**预期效果:**
- 完整金属反射
- 高镜面强度
- 反射环境颜色

### 金块 (Gold Block)

**材质参数:**
- Roughness: 0.25
- Metallic: 1.0
- Specular: 0.9
- Subsurface: 0.0

**预期效果:**
- 金黄色反射
- 低粗糙度高光

### 铜块 (Copper Block)

**材质参数:**
- Roughness: 0.3
- Metallic: 1.0
- Specular: 0.85
- Subsurface: 0.0

**预期效果:**
- 橙红色金属反射
- 氧化表面（如有）

### 钻石块 (Diamond Block)

**材质参数:**
- Roughness: 0.15
- Metallic: 1.0
- Specular: 0.95
- Subsurface: 0.0

---

## 玻璃测试

### 透明玻璃 (Clear Glass)

**材质参数:**
- Roughness: 0.1
- Metallic: 0.0
- Specular: 0.04
- Subsurface: 0.0

**预期效果:**
- 低粗糙度镜面反射
- 透明材质（需要折射支持）

### 染色玻璃 (Stained Glass)

**材质参数:**
- Roughness: 0.1
- Metallic: 0.0
- Specular: 0.04
- Subsurface: 0.0
- Albedo: 彩色

---

## 水体测试

### 自然水体 (Natural Water)

**材质参数:**
- Roughness: 0.2
- Metallic: 0.0
- Specular: 0.02
- Subsurface: 0.0

**预期效果:**
- 柔和波浪高光
- 与 WaterPreset 参数联动

---

## 发光材质测试

### 荧石 (Glowstone)

**材质参数:**
- Roughness: 0.5
- Metallic: 0.0
- Specular: 0.02
- Emission: 1.0

### 海晶灯 (Sea Lantern)

**材质参数:**
- Roughness: 0.4
- Metallic: 0.0
- Specular: 0.02
- Emission: 0.9

### 红石火把 (Redstone Torch)

**材质参数:**
- Roughness: 0.6
- Metallic: 0.0
- Specular: 0.02
- Emission: 0.6 (红色通道增强)

### 灵魂火把 (Soul Torch)

**材质参数:**
- Roughness: 0.6
- Metallic: 0.0
- Specular: 0.02
- Emission: 0.5 (蓝色通道增强)

---

## 验证清单

### LabPBR 解码验证
- [ ] specularMap.r 正确映射为 roughness
- [ ] specularMap.g 正确映射为 metallic
- [ ] specularMap.b 正确映射为 specular strength
- [ ] specularMap.a 正确映射为 emission

### Fallback 材质验证
- [ ] 无 labPBR 纹理时使用 fallback 参数
- [ ] materialID 识别正确
- [ ] 默认材质参数合理

### 视觉效果验证
- [ ] 金属材质反射环境
- [ ] 非金属材质介电反射
- [ ] 粗糙表面高光扩散
- [ ] 光滑表面高光集中
- [ ] 发光材质自发光正确

---

## 已知问题

暂无

---

**文档结束**
