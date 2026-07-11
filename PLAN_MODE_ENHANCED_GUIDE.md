# 📚 Plan Mode 增强版 - 代码原理详解

> 通过实现计划修改功能，学习 Plan Mode 的核心原理

## 🎯 学习目标

通过这个增强版实现，你将学会：

1. **用户交互设计模式** - 如何设计友好的用户交互
2. **异步编程** - 如何使用 async/await 处理用户输入
3. **数据结构修改** - 如何动态修改计划数据
4. **错误处理** - 如何处理用户输入错误
5. **状态管理** - 如何跟踪计划和步骤的状态

## 📁 文件结构

```
minimal_agent/
├── plan_mode_enhanced.js    # 增强版 Plan Mode（新增）
├── plan_mode.js             # 原版 Plan Mode
├── agent.js                 # 主程序
└── ...
```

## 🔍 核心代码解析

### 1. 用户交互设计

#### 原理：使用 readline 处理用户输入

```javascript
const readline = require('readline');

// 创建 readline 接口
this.rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// 封装为 Promise，使其可以 await
askQuestion(question) {
    return new Promise((resolve) => {
        this.rl.question(question, (answer) => {
            resolve(answer.trim());
        });
    });
}
```

**为什么这样设计？**
- `readline` 是 Node.js 内置模块，用于读取用户输入
- 将回调函数封装为 Promise，可以使用 `await` 语法
- 这样代码更清晰，易于理解

#### 实际使用：

```javascript
// 获取用户输入
const stepIndex = await this.askQuestion('要修改哪个步骤？');

// 验证输入
const index = parseInt(stepIndex) - 1;
if (isNaN(index) || index < 0 || index >= plan.steps.length) {
    console.log('❌ 无效的步骤编号');
    return this.modifyPlan(plan); // 递归调用，重新获取输入
}
```

### 2. 计划修改流程

#### 原理：递归 + 状态更新

```javascript
async modifyPlan(plan) {
    // 1. 显示当前步骤
    console.log('当前步骤：');
    plan.steps.forEach((step, index) => {
        console.log(`  ${index + 1}. ${step.action}`);
    });
    
    // 2. 获取用户选择
    const stepIndex = await this.askQuestion('要修改哪个步骤？');
    
    // 3. 检查是否完成
    if (stepIndex.toLowerCase() === 'done') {
        return plan;
    }
    
    // 4. 验证输入
    const index = parseInt(stepIndex) - 1;
    if (isNaN(index) || index < 0 || index >= plan.steps.length) {
        console.log('❌ 无效的步骤编号');
        return this.modifyPlan(plan); // 递归调用
    }
    
    // 5. 获取新的描述
    const step = plan.steps[index];
    const newAction = await this.askQuestion('输入新的描述: ');
    
    // 6. 更新步骤
    if (newAction) {
        step.action = newAction;
    }
    
    // 7. 重新显示计划
    this.displayPlan(plan);
    
    // 8. 询问是否继续修改
    const continueModifying = await this.askQuestion('继续修改其他步骤？(y/n): ');
    if (continueModifying.toLowerCase() === 'y') {
        return this.modifyPlan(plan); // 递归调用
    }
    
    return plan;
}
```

**关键点：**
- **递归调用**：如果用户输入无效或想继续修改，递归调用自身
- **状态更新**：直接修改 `plan.steps[index].action`
- **流程控制**：通过用户输入决定是继续修改还是退出

### 3. 进度显示

#### 原理：计算百分比，绘制进度条

```javascript
displayProgress(currentStep, totalSteps, stepAction) {
    // 计算进度百分比
    const progress = Math.round((currentStep / totalSteps) * 100);
    
    // 绘制进度条
    const progressBarLength = 20;
    const filledLength = Math.round((progress / 100) * progressBarLength);
    const progressBar = '█'.repeat(filledLength) + '░'.repeat(progressBarLength - filledLength);
    
    // 显示进度
    console.log(`执行进度: ${progressBar} ${progress}%`);
    console.log(`当前步骤: ${currentStep}/${totalSteps} - ${stepAction}`);
}
```

**示例输出：**
```
执行进度: ████████████░░░░░░░░ 60%
当前步骤: 3/5 - 设计重构方案
```

### 4. 执行时间统计

#### 原理：记录开始和结束时间，计算差值

```javascript
async executePlan(plan) {
    // 记录开始时间
    const startTime = Date.now();
    
    // 执行所有步骤
    for (let i = 0; i < plan.steps.length; i++) {
        // ... 执行步骤 ...
    }
    
    // 计算总耗时
    const endTime = Date.now();
    const totalTime = ((endTime - startTime) / 1000).toFixed(1);
    
    console.log(`⏱️ 总耗时: ${totalTime}秒`);
}
```

**关键点：**
- `Date.now()` 返回当前时间戳（毫秒）
- 计算差值并转换为秒
- 使用 `toFixed(1)` 保留一位小数

### 5. 错误处理

#### 原理：try-catch + 用户确认

```javascript
try {
    // 执行步骤
    result = this.agent.executeCommand(step.command.split(' ')[1]);
    
    if (result.success) {
        console.log(`✅ 执行成功`);
        step.status = 'completed';
    } else {
        console.log(`❌ 执行失败`);
        step.status = 'failed';
    }
} catch (error) {
    console.log(`❌ 步骤失败: ${error.message}`);
    step.status = 'failed';
    
    // 询问用户是否继续
    const continueExecution = await this.askQuestion('是否继续执行后续步骤？(y/n): ');
    if (continueExecution.toLowerCase() !== 'y') {
        console.log('🛑 计划执行已停止');
        plan.status = 'failed';
        return;
    }
}
```

**关键点：**
- 使用 try-catch 捕获异常
- 更新步骤状态为 'failed'
- 询问用户是否继续执行
- 根据用户选择决定是否停止

## 🎮 交互流程图

```
用户输入请求
    ↓
生成计划
    ↓
显示计划
    ↓
用户选择
    ├─→ 1: 批准执行
    │       ↓
    │   执行计划
    │       ↓
    │   显示进度
    │       ↓
    │   完成
    │
    ├─→ 2: 修改计划
    │       ↓
    │   显示步骤列表
    │       ↓
    │   用户选择步骤
    │       ↓
    │   用户输入新描述
    │       ↓
    │   更新步骤
    │       ↓
    │   重新显示计划
    │       ↓
    │   是否继续修改？
    │       ├─→ 是: 继续修改
    │       └─→ 否: 退出修改
    │
    └─→ 3: 取消
            ↓
        退出
```

## 📊 数据结构变化

### 修改前：
```javascript
plan = {
    id: 'plan_123',
    description: '帮我读取文件',
    steps: [
        { id: 1, action: '读取文件 test.txt', status: 'pending' }
    ],
    status: 'draft'
}
```

### 修改后：
```javascript
plan = {
    id: 'plan_123',
    description: '帮我读取文件',
    steps: [
        { id: 1, action: '读取文件 package.json', status: 'pending' }  // 已修改
    ],
    status: 'draft'
}
```

## 🧪 测试方法

### 测试1：基本修改功能

```bash
cd minimal_agent
node -e "
const Agent = require('./agent');
const PlanMode = require('./plan_mode_enhanced');

const agent = new Agent();
const planMode = new PlanMode(agent);

// 模拟用户输入
const plan = planMode.generatePlan('帮我读取 README.md 文件');
console.log('生成的计划：');
planMode.displayPlan(plan);

// 模拟修改（实际需要用户交互）
console.log('\n测试修改功能...');
"
```

### 测试2：交互式测试

```bash
cd minimal_agent
node -e "
const Agent = require('./agent');
const PlanMode = require('./plan_mode_enhanced');

const agent = new Agent();
const planMode = new PlanMode(agent);

// 运行交互式流程
planMode.run('帮我重构这个代码');
"
```

## 🎯 关键学习点

### 1. 异步编程
- 使用 `async/await` 处理用户输入
- 将回调函数封装为 Promise
- 递归调用处理循环交互

### 2. 数据结构
- 计划对象包含 steps 数组
- 每个步骤有 id, action, status 等属性
- 直接修改对象属性更新状态

### 3. 用户交互
- 清晰的提示信息
- 输入验证和错误处理
- 友好的反馈信息

### 4. 状态管理
- 跟踪计划状态 (draft, executing, completed, failed)
- 跟踪步骤状态 (pending, completed, failed)
- 根据状态决定下一步操作

## 🚀 下一步学习

### 1. 尝试修改代码
- 修改进度条的显示样式
- 添加更多步骤类型
- 改进错误处理逻辑

### 2. 添加新功能
- 计划保存/加载
- 并行执行步骤
- 依赖管理

### 3. 优化用户体验
- 添加颜色输出
- 改进输入验证
- 添加帮助信息

## 💡 常见问题

### Q1: 为什么使用递归而不是循环？
**A1:** 递归更符合用户交互的思维模式。用户可能多次修改，递归调用更自然。

### Q2: 如何处理用户输入超时？
**A2:** 可以使用 `setTimeout` 设置超时，超时后自动继续或取消。

### Q3: 如何保存修改后的计划？
**A3:** 可以将 plan 对象序列化为 JSON 文件，下次加载时恢复。

---

*通过这个增强版实现，你应该能够理解 Plan Mode 的核心原理。动手修改代码，加深理解！*
