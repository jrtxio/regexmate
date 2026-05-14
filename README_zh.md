# RegexMate

Agent 友好的正则表达式 CLI 工具。为人类和 AI agent 设计。

## 功能

- **validate** — 验证正则语法
- **match** — 匹配测试，支持终端高亮
- **explain** — 拆解正则表达式为可读说明
- **graph** — 生成 railroad diagram（SVG）
- **JSON 模式** — 结构化输出，方便 agent 解析（`--json`）

## 使用

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

## JSON 输出示例

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

## 环境要求

- [Racket](https://racket-lang.org/)（已测试 v9.0）

## 项目结构

```
regexmate/
├── main.rkt                 # CLI 入口
├── core/
│   ├── ast.rkt              # 正则 AST 数据结构
│   ├── regex-engine.rkt     # 验证与匹配
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

MIT
