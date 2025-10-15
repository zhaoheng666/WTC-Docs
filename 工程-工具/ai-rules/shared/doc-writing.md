# 文档编写规范

**适用范围**: 所有项目和子项目（主项目、docs、extensions 等）

## Markdown 通用规范

### 标题层级

- 使用 `#` 到 `######` 表示 H1 到 H6
- 标题前后保留空行
- 避免跳级使用标题（如 H1 直接到 H3）

### 代码块

使用三个反引号包裹代码，并指定语言：

````markdown
```javascript
const hello = 'world';
```
````

### 链接和图片

- 链接: `[文字](./URL)`
- 图片: `![描述](./图片URL)`
- 相对路径: 使用相对路径引用项目内文件

## VitePress 特定规范

### 代码块语言标识符

VitePress 使用 [Shiki](https://shiki.style/) 作为语法高亮引擎，支持 **218 种语言**。

#### 基本规则

- ✅ 使用 Shiki 支持的语言标识符
- ❌ 不支持的语言使用 `text`（纯文本，无高亮）
- ⚠️ 如果看到 "The language 'xxx' is not loaded, falling back to 'bash'" 警告，说明语言不支持，应改为 `text`

#### 常用支持的语言

| 分类 | 支持的语言 |
|------|-----------|
| **Shell** | `bash`, `sh`, `shell`, `zsh`, `powershell`, `fish` |
| **Web** | `html`, `css`, `javascript`/`js`, `typescript`/`ts`, `jsx`, `tsx`, `vue`, `svelte` |
| **数据格式** | `json`, `yaml`/`yml`, `xml`, `toml`, `csv`, `ini` |
| **配置文件** | `dockerfile`, `nginx`, `apache`, `makefile`, `cmake` |
| **编程语言** | `python`/`py`, `java`, `c`, `cpp`, `go`, `rust`, `ruby`, `php`, `swift`, `kotlin` |
| **数据库** | `sql`, `plsql`, `graphql` |
| **文档** | `markdown`/`md`, `mdx`, `latex` |

#### 不支持的常见格式

使用 `text` 代替：

- ❌ `gitignore` - Git 忽略文件
- ❌ `env` - 环境变量文件
- ❌ `just` / `justfile` - Justfile 脚本
- ❌ `editorconfig` - 编辑器配置

#### 示例

```text
# ❌ 错误写法
```gitignore
.vscode/.env-verified
```

# ✅ 正确写法
```text
.vscode/.env-verified
```
```

**完整语言列表**: https://shiki.style/languages

### 容器（Containers）

VitePress 支持自定义容器：

```markdown
::: tip 提示
这是一条提示信息
:::

::: warning 警告
这是一条警告信息
:::

::: danger 危险
这是一条危险警告
:::
```

### 表格

```markdown
| 列1 | 列2 | 列3 |
|-----|-----|-----|
| 内容1 | 内容2 | 内容3 |
```

---

**最后更新**: 2025-10-13
**维护者**: WorldTourCasino Team
**参考资料**: [VitePress 文档](https://vitepress.qzxdp.cn/)
