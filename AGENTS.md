# Repository Guidelines

## Project Structure & Module Organization

This repository contains AI Agent learning resources and tutorials, organized into a clear directory structure.

```
AI-Agent-Study/
├── README.md                    # Project homepage
├── AGENTS.md                    # This contributor guide
├── docs/                        # Documentation directory
│   ├── INDEX.md                 # Documentation index
│   ├── tutorials/               # Tutorials and guides
│   ├── plan-mode/               # Plan Mode专题
│   └── git/                     # Git相关文档
├── minimal_agent/               # Agent code implementation
│   ├── agent.js                 # JavaScript version (recommended)
│   ├── agent.py                 # Python version
│   ├── plan_mode.js             # Plan Mode implementation
│   └── test_plan_mode.js        # Plan Mode test script
└── .vscode/                     # VS Code configuration
```

## Content Guidelines

### Adding New Resources

1. **Determine the category:**
   - **Tutorials**: Learning guides, feature explanations, tutorials → `docs/tutorials/`
   - **Plan Mode**: Plan Mode related documents → `docs/plan-mode/`
   - **Git**: Git setup and configuration → `docs/git/`
   - **Agent Code**: Implementation files → `minimal_agent/`

2. **Follow naming conventions:**
   - Use lowercase with underscores: `my_topic_guide.md`
   - Include date/version when relevant: `tutorial_2026.md`
   - Use descriptive names indicating content purpose

3. **Update documentation:**
   - Update `docs/INDEX.md` if adding new categories
   - Update this `AGENTS.md` if adding new resource types
   - Update `README.md` if changes affect project structure

### Content Quality Standards

- Ensure content is accurate and up-to-date
- Include practical examples and code snippets when relevant
- Structure content with clear headings and logical flow
- Keep explanations accessible to beginners while maintaining technical accuracy
- Use proper Markdown formatting

## File Naming Conventions

### General Rules
- Use lowercase with underscores for multi-word filenames: `my_topic_guide.md`
- Include date or version indicators when relevant: `tutorial_2026.md`
- Use descriptive names that indicate content purpose
- Avoid special characters except hyphens and underscores

### Category-Specific Naming

#### Tutorials (`docs/tutorials/`)
- `learning_guide.md` - Learning path guide
- `modern_agent_features.md` - Modern agent features
- `one_week_plan.md` - One week plan
- `quick_start.md` - Quick start guide
- `summary.md` - Learning summary
- `lidang_tutorial.md` - Original tutorial

#### Plan Mode (`docs/plan-mode/`)
- `analysis.md` - Codex Plan Mode analysis
- `practice.md` - Practice implementation guide
- `faq.md` - Frequently asked questions
- `implementation_guide.md` - Implementation plan
- `complete.md` - Completion guide

#### Git (`docs/git/`)
- `setup_guide.md` - Git setup guide
- `setup.ps1` - Git setup script

#### Agent Code (`minimal_agent/`)
- `agent.js` - Main JavaScript implementation
- `agent.py` - Python implementation
- `plan_mode.js` - Plan Mode implementation
- `test_plan_mode.js` - Test script
- `agent_analysis.md` - Agent analysis document

## Contribution Process

### Adding Content
1. Create new content following the naming conventions above
2. Place files in the appropriate directory based on category
3. Ensure content is well-structured with proper Markdown formatting
4. Update `docs/INDEX.md` if adding new categories
5. Update this `AGENTS.md` if adding new resource types
6. Update `README.md` if changes affect project structure

### Content Review
- Verify technical accuracy of all code examples
- Ensure proper attribution for external references
- Check for consistent formatting and style
- Test any code examples to ensure they work correctly

### Documentation Updates
- Keep documentation synchronized with code changes
- Update file links when moving or renaming files
- Ensure all cross-references are valid

## Directory Structure Details

### `docs/` - Documentation Root
Contains all documentation files organized by category.

### `docs/tutorials/` - Tutorials and Guides
Learning materials, guides, and educational content.

### `docs/plan-mode/` - Plan Mode专题
All Plan Mode related documentation and guides.

### `docs/git/` - Git Related
Git setup guides and configuration scripts.

### `minimal_agent/` - Agent Code
Source code and implementation files for the AI Agent.

### `.vscode/` - VS Code Configuration
VS Code workspace settings and configurations.

## Recommended Tools

- **Markdown Editor**: VS Code, Typora, or any Markdown-capable editor
- **Content Validation**: Preview Markdown rendering before committing
- **Code Testing**: Test all code examples before documenting
- **Link Checking**: Verify all internal and external links work

## Commit Guidelines

- Use descriptive commit messages: `Add tutorial on multi-agent systems`
- Reference specific sections when updating existing content
- Keep commits focused on single logical changes
- Include file path in commit message when moving/renaming files

## Current Resources

### Tutorials
- Comprehensive guide on AI Agent development
- Modern Agent features learning guide
- One week intensive learning plan
- Quick start guide for beginners

### Plan Mode
- Codex Plan Mode detailed analysis
- Practice implementation guide
- Frequently asked questions
- Implementation plan and completion guide

### Agent Code
- Minimal Coding Agent implementation (JavaScript & Python)
- Plan Mode implementation
- Test scripts and examples

## Future Expansion

This repository is designed to grow with contributions including:
- Additional tutorials on specific agent frameworks
- Code examples and implementations
- Comparative analysis of different agent approaches
- Best practices and design patterns
- Documentation for new features and capabilities

---

*For questions or suggestions about contributing, please open an issue or submit a pull request.*
