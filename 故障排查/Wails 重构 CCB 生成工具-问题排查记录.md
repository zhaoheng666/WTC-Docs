# Wails 重构 CCB 生成工具-问题排查记录

## 1. 生产构建黑屏问题

### 🚨 问题描述

- **症状**: `wails dev` 正常显示，`wails build` 后的应用启动显示黑屏
- **影响**: 生产版本完全无法使用
- **反复出现**: 最顽固的问题

### 🔍 根因分析

这是一个**复合问题**，涉及三个不同的根因：

1. **Vite 资源路径问题**

    - Vite 默认使用绝对路径 (`/assets/`)
    - Wails 需要相对路径 (`./assets/`)
2. **Go embed 文件系统问题**

    - 直接使用 `assets` embed.FS
    - 需要使用 `fs.Sub(assets, "frontend/dist")`​
3. **Vue 全局变量未定义**

    - 生产构建缺少 Vue 运行时全局变量
    - 导致 JavaScript 错误

### ✅ 解决方案

#### 1. 修复 Vite 配置 (`vite.config.ts`)

```typescript
export default defineConfig({
  plugins: [vue()],
  base: './',  // 关键：使用相对路径
  build: { assetsDir: 'assets' },
  define: {
    // 定义 Vue 全局变量
    '__VUE_PROD_HYDRATION_MISMATCH_DETAILS__': false,
    '__VUE_OPTIONS_API__': true,
    '__VUE_PROD_DEVTOOLS__': false
  }
})
```

#### 2. 修复 Go 文件系统 (`main.go`)

```go
//go:embed all:frontend/dist
var assets embed.FS

// 关键：创建子文件系统
assetsFS, err := fs.Sub(assets, "frontend/dist")
if err != nil {
    panic(err)
}

AssetServer: &assetserver.Options{
    Assets: assetsFS,  // 使用子文件系统
},
```

---

## 2. Frame 预览显示问题

### 🚨 问题描述

- **症状**: 所有 frame 预览显示 "No preview"
- **影响**: 无法预览提取的图像帧

### 🔍 根因分析

Canvas 图像提取逻辑与原始 Python 算法不完全匹配，特别是：

- 旋转处理逻辑差异
- 坐标系统差异
- 图像粘贴位置计算错误

### ✅ 解决方案

完全按照原始 Electron 版本的算法重新实现：

```javascript
// 关键修复：正确的旋转和坐标处理
if (frameData.rotated) {
  // PIL rotate(90) 是逆时针旋转
  rotatedCtx.translate(0, width)
  rotatedCtx.rotate(-Math.PI / 2)
  rotatedCtx.drawImage(cropCanvas, 0, 0)
}

// 正确的粘贴位置计算
const sourceColorRect = toList(frameData.sourceColorRect).map(x => parseInt(x))
resultCtx.drawImage(rect_on_big, sourceColorRect[0], sourceColorRect[1])
```

### 🔧 预防措施

- 严格按照原始实现移植算法
- 使用详细的调试日志验证每个步骤
- 与原始版本逐步对比输出结果

---

## 3. CCB 文件名重复前缀问题

### 🚨 问题描述

- **症状**: 生成文件名为 `luxurious_vaults_symbol_batch_luxurious_vaults_symbol_batch_7_1.ccb`​
- **期望**: `luxurious_vaults_symbol_batch_7_1.ccb`​

### 🔍 根因分析

输出路径构建逻辑错误：

```javascript
// 错误的方式
const outputPath = selectedFile.value.replace('.plist', `_${frame.ccbFileName}`)
```

这导致：

- ​`selectedFile.value`: `luxurious_vaults_symbol_batch.plist`​
- ​`frame.ccbFileName`: `luxurious_vaults_symbol_batch_7_1.ccb`​
- 结果: `luxurious_vaults_symbol_batch_luxurious_vaults_symbol_batch_7_1.ccb`​

### ✅ 解决方案

```javascript
// 正确的方式：直接在同目录生成
const baseDir = selectedFile.value.substring(0, selectedFile.value.lastIndexOf('/'))
const outputPath = `${baseDir}/${frame.ccbFileName}`
```

---

## 4. 开发者工具Inspect卡死问题

### 🚨 问题描述

- **症状**: 打开开发者工具后界面卡死，无法操作
- **影响**: 无法调试应用

### 🔍 根因分析

过量的 `console.log` 输出导致浏览器开发者工具性能问题：

```javascript
// 问题代码：大量高频日志
for (const [frameName, frameData] of Object.entries(plistData.frames)) {
  console.log('Processing frame:', frameName, 'frameData:', frameData) // 复杂对象
  console.log('Atlas image loaded, size:', img.width, 'x', img.height)
  // ... 更多日志
}
```

### ✅ 解决方案

- 移除或简化调试日志
- 只保留关键的统计信息：

```javascript
console.log(`Frame extraction: ${successCount}/${frameItems.length} successful`)
```

- 强制启用生产环境 Devtools，wails.json define 添加变量`'__VUE_PROD_DEVTOOLS__': true`​

  覆盖 Vue 3 生产构建时默认禁用 Devtools 的行为

---

## 5. 命令行参数传递问题

### 🚨 问题描述

- **症状**: 使用 `open` 命令启动应用时参数未传递到应用

### 🔍 根因分析

macOS `open` 命令的行为差异：

- ​`open app.app --args --template path` ❌ 参数传递可能失败
- ​`./app.app/Contents/MacOS/app --template path` ✅ 直接执行正常

### ✅ 解决方案

#### 方法1：直接执行（推荐）

```bash
./createSymbols.app/Contents/MacOS/createSymbols --template "/path/to/template"
```

#### 方法2：正确使用 open 命令

```bash
open createSymbols.app --args --template "/path/to/template"
```

---

## 6. Wails 项目模板选择问题

### 🚨 问题描述

- **症状**: 初始创建项目时选择了错误的模板
- **影响**: 缺少 Vue 和 TypeScript 支持

### 🔍 根因分析

使用了 `wails init -n createSymbols -t vanilla` 而不是 `vue-ts`​

### ✅ 解决方案

```bash
# 正确的创建命令
wails init -n createSymbols -t vue-ts -d createSymbols
```

---

## 7. Data URL 格式错误问题

### 🚨 问题描述

- **症状**: "Failed to load resource: Data URL decoding failed"
- **影响**: 图像无法正确显示

### 🔍 根因分析

重复添加 Data URL 前缀：

```javascript
// Go 后端已经返回完整的 data URL
return fmt.Sprintf("data:%s;base64,%s", mimeType, encoded)

// 前端又添加了前缀
img.src = `data:image/png;base64,${atlasBase64}` // ❌ 双重前缀
```

### ✅ 解决方案

```javascript
// 直接使用 Go 返回的完整 data URL
img.src = atlasDataUrl // ✅ 正确
```

---

## 8. Vue 全局变量错误

### 🚨 问题描述

- **症状**: `ReferenceError: Can't find variable: __VUE_PROD_HYDRATION_MISMATCH_DETAILS__`​
- **影响**: 生产构建 JavaScript 运行时错误

### 🔍 根因分析

Vue 3 在生产构建时需要特定的全局变量，但 Vite 配置中未定义。

### ✅ 解决方案

在 `vite.config.ts` 中定义所需的全局变量：

```typescript
define: {
  '__VUE_PROD_HYDRATION_MISMATCH_DETAILS__': false,
  '__VUE_OPTIONS_API__': true,
  '__VUE_PROD_DEVTOOLS__': false
}
```

---

## 🛠️ 通用调试技巧

### 1. 分层调试法

1. **网络层**: 检查资源加载 (Network tab)
2. **JavaScript层**: 检查控制台错误 (Console tab)
3. **应用层**: 检查功能逻辑
4. **系统层**: 检查文件权限和路径

### 2. 对比调试法

- 开发模式 vs 生产模式
- 原始版本 vs 新版本
- 不同操作系统的行为差异

### 3. 最小化重现法

- 创建最简单的测试用例
- 逐步添加复杂性
- 确定引入问题的最小变更

### 4. 版本控制策略

- 小步提交，便于回滚
- 详细的提交信息记录问题和解决方案
- 使用分支隔离实验性修复

---

## 📚 相关资源

- [Wails v2 官方文档](https://wails.io/docs/introduction)
- [Vue 3 生产构建指南](https://vuejs.org/guide/best-practices/production-deployment.html)
- [Vite 配置参考](https://vitejs.dev/config/)
- [Go embed 文档](https://pkg.go.dev/embed)
