---
# 第 16 章: 生产环境部署

> **核心问题**：模型写好了，代码跑通了，怎么把 Agent 变成真正可用的服务？

## 16.1 Agent 服务化

将 Agent 封装为 API 服务，让其他系统可以调用。

### 架构概览

```
客户端 → API Gateway → Agent Service → LLM Provider
                            ↓
                       Context Store (Redis)
                            ↓
                       Memory Store (Vector DB)
```

### 基础 API 设计

```javascript
const express = require('express');
const app = express();
app.use(express.json());

// Agent 执行端点
app.post('/api/agent/execute', async (req, res) => {
  const { sessionId, message } = req.body;

  // 加载上下文
  const context = await loadContext(sessionId);

  // 执行 Agent
  const result = await agent.process(message, context);

  // 保存上下文
  await saveContext(sessionId, result.updatedContext);

  res.json({
    reply: result.output,
    sessionId,
    rounds: result.rounds,
  });
});

// 流式输出端点
app.post('/api/agent/stream', async (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');

  const stream = await agent.stream(req.body.message);
  for await (const chunk of stream) {
    res.write(`data: ${JSON.stringify(chunk)}\n\n`);
  }
  res.write('data: [DONE]\n\n');
  res.end();
});

app.listen(3000);
```

## 16.2 流式输出

Agent 的流式输出比普通 LLM 流式更复杂，因为涉及多轮工具调用。

### 流式事件的类型

```
event: think      data: {"text": "我需要先搜索..."}
event: tool_call  data: {"tool": "search", "args": {"q": "天气"}}
event: tool_result data: {"result": "今天晴，25度"}
event: think      data: {"text": "根据搜索结果..."}
event: text       data: {"text": "今天天气晴朗，25度。"}
event: done       data: {}
```

### SSE 实现

```javascript
async function* agentStream(message) {
  // Step 1: Think
  yield { type: 'think', content: '让我来查询天气...' };

  // Step 2: Tool Call
  yield { type: 'tool_call', tool: 'search', args: { q: '今天天气' } };
  const result = await callTool('search', { q: '今天天气' });
  yield { type: 'tool_result', tool: 'search', result };

  // Step 3: Generate Output
  const output = await generateResponse(message, result);
  yield { type: 'text', content: output };

  yield { type: 'done' };
}
```

## 16.3 高可用与限流

### 三种限流策略

| 策略 | 原理 | 适用场景 |
|------|------|---------|
| **Token 桶** | 每秒固定令牌数，桶满即弃 | 通用 API 限流 |
| **滑动窗口** | 统计时间窗口内的请求数 | 用户级别限流 |
| **并发控制** | 限制同时进行的 Agent 会话数 | GPU 资源受限场景 |

```javascript
class RateLimiter {
  constructor(maxRpm = 60) {
    this.requests = new Map(); // userId -> [timestamp]
    this.maxRpm = maxRpm;
  }

  allow(userId) {
    const now = Date.now();
    const userReq = this.requests.get(userId) || [];
    // 移除 1 分钟前的记录
    const recent = userReq.filter(t => now - t < 60000);
    if (recent.length >= this.maxRpm) {
      return false; // 限流
    }
    recent.push(now);
    this.requests.set(userId, recent);
    return true;
  }
}
```

## 16.4 多租户隔离

生产系统中通常有多个用户/团队共享同一个 Agent 服务。需要做好隔离：

1. **上下文隔离**：每个租户独立的 Redis namespace（`tenant:{id}:session:*`）
2. **数据隔离**：租户的文档、知识库互不可见
3. **速率隔离**：每个租户独立的限流配额
4. **成本核算**：按租户统计 Token 消耗

## 16.5 CI/CD 与模型迭代

Agent 的 CI/CD 比传统应用多一层：模型行为验证。

```yaml
# .github/workflows/agent-ci.yml
steps:
  - run: npm test                    # 单元测试
  - run: npm run test:agent          # Agent 端到端测试
  - run: npm run eval:baseline       # 与基线对比
  - run: npm run eval:hallucination  # 幻觉检测
```

### 模型升级流程

```
1. 在新模型上跑回归测试套件
2. 对比基线指标（完成率、准确率、耗时）
3. 如果指标下降，需要调优 Prompt 或回滚
4. 使用 Feature Flag 灰度发布新模型（10% → 50% → 100%）
```

## 面试高频问法

**Q1: Agent 服务化有哪些关键考虑？**
三个核心：API 封装（REST API + 流式输出）、状态管理（上下文持久化到 Redis）、可靠性（限流 + 降级 + 超时控制）。多租户场景还需要做好隔离。

**Q2: 流式输出在 Agent 场景下怎么实现？**
Agent 的流式比普通 LLM 流式复杂，因为涉及多轮工具调用。需要定义不同类型的事件（think/tool_call/tool_result/text/done），用 SSE 实时推送。客户端根据事件类型更新 UI。

**Q3: 多租户场景下 Agent 上下文怎么隔离？**
四个维度：上下文隔离（Redis namespace 分区）、数据隔离（知识库互不可见）、速率隔离（独立限流配额）、成本核算（按租户统计 Token）。实践中常用"一户一实例"或"共享实例 + 隔离存储"。