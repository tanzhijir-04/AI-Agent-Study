# 🤖 AI Agent Study

> 从零开始学习AI Agent开发的完整学习资源库

## 📚 项目简介

本仓库包含AI Agent学习的完整资料，从基础的最小Agent实现到现代Agent特性的深入学习。

## 🎯 学习路径

### 第一阶段：基础入门
- [x] 手写最小Coding Agent
- [x] 理解Agent核心循环

### 第二阶段：现代特性学习
- [x] Plan Mode（计划模式）
- [ ] Memory系统（记忆系统）
- [ ] Context Compression（上下文压缩）
- [ ] Multi-agent管理
- [ ] Background Tasks（后台任务）
- [ ] Skills/Plugins系统
- [ ] Loop/Workflow控制
- [ ] Sandbox环境控制
- [ ] MCP配置
- [ ] TUI优化
- [ ] 可视化和可观测性

## 📁 项目结构

```
AI-Agent-Study/
├── README.md                    # 项目主页
├── AGENTS.md                    # 贡献指南
├── docs/                        # 文档目录
│   ├── INDEX.md                 # 文档索引
│   ├── tutorials/               # 教程和指南
│   │   ├── lidang_tutorial.md   # 原始教程（峰哥AI学习视频文字版）
│   │   ├── learning_guide.md    # 完整学习路径指南
│   │   ├── modern_agent_features.md  # 现代Agent特性详解
│   │   ├── one_week_plan.md     # 一周速成计划
│   │   ├── quick_start.md       # 快速开始指南
│   │   └── summary.md           # 学习成果总结
│   ├── plan-mode/               # Plan Mode 专题
│   │   ├── analysis.md          # Codex Plan Mode 详细分析
│   │   ├── practice.md          # 实践实现指南
│   │   ├── faq.md               # 常见问题解答
│   │   ├── implementation_guide.md  # 简单实现计划
│   │   └── complete.md          # 完成指南
│   └── git/                     # Git 相关
│       ├── setup_guide.md       # Git设置指南
│       └── setup.ps1            # Git设置脚本
├── minimal_agent/               # Agent 代码
│   ├── agent.js                 # JavaScript版本（推荐）
│   ├── agent.py                 # Python版本
│   ├── plan_mode.js             # Plan Mode实现
│   ├── test_plan_mode.js        # Plan Mode测试脚本
│   ├── agent_analysis.md        # Agent解读教材
│   └── README.md                # Agent说明文档
└── .vscode/                     # VS Code 配置
    └── settings.json
```

## 🚀 快速开始
### 学习笔记
- **[AI Agent 学习笔记](AI_AGENT_STUDY_NOTES.md)** - 两天学习内容的完整总结，适合复盘和复习

### 1. 运行最小Agent

```bash
cd minimal_agent
node agent.js
```

### 2. 尝试基本命令

```
🤖 Agent> exec echo "Hello, Agent!"
🤖 Agent> write test.txt
🤖 Agent> read test.txt
🤖 Agent> plan 帮我读取 README.md 文件
🤖 Agent> history
🤖 Agent> quit
```

## 📖 学习资料

### 文档导航
- **[文档索引](docs/INDEX.md)** - 完整的文档分类和导航
- **[教程目录](docs/tutorials/)** - 所有教程和指南
- **[Plan Mode专题](docs/plan-mode/)** - Plan Mode 完整学习资料
- **[Git相关](docs/git/)** - Git设置和配置

### 核心文档
- **[学习路径指南](docs/tutorials/learning_guide.md)** - 完整学习路径
- **[现代Agent特性](docs/tutorials/modern_agent_features.md)** - 现代Agent特性详解
- **[一周速成计划](docs/tutorials/one_week_plan.md)** - 一周速成计划

### 快速入门
- **[快速开始](docs/tutorials/quick_start.md)** - 快速开始指南
- **[学习总结](docs/tutorials/summary.md)** - 学习成果总结

### 原始教程
- **[峰哥AI学习视频](docs/tutorials/lidang_tutorial.md)** - 原始教程文字版（2026年）

## 🎓 学习目标

完成本课程后，你将能够：

1. ✅ 理解Agent的核心工作原理
2. ✅ 实现基本的Coding Agent
3. ✅ 掌握现代Agent的关键特性（Plan Mode）
4. ✅ 具备进一步深入学习的基础

## 💡 教程关键点

### 关于模型选择
> "对于大部分的工作而言，买质朴moon shot就是约战面，买阿里，买deep sick，买小米快手mini max基业形成"

**建议**：使用性价比高的国产模型（80-90分模型）

### 关于Multi-agent
> "multi agent它不太适合于编程问题"

**警告**：
- ❌ 不要用于并行编程
- ❌ 不要用于公司架构模拟
- ✅ 适合大规模并行任务（Map-Reduce）

### 关于学习顺序
> "从马车蒸汽汽车开始，你已经实现了第一节课。你要和看一看和今天最好的这些开源的实现你有哪些差距。"

**建议**：先完成基础，再研究高级实现

## 📚 推荐资源

### 官方文档
- [Claude Code文档](https://docs.anthropic.com/claude-code)
- [OpenAI Codex文档](https://platform.openai.com/docs/codex)
- [MCP协议文档](https://modelcontextprotocol.io)

### 开源项目
- [Claude Code](https://github.com/anthropics/claude-code)
- [Open Interpreter](https://github.com/OpenInterpreter/open-interpreter)
- [GPT Engineer](https://github.com/gpt-engineer-org/gpt-engineer)

## 🤝 贡献

欢迎提交Issue和Pull Request！

详见 [AGENTS.md](AGENTS.md) 了解贡献指南。

## 📄 许可证

MIT License

---

*记住：这是你的AI Agent学习之旅的第一步。完成它，你就入门了！*

