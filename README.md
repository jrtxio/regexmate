# RegexMate

[![Language](https://img.shields.io/badge/language-Racket-red)] [![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)  [![English](https://img.shields.io/badge/lang-English-blue)](README.md) [![中文](https://img.shields.io/badge/lang-中文-red)](README.zh-CN.md)


A cross-platform GUI regular expression tool built with [Racket](https://racket-lang.org/), featuring AI assistance for more efficient regex creation. RegexMate also provides an agent-friendly CLI with structured JSON output.

## Features

- **validate** -- check regex syntax validity
- **match** -- test regex against text, with highlighted matches
- **explain** -- break down a regex into human-readable parts
- **graph** -- generate a railroad diagram as SVG
- **JSON mode** -- structured output for agent consumption (`--json`)

## Usage

```bash
# Validate regex syntax
racket main.rkt validate '^\d+$'
racket main.rkt validate '^\d+$' --json

# Match regex against text
racket main.rkt match '\d+' 'abc 123 def 456'
racket main.rkt match '\d+' 'abc 123 def 456' --json

# Explain regex parts
racket main.rkt explain '\d{2,4}'
racket main.rkt explain '\d{2,4}' --json

# Generate railroad diagram
racket main.rkt graph 'a|b' -o diagram.svg
```

## JSON Output Examples

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

## Requirements

- [Racket](https://racket-lang.org/) (tested with v9.0)

## Project Structure

```
regexmate/
├── main.rkt                 CLI entry point
├── run-tests.rkt            Test runner
├── core/
│   ├── ast.rkt              Regex AST data structures
│   ├── regex-engine.rkt     Validation and matching engine
│   └── regex-parser.rkt     Recursive descent parser
├── output/
│   ├── highlight.rkt        ANSI terminal highlighting
│   ├── json-format.rkt      JSON output formatting
│   ├── human-format.rkt     Human-readable output
│   └── railroad.rkt         SVG railroad diagram generator
└── tests/
    ├── test-regex-engine.rkt
    ├── test-regex-parser.rkt
    ├── test-highlight.rkt
    └── test-json-format.rkt
```

## Development

```bash
# Run tests
racket run-tests.rkt

# Run CLI
racket main.rkt <command> <args>
```

## License

MIT
