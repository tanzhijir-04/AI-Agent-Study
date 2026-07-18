---
# 第 14 章: 可观测性、故障排查与降级兜底

> **核心问题**：Agent 在生产环境中出了问题，你怎么知道？怎么定位？怎么恢复？

## 14.1 为什么 Agent 需要可观测性

传统应用的监控（CPU、内存、错误率）在 Agent 场景下远远不够。Agent 的问题往往是"语义级别"的：

- Agent 陷入了死循环，但进程还在运行（CPU 正常）
- Agent 调用了错误的工具，但 API 返回 200
- Agent 产生了幻觉，但输出格式完全正确
- Agent 上下文溢出了，但没有报错，只是开始"失忆"

可观测性要回答三个问题：

1. **发生了什么？**（Tracing：记录每一步）
2. **为什么发生？**（日志：完整上下文）
3. **怎么修复？**（降级策略：故障恢复）

## 14.2 Tracing：全链路追踪

Tracing 记录 Agent 的每一次思考、每一个行动、每一轮观察。这是排查 Agent 问题最核心的手段。

### 关键追踪点

| 追踪点 | 记录内容 | 作用 |
|-------|---------|------|
| **Think** | 推理的完整 Prompt + 输出 | 检查 Agent 的推理质量 |
| **Tool Call** | 工具名称 + 参数 + 返回结果 | 检查工具调用是否正确 |
| **Memory Access** | 读取/写入的记忆内容 | 检查记忆是否被正确维护 |
| **Plan Steps** | 计划中的每一步状态 | 检查计划执行进度 |
| **Round Trip** | 单次循环的耗时 | 定位性能瓶颈 |

### 实现示例

```javascript
class Tracer {
  constructor() {
    this.events = [];
  }

  trace(type, data) {
    this.events.push({
      type, timestamp: Date.now(), round: this.currentRound, data
    });
  }

  getTimeline() {
    return this.events.map(e =>
      `[R${e.round}] ${e.type}: ${JSON.stringify(e.data).slice(0, 200)}`
    ).join('\n');
  }

  findLoop() {
    // 检测最近 N 轮是否重复相同工具调用
    const recentTools = this.events
      .filter(e => e.type === 'tool_call')
      .slice(-10)
      .map(e => e.data.tool);
    return hasRepeatingPattern(recentTools);
  }
}
```

## 14.3 常见故障排查

### 故障一：死循环

Agent 卡在"思考→行动→观察"的循环里出不来。

**检测手段**：
- 轮次上限：超过 N 轮强制终止
- 重复检测：连续 3+ 轮调用相同工具/产生相同输出
- 时间超时：单次任务超过 M 秒自动中断

**解决方案**：
- 引入 Plan Mode：先规划再执行，减少盲目行动
- 改进 Prompt：给 Agent 明确的"终止条件"
- 降级策略：循环超过阈值后改为简单模式

### 故障二：上下文溢出

Agent 的上下文窗口满了，最早的信息被丢弃，导致"失忆"。

**检测手段**：
- Token 计数：每次 LLM 调用前检查 token 使用量
- 上下文利用率：当前 token / 最大 token 的比值

**解决方案**：
- 滑动窗口：保留最近的 N 轮对话，丢弃最早的内容
- 摘要压缩：将部分历史用 LLM 压缩为摘要
- Memory 系统：关键信息存入外部记忆，不占用上下文

### 故障三：工具调用失败

**检测手段**：
- HTTP 状态码检查
- 超时监控
- 返回格式校验（LLM 可能生成错误的 JSON）

**解决方案**：
- 重试机制：指数退避重试
- 格式校验：在解析 JSON 时做严格校验
- 降级替代：如果主要工具不可用，尝试备用工具

## 14.4 分级降级策略

降级应该分级执行，尽可能提供服务：

```
L1: 工具降级
   主要工具失败 → 备用工具 → 降级回复

L2: 模型降级
   GPT-4 超时 → GPT-3.5 → 简单规则回复

L3: 功能降级
   完整模式 → 只读模式 → 提示"暂时无法处理"

L4: 人工兜底
   以上全部失败 → 转接人工客服
```

### 降级示例

```javascript
async function executeWithDegradation(task) {
  const strategies = [
    { model: 'gpt-4', tools: ['search', 'calc'], timeout: 30000 },
    { model: 'gpt-3.5', tools: ['search'], timeout: 15000 },
    { model: 'gpt-3.5', tools: [], timeout: 10000 },
    { fallback: true, message: '暂时无法处理，请稍后再试' },
  ];

  for (const level of strategies) {
    try {
      return await executeAtLevel(task, level);
    } catch (err) {
      console.warn(`Level failed: ${err.message}`);
      continue;
    }
  }
  return { status: 'degraded', message: '所有策略均已失败，转人工' };
}
```

## 面试高频问法

**Q1: Agent 陷入死循环怎么处理？有哪些检测手段？**
三种检测：轮次上限（超过 N 轮终止）、重复检测（连续 3+ 轮调用相同工具）、时间超时（超过 M 秒中断）。对应策略：改进 Prompt 明确终止条件、Plan Mode 先规划后执行、超过阈值降级为简单模式。

**Q2: 上下文溢出有哪些解决方案？**
滑动窗口（末尾淘汰）、摘要压缩（LLM 压缩历史）、Memory 系统（关键信息外存）。实际生产中是三种组合使用。

**Q3: 说说 Agent 的降级策略有哪些层级？**
四级：L1 工具降级（主→备→降级回复）、L2 模型降级（强→弱→规则）、L3 功能降级（完整→只读→提示）、L4 人工兜底。核心原则是"尽可能提供服务，而不是直接报错"。