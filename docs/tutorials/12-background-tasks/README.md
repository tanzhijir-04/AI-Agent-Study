---

# 第 12 章: 后台任务与异步执行

> **核心问题**：Agent 在处理耗时操作（如文件处理、网络请求、批量推理）时，如何不阻塞主执行循环？

## 12.1 为什么 Agent 需要后台任务

Agent 的核心执行循环是"思考→行动→观察"的同步迭代。但现实中有大量操作**不能**同步完成：

- **LLM 调用**：大模型推理耗时数百毫秒到数秒
- **文件处理**：上传/下载大文件、视频转码
- **批量 RAG 检索**：多路知识库搜索
- **外部 API 调用**：慢响应、超时、限流
- **Agent 协作**：等待子 Agent 完成任务

如果所有操作都同步阻塞，会带来两个后果：
1. Agent 在等待期间**完全无法响应用户**（糟糕的体验）
2. **资源利用率低**：CPU/GPU 等待 I/O 时被闲置

后台任务的核心模式就是：**将耗时操作放入队列，主循环继续执行，完成后回调通知**。

![配图：同步阻塞 vs 异步非阻塞 - 长任务交给队列](/assets/12-background-01-sync-vs-async.png)

## 12.2 消息队列模式

消息队列（Message Queue）是后台任务架构的基石。它在 Agent 内部充当"邮局"的角色——发送方不需要等待接收方处理完毕。

### 核心概念

| 概念 | 说明 |
|------|------|
| **队列** | 按 FIFO 顺序存储消息的缓冲区 |
| **生产者** | 产生消息的一方（通常是 Agent 主循环） |
| **消费者** | 处理消息的一方（后台 Worker 线程） |
| **主题** | 消息的分类标签，用于广播和订阅 |
| **确认** | 消费者处理完成后通知队列删除消息 |

### 代码实现

项目中的 `message_queue.js` 实现了基础的队列系统：

```javascript
// 创建消息队列
const queue = new MessageQueue();

// Agent A 给 Agent B 发消息（不等待）
queue.send({ from: 'A', content: '处理这份文件' }, 'AgentB');

// 主题广播：所有订阅者都能收到
queue.broadcast({ type: 'new_file', path: '/tmp/doc.pdf' }, 'file_events');
```

关键设计要点：

- **异步发送**：`send()` 将消息放入目标队列后立即返回，不阻塞调用方
- **消息 ID + 时间戳**：每条消息有唯一 ID 和毫秒级时间戳，方便追踪
- **历史记录**：保留最近 N 条消息用于调试和重放
- **通知机制**：`notifySubscriber()` 在消息入队时触发回调

## 12.3 任务调度与优先级

消息队列解决的是"传递"问题，而任务调度器解决的是"执行顺序"问题。

### 调度策略

项目中的 `task_scheduler.js` 支持三种策略：

| 策略 | 适用场景 | 核心逻辑 |
|------|---------|---------|
| **FIFO** | 简单顺序任务 | 先入先出，按到达时间依次执行 |
| **优先级** | 紧急任务插队 | 高优先级任务跳到队列前面 |
| **依赖关系** | 有前置条件的任务 | 前置任务完成后才调度后续任务 |

```javascript
const scheduler = new TaskScheduler();

// 添加有依赖关系的任务
scheduler.addTask({ id: 'download', name: '下载文件' });
scheduler.addTask({ id: 'parse', name: '解析文件', dependencies: ['download'] });
scheduler.addTask({ id: 'analyze', name: '分析数据', dependencies: ['parse'] });

// 当 download 完成时，自动触发 schedule() 检查哪些任务可以执行
scheduler.updateTaskStatus('download', 'completed');
```

依赖调度的工作流：

```
download (completed) → parse (ready) → analyze (ready)
                              ↓
                      dispatch to Agent
```

### 超时处理

后台任务最危险的问题就是死等。需要在两个层面设防：

```javascript
// 方案一：任务级别超时
const task = {
  id: 'process-file',
  timeout: 30000, // 30 秒超时
  createdAt: Date.now()
};

// 在调度循环中检查
if (Date.now() - task.createdAt > task.timeout) {
  task.status = 'timed_out';
  // 触发降级处理
}

// 方案二：全局心跳检测
setInterval(() => {
  scheduler.tasks.forEach(task => {
    if (task.status === 'in_progress' && 
        Date.now() - task.startedAt > MAX_TASK_DURATION) {
      handleTimeout(task);
    }
  });
}, 5000); // 每 5 秒检测一次
```

## 12.4 断点续传与恢复

Agent 在运行过程中可能崩溃或重启。如果不做持久化，所有未完成的任务都会丢失。

### 任务状态持久化

```javascript
// 保存任务状态到 JSON
function persistTasks(scheduler, filePath = 'tasks_backup.json') {
  const snapshot = [];
  scheduler.tasks.forEach((task, id) => {
    snapshot.push({
      id,
      status: task.status,
      progress: task.progress || 0,
      data: task.savedState
    });
  });
  fs.writeFileSync(filePath, JSON.stringify(snapshot, null, 2));
}

// 恢复时重新加载
function restoreTasks(scheduler, filePath = 'tasks_backup.json') {
  const snapshot = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  snapshot.forEach(item => {
    scheduler.addTask({ id: item.id, savedState: item.data });
    scheduler.updateTaskStatus(item.id, item.status);
  });
}
```

对于特别长的任务（如数据分析流水线），每个阶段完成后保存一个检查点，下次从中断处继续。

## 12.5 后台任务架构全景

组合消息队列和任务调度器，可以构造完整的异步架构：

```
Agent 主循环
   │
   ├── 同步操作 → 立即返回结果
   │
   └── 耗时操作 → 放入 MessageQueue
                       │
                       ▼
                 TaskScheduler 判断
                  ├── 无前置依赖 → 立即派发给 Worker Agent
                  └── 有前置依赖 → 等待依赖完成
                       │
                       ▼
                 Worker Agent 异步执行
                       │
                       ▼
                 完成后回调主循环 → 通知用户
```

## 面试高频问法

**Q1: Agent 的长任务怎么在不阻塞主流程的情况下执行？**

核心思路是"异步解耦"：将耗时操作封装为任务放入消息队列，主循环继续处理新的请求，后台 Worker 消费队列，完成后通过回调或事件通知主循环。具体实现涉及 MessageQueue 的任务分发和 TaskScheduler 的依赖管理。

**Q2: 后台任务的超时中断怎么设计？**

两层级联：任务级超时（创建时指定 deadline）+ 全局心跳检测（定时扫描所有进行中的任务）。超时触发回调执行降级逻辑（返回部分结果、重试、或通知用户）。对长时间运行的任务还应支持断点续传，通过定期持久化任务状态来实现。
