---
# 第 15 章: 性能与成本优化

> **核心问题**：Agent 每次调用 LLM 都要花钱。怎么让 Agent 跑得快、花得少？

## 15.1 Token 优化的必要性

Token 是 Agent 成本的最大来源。每次 LLM 调用，你都在为 Prompt 中的每一个 Token 付费。

### 典型成本分析

一次 Agent 调用的 Token 构成：

```
系统 Prompt:       ~500 tokens（固定开销）
对话历史:         ~2000 tokens（随时间增长）
工具定义:         ~1000 tokens（取决于工具数量）
用户输入:          ~100 tokens
LLM 输出:         ~500 tokens
─────────────────────────────
单次 Agent 调用:  ~4100 tokens
```

如果 Agent 需要 5 轮循环完成一个任务，那就是 20,000+ tokens。

## 15.2 Token 优化策略

### 策略一：上下文裁剪

裁剪掉不必要的内容，保留核心信息：

```javascript
function trimContext(context, maxTokens = 4000) {
  // 1. 总是保留系统 Prompt
  const system = context.system;
  let remaining = maxTokens - estimateTokens(system);

  // 2. 保留最近的 N 轮对话
  const recent = [];
  for (let i = context.history.length - 1; i >= 0; i--) {
    const turn = context.history[i];
    const tokens = estimateTokens(turn.content);
    if (remaining - tokens > 0) {
      recent.unshift(turn);
      remaining -= tokens;
    } else {
      break;
    }
  }

  // 3. 如果还有空间，用摘要填充早期内容
  return {
    system,
    history: recent,
    summary: context.summary || null,
  };
}
```

### 策略二：摘要压缩

当对话历史太长时，用 LLM 将早期内容压缩为摘要：

```javascript
async function compressHistory(history, maxLength = 500) {
  const compressPrompt = `将以下对话压缩为 ${maxLength} tokens 以内的摘要，保留关键信息：`;
  const fullText = history.map(h => `${h.role}: ${h.content}`).join('\n');
  const summary = await callLLM(compressPrompt + '\n\n' + fullText);
  return summary;
}
```

### 策略三：缓存

重复的 LLM 调用可以直接返回缓存结果，避免重复计算：

| 缓存类型 | 命中场景 | 节省比例 |
|---------|---------|---------|
| **精确匹配** | 完全相同的输入 | 100% |
| **语义缓存** | 意图相同的不同表述 | 60-80% |
| **工具结果** | 外部 API 返回结果 | 30-50% |

```javascript
class SemanticCache {
  constructor() {
    this.cache = new Map();
  }

  async get(prompt) {
    // 将 prompt 向量化后搜索相似缓存
    const embedding = await embed(prompt);
    for (const [key, value] of this.cache) {
      if (cosineSimilarity(embedding, key.embedding) > 0.95) {
        return value; // 命中语义相似的缓存
      }
    }
    return null;
  }

  set(prompt, response) {
    // 缓存新结果
    this.cache.set({ prompt, embedding: null }, response);
  }
}
```

## 15.3 模型分层选型

不同任务用不同模型，而不是所有任务都用最强（最贵）的模型：

```
复杂推理（5% 请求）    → GPT-4 / Claude 3 Opus    ← 最贵
工具调用（15% 请求）   → GPT-4o-mini / Claude 3 Haiku
简单问答（50% 请求）   → GPT-3.5 / 本地小模型
规则匹配（30% 请求）   → 正则/关键词 → 不用 LLM   ← 最便宜
```

### 路由实现

```javascript
class ModelRouter {
  constructor() {
    this.models = {
      reasoning: { name: 'gpt-4', costPer1k: 0.03 },
      general: { name: 'gpt-4o-mini', costPer1k: 0.002 },
      simple: { name: 'gpt-3.5', costPer1k: 0.0005 },
    };
  }

  selectModel(task) {
    if (task.requiresReasoning) return this.models.reasoning;
    if (task.requiresToolUse) return this.models.general;
    if (task.isSimpleQuery) return this.models.simple;
    return this.models.general;
  }
}
```

## 15.4 延迟优化

### 常见瓶颈

| 瓶颈 | 典型耗时 | 优化方案 |
|------|---------|---------|
| LLM 推理 | 1-3s | 小模型 + 流式输出 |
| RAG 检索 | 200-500ms | 向量索引 + 缓存 |
| 工具调用 | 100ms-5s | 并行调用 + 超时控制 |
| 上下文构造 | 50-200ms | 预计算 + 增量更新 |

### 并行调用

当 Agent 需要调用多个独立工具时，并行执行：

```javascript
async function parallelToolCalls(tools) {
  // 识别独立工具（无依赖关系）并行执行
  const independent = tools.filter(t => !t.dependsOn);
  const results = await Promise.all(
    independent.map(t => callTool(t))
  );
  return results;
}
```

## 面试高频问法

**Q1: 怎么降低 Agent 的单次任务 Token 成本？**
三个方向：上下文裁剪（只保留必要的对话历史）、摘要压缩（用 LLM 压缩早期内容为简短摘要）、缓存（重复的 LLM 调用直接返回缓存结果）。模型分层也是关键——简单任务用小模型。

**Q2: 模型分层是什么？在什么场景下应该用大小模型搭配？**
按任务复杂度分配不同规模的模型。例如：复杂推理用 GPT-4、工具调用用 GPT-4o-mini、简单问答用 GPT-3.5、规则匹配直接用正则。典型场景是客服系统：高价值客户用强模型，普通客户用弱模型。

**Q3: Agent 的延迟瓶颈通常在哪里？怎么优化？**
LLM 推理是最大瓶颈（1-3s）。方案：简单任务用小模型、启用流式输出、缓存重复调用。RAG 检索（200-500ms）可通过向量索引和缓存加速。多工具调用可并行执行。