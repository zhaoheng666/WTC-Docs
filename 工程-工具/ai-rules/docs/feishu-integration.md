# 飞书集成规范

**适用范围**: docs 子项目文档生成

从飞书文档读取原始信息，加工后自动生成标准 Markdown 文档并提交到 docs 项目。

**完整工作流程和规则**：请参考 `.claude/skills/feishu-to-docs/SKILL.md`

---

## lark-mcp 工具使用

### 前置条件

确保已正确配置 lark-mcp：

```bash
# 检查配置
claude mcp list | grep lark-mcp

# 如未配置，参考之前的配置步骤
# ~/.claude.json 中应包含 lark-mcp 配置，包含 App ID 和 Secret
```

### 工具调用

#### 1. 获取飞书 Wiki 节点信息

```javascript
mcp__lark-mcp__wiki_v2_space_getNode({
  params: {
    token: "FjqOwGH72izxYHkbgKgcUSEbnZb",  // Wiki Token
    obj_type: "wiki"
  },
  useUAT: true  // 可选，调试模式
})
```

**参数说明**：
- `token`: 从飞书链接提取，例如 `https://ghoststudio.feishu.cn/wiki/FjqOwGH72izxYHkbgKgcUSEbnZb` → token: `FjqOwGH72izxYHkbgKgcUSEbnZb`
- `obj_type`: 固定为 `wiki`

**返回信息**：
- `title`: 文档标题
- `children`: 子页面列表
- `document_id`: 文档 ID（用于读取内容）

---

#### 2. 读取文档原始内容

```javascript
mcp__lark-mcp__docx_v1_document_rawContent({
  path: {
    document_id: "XP5Md7Xa9ooFJRx4vALcnmHxn1b"  // 从 getNode 获得
  },
  params: {
    lang: 0  // 0=默认语言, 1=英文, 2=日文
  },
  useUAT: true  // 可选
})
```

**参数说明**：
- `document_id`: Wiki 节点的文档 ID
- `lang`: 语言参数

**返回信息**：
- `content`: 文档的 XML 格式内容
- 需要解析提取有用信息

---

#### 3. URL 转换

飞书文档的两种常见链接格式：

| 格式 | 示例 | 说明 |
|-----|------|------|
| 完整链接 | `https://ghoststudio.feishu.cn/wiki/FjqOwGH72izxYHkbgKgcUSEbnZb` | 可直接提取 token |
| 短链接 | `https://ghoststudio.feishu.cn/wiki/FjqOwGH72izxYHkbgKgcUSEbnZb?from=from_copylink` | 去除查询参数后提取 token |

**提取方法**：

```javascript
// 正则匹配提取 Wiki Token
const wikiTokenMatch = url.match(/\/wiki\/([a-zA-Z0-9]+)/);
const wikiToken = wikiTokenMatch ? wikiTokenMatch[1] : null;
```

---

## 错误处理

### 权限错误

**症状**：
```
Access denied. One of the following scopes is required:
[wiki:wiki, wiki:wiki:readonly, wiki:node:read]
```

**解决**：
1. 检查 lark-mcp 配置的 App ID 和 Secret
2. 在飞书开发者后台申请权限
3. 权限包括：`wiki:wiki:readonly`, `docx:document:readonly`

**参考**：用户首次配置 lark-mcp 时已经历过，详见历史记录

---

### 链接无效

**症状**：
```
Wiki token not found or document deleted
```

**处理**：
1. 确认链接格式正确
2. 检查文档未被删除
3. 提示用户重新提供有效链接

---

### 类型识别失败

**症状**：自动识别无法确定文档类型

**处理**：
```
自动识别失败，请选择文档类型：

1️⃣ 故障排查 - 问题修复相关
2️⃣ 活动 - 活动设计相关
3️⃣ 关卡 - 关卡配置相关
4️⃣ 其他 - 其他类型文档

请选择 (1-4):
```

---

### 文件重名

**症状**：目标文件已存在

**处理**：
```
文件已存在: docs/故障排查/Coupon关卡-活动入口异常显示问题.md

选择处理方式：
1️⃣ 覆盖现有文件
2️⃣ 重命名为: xxx-v2.md
3️⃣ 取消操作
```

---

## 常见问题

### Q1：如何从群聊链接提取飞书文档？

**A**: 飞书群聊消息中可能包含文档链接。提取方式：

1. 从消息中识别 Wiki 链接（`https://ghoststudio.feishu.cn/wiki/xxxx`）
2. 或查看消息中"文档"、"链接"等引用
3. 直接提供给 Skill

示例：
```
在群聊消息中看到：
"问题详情见: https://ghoststudio.feishu.cn/wiki/FjqOwGH72izxYHkbgKgcUSEbnZb"

→ 直接提供链接：
/feishu-to-docs https://ghoststudio.feishu.cn/wiki/FjqOwGH72izxYHkbgKgcUSEbnZb
```

---

### Q2：飞书文档包含截图/视频，如何处理？

**A**: 当前策略：保留飞书原文档链接

- 不下载或转换媒体文件（复杂且易出错）
- 生成 Markdown 文档链接指向原飞书
- 用户需要完整信息时访问飞书原文档查看截图/视频

优点：
- 简化流程，降低出错风险
- 保持信息更新（飞书文档修改自动反映）
- 便于版本管理（原文档永久存档）

---

### Q3：同一文档可能属于多个类型，如何识别？

**A**: 按优先级判断

```
故障排查 > 活动 > 关卡 > 其他
```

即：如果既包含问题又包含活动信息，优先识别为故障排查。

如确实混合型文档，建议手动选择主要类型。

---

### Q4：生成文档后如何修改或删除？

**A**: 文档生成后的修改流程：

1. **修改内容**：
   - 直接编辑 Markdown 文件
   - 更新后 `git add` 和 `git commit`
   - 提交信息示例：`docs: 更新 - [文档名]`

2. **删除文档**：
   - 直接删除文件
   - 提交信息示例：`docs: 删除 - [文档名]`

---

### Q5：如何处理没有权限的飞书文档？

**A**:

1. **群聊分享文档**：
   - 检查是否有权限访问
   - 权限缺失时，提示用户申请
   - 或让文档所有者分享权限

2. **个人文档**：
   - 向文档所有者请求权限
   - 或提供文档内容截图（手动处理）

---

## 参考资源

- **Skill 完整规范**: `.claude/skills/feishu-to-docs/SKILL.md`
- **VitePress 规范**: `docs/工程-工具/ai-rules/docs/vitepress.md`
- **文档分类规范**: `CLAUDE.md > 文档记录原则`
- **Git 提交规范**: `.claude/skills/git-commit/SKILL.md`
- **lark-mcp 文档**: https://github.com/larksuiteoapi/lark-mcp

---

**最后更新**: 2025-10-31
**维护者**: WorldTourCasino Team
