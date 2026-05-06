# 如何获取 fbId

## 适用场景

在 Facebook 网页端（Canvas / Messenger 等）排查玩家问题、对接客服或测试时，需要拿到当前账号的 fbId。

## 1、打开浏览器开发者工具，切到「元素」页签

在搜索框里输入 `fbid`，浏览器会高亮一段 `<script type="application/json">` 内的 JSON 文本。

![step1](/assets/170faa63e09732cf46dab1b0bb04fef0.png)

## 2、在高亮区域上右键 → 复制 → 复制元素

> 直接看高亮区域里的 fbId 也可以，但 JSON 通常被压成一行，肉眼很难定位，推荐复制下来再查找。

## 3、把复制的内容粘贴到任意文本编辑器（VS Code / 文本编辑 等），搜索 `"fbId"`

引号后边的数字串就是当前账号的 fbId。

![step2](/assets/c09780647cd299b7085eaf6e8f6c9169.png)

## 常见问题

- **搜不到 `fbid`**：确认当前页面是已登录的 Facebook 域名（如 `apps.facebook.com`、`www.facebook.com`），未登录态没有这个字段。
- **复制元素粘贴后是 HTML 而不是 JSON**：右键时务必点中带 `application/json` 的 `<script>` 节点本身，而不是它的父节点。
