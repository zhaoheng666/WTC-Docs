# 主项目 Git 提交规则

**适用范围**: 仅 WorldTourCasino 主项目

本文件定义主项目**特有的** Git 提交规则。通用规则请参考：
- **提交类型**: `docs/工程-工具/ai-rules/shared/git-commit-types.md`
- **执行流程**: `.claude/skills/git-commit/SKILL.md`

---

## 忽略构建产物

提交时必须忽略 `./build_local_app.sh` 产生的文件。

### 需忽略的文件模式

- `res_*/flavor/index.html`
- `res_*/flavor/main*.css`
- `res_*/flavor/project.json`
- `res_*/flavor/js_src/common/util/Config.js`
- `res_*/resource_list/**/*.json`
- `res_*/resource_dirs.json`

### 原则

**只提交源码修改，不提交构建结果**

---

## 主项目提交格式

```
cv: [类型] 描述
cv: 关卡X 描述
```

**示例**：
- `cv: fix 修复加载错误`
- `cv: feat 添加新功能`
- `cv: 关卡100 优化卡片收集`
- `cv: chore 更新构建脚本`

---

## 子项目提交顺序

当"全部提交"时，顺序为：

1. docs 子项目
2. extensions 子项目
3. 主项目

---

**最后更新**: 2025-01-19
**维护者**: WorldTourCasino Team
