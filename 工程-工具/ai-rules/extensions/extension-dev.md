# VS Code 扩展开发规范

**适用范围**: 仅 extensions 子项目

本文件定义 VS Code 扩展的开发规范和标准。

---

## TypeScript 配置

### 统一配置

所有扩展使用以下 TypeScript 配置：

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "ES2020",
    "outDir": "out",
    "lib": ["ES2020"],
    "sourceMap": true,
    "rootDir": "src",
    "strict": true
  }
}
```

### 配置说明

- `module: "commonjs"` - VS Code 扩展使用 CommonJS 模块
- `target: "ES2020"` - 编译目标为 ES2020
- `strict: true` - 启用严格模式检查

---

## 扩展清单（package.json）

### 必须包含的字段

```json
{
  "name": "wtc-扩展名",
  "displayName": "WTC 扩展显示名",
  "description": "扩展描述",
  "version": "1.0.0",
  "engines": {
    "vscode": "^1.80.0"
  },
  "categories": ["Other"],
  "activationEvents": [...],
  "main": "./out/extension.js"
}
```

### 字段说明

| 字段 | 说明 | 示例 |
|------|------|------|
| `name` | 扩展名称（必须以 wtc- 开头） | `wtc-toolbars` |
| `displayName` | 显示名称 | `WTC Toolbars` |
| `description` | 扩展描述 | `提供快捷的工具栏按钮` |
| `version` | 版本号（遵循 semver） | `1.0.0` |
| `engines.vscode` | VS Code 最低版本 | `^1.80.0` |
| `categories` | 扩展分类 | `["Other"]` |
| `activationEvents` | 激活条件 | 见下一章节 |
| `main` | 入口文件 | `./out/extension.js` |

---

## 命名规范

### 扩展名称

- 必须以 `wtc-` 开头
- 使用小写字母和连字符
- 例如：`wtc-toolbars`, `wtc-docs-server`

### 符号链接名称

- 与扩展名称一致
- 配置在 `.vscode/settings.json` 的 `WTC.subProjects.extensions.plugins` 中

---

## 目录结构

```
wtc-扩展名/
├── package.json       # 扩展清单
├── src/
│   └── extension.ts   # 扩展入口
├── out/               # 编译输出
├── icons/             # 图标（可选）
├── scripts/           # 脚本（可选）
└── tsconfig.json      # TypeScript 配置
```

---

## 开发流程

### 1. 安装依赖

```bash
cd wtc-扩展名
npm install
```

### 2. 编译

```bash
npm run compile  # 单次编译
npm run watch    # 监听模式
```

### 3. 测试

按 `F5` 启动扩展开发主机

### 4. 重载

修改后重载 VS Code 窗口：
- macOS: `Cmd+Shift+P` > "Developer: Reload Window"
- Windows/Linux: `Ctrl+Shift+P` > "Developer: Reload Window"

---

## 打包发布

### 安装 vsce

```bash
npm install -g vsce
```

### 打包扩展

```bash
cd wtc-扩展名
vsce package
```

生成 `wtc-扩展名-x.x.x.vsix` 文件

---

## 相关文档

- [扩展激活条件规则](./activation)
- [符号链接管理](./symlink-management)

---

**最后更新**: 2025-10-13
**维护者**: WTC-Extensions Team
**参考资料**: [VS Code Extension API](https://code.visualstudio.com/api)
