# Claude Code effort 推理能力配置

## 简介

`effort` 参数用于调节 Claude 在回答前分配多少 Token 进行内部扩展思考（推理能力/模型努力程度）。

## 可选值

| 值 | 说明 |
|---|---|
| `low` | 低推理预算 |
| `medium` | 中等推理预算 |
| `high` | 高推理预算（**默认值**） |
| `max` | 最大推理预算（算力消耗大，仅能临时开启，无法持久化） |
| `auto` | 自动调节 |

## 注意事项

- 不保证必定生效，仅作为设定影响模型的"自适应思考"和"元决策器"
- 受官方**"负载感知的动态配额"**机制影响：算力紧张时系统可能会动态调低单次请求的实际推理预算（例如乘以 0.3 系数）
- `Max` 由于算力消耗大，官方规定只能通过命令临时开启，**无法持久化配置**

## 任务场景推荐

搭配模型选择使用，参考 [Claude Code Opusplan 混合模型](./Claude%20Code%20Opusplan%20混合模型.md)。

## 调整方法

### 1. 命令行临时设置
```bash
/effort [low|medium|high|max|auto]
```

### 2. 交互式选择
```
/model + 键盘 ⬅️ ➡️ 选择
```

### 3. CLI 参数
```bash
claude --effort [low|medium|high|max|auto]
```

### 4. 配置文件（持久化）
编辑 `~/.claude/settings.json`：
```json
{
  "effortLevel": "high"
}
```

### 5. 环境变量
```bash
export CLAUDE_CODE_EFFORT_LEVEL=high
```
