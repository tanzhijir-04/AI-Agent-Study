---
# 第 24 章: 手写代码题备战

> **核心目标**：掌握 Agent 面试中常考的手写代码题。

## 高频手写题清单

### 1. 手写 ReAct 循环

```javascript
async function reactLoop(task, tools, maxRounds = 10) {
  let context = { task, history: [] };

  for (let round = 0; round < maxRounds; round++) {
    // Think
    const thought = await callLLM(buildPrompt(context));

    // 检查是否完成
    if (thought.isDone) return thought.result;

    // Act
    const action = parseAction(thought);
    const result = await tools[action.tool](action.args);

    // Observe
    context.history.push({ thought, action, result });
  }

  return { error: 'Max rounds reached' };
}
```

### 2. 手写 Memory 系统

```javascript
class Memory {
  constructor(maxSize = 10) {
    this.shortTerm = []; // FIFO 队列
    this.maxSize = maxSize;
  }

  add(item) {
    this.shortTerm.push(item);
    if (this.shortTerm.length > this.maxSize) {
      this.shortTerm.shift(); // 移除最旧的
    }
  }

  search(query) {
    // 关键词匹配
    return this.shortTerm.filter(item =>
      item.content.includes(query)
    );
  }
}
```

### 3. 手写工具调用解析

```javascript
function parseToolCall(text) {
  // 解析格式：<tool_name>参数1=值1, 参数2=值2</tool_name>
  const regex = /<(\w+)>([^<]+)<\/\1>/;
  const match = text.match(regex);
  if (!match) return null;

  const [_, tool, argsStr] = match;
  const args = {};
  argsStr.split(',').forEach(pair => {
    const [k, v] = pair.trim().split('=');
    args[k.trim()] = v.trim();
  });

  return { tool, args };
}
```

### 4. 手写限流器

```javascript
class RateLimiter {
  constructor(maxRequests, windowMs) {
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
    this.requests = [];
  }

  allow() {
    const now = Date.now();
    this.requests = this.requests.filter(t => now - t < this.windowMs);
    if (this.requests.length >= this.maxRequests) return false;
    this.requests.push(now);
    return true;
  }
}
```

### 5. 手写简单的 RAG

```javascript
async function simpleRAG(query, documents, llm) {
  // 1. 检索相关文档
  const relevant = documents
    .map(doc => ({ doc, score: similarity(query, doc.text) }))
    .sort((a, b) => b.score - a.score)
    .slice(0, 3);

  // 2. 构建增强 Prompt
  const context = relevant.map(r => r.doc.text).join('\n---\n');
  const prompt = `基于以下上下文回答问题：\n\n${context}\n\n问题：${query}`;

  // 3. 生成回答
  return llm.generate(prompt);
}
```

## 考试技巧

1. **先画框架**：先写出函数签名和大致结构，再填充细节
2. **写注释**：关键逻辑加上注释，展示思路
3. **边界处理**：主动提出来"这里需要处理空值/超时/异常"
4. **考虑扩展**：写完后说"如果未来需要 XXX，这里可以改为可配置的"
5. **测试意识**：提一句"我会给这个函数写单元测试，覆盖 XX 场景"