# RegexMate

基于 [Racket](https://racket-lang.org/) 开发的跨平台 GUI 正则表达式工具，支持 AI 辅助构建正则。RegexMate 同时提供 Agent 友好的 CLI 模式，输出结构化 JSON。

![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[English](README.md) · **中文**

## 功能特性

- **validate** —— 验证正则语法是否有效
- **match** —— 匹配测试，终端高亮显示匹配结果
- **explain** —— 将正则表达式拆解为人类可读的说明
- **graph** —— 生成 railroad diagram（SVG 格式）
- **JSON 模式** —— 结构化输出，方便 agent 解析（`--json`）

## 环境要求

| 依赖 | 用途 / 版本 |
|------|------------|
| [Racket](https://racket-lang.org/) | 已测试 v9.0 |

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/turinglambdaai/regexmate.git
cd regexmate
```

### 2. 使用方法

```bash
# 验证正则语法
racket main.rkt validate '^\d+$'
racket main.rkt validate '^\d+$' --json

# 匹配测试
racket main.rkt match '\d+' 'abc 123 def 456'
racket main.rkt match '\d+' 'abc 123 def 456' --json

# 解释正则各部分
racket main.rkt explain '\d{2,4}'
racket main.rkt explain '\d{2,4}' --json

# 生成 railroad diagram
racket main.rkt graph 'a|b' -o diagram.svg
```

### JSON 输出示例

**validate:**

```json
{"pattern":"^\\d+$","valid":true}
```

**match:**

```json
{"pattern":"\\d+","text":"abc 123 def 456","matches":[{"value":"123","start":4,"end":7},{"value":"456","start":12,"end":15}],"count":2}
```

**explain:**

```json
{"pattern":"\\d{2,4}","parts":[{"type":"re-quantifier","description":"数字 (\\d) × {2,4}","raw":"\\d{2,4}"}]}
```

## 项目结构

```
regexmate/
├── main.rkt                 # CLI 入口
├── run-tests.rkt            # 测试运行器
├── core/
│   ├── ast.rkt              # 正则 AST 数据结构
│   ├── regex-engine.rkt     # 验证与匹配引擎
│   └── regex-parser.rkt     # 递归下降解析器
├── output/
│   ├── highlight.rkt        # ANSI 终端高亮
│   ├── json-format.rkt      # JSON 输出格式化
│   ├── human-format.rkt     # 人类可读输出
│   └── railroad.rkt         # SVG railroad diagram 生成器
└── tests/
    ├── test-regex-engine.rkt
    ├── test-regex-parser.rkt
    ├── test-highlight.rkt
    └── test-json-format.rkt
```

## 开发

```bash
# 运行测试
racket run-tests.rkt

# 运行 CLI
racket main.rkt <command> <args>
```

## 许可证

基于 [MIT License](LICENSE) 开源。
