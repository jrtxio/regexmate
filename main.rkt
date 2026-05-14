#lang racket

(require racket/match
         json
         "core/regex-engine.rkt"
         "output/json-format.rkt"
         "output/highlight.rkt"
         "output/human-format.rkt"
         "output/railroad.rkt")

;; CLI 使用说明
(define (show-usage)
  (displayln "RegexMate - Agent-friendly 正则表达式 CLI 工具")
  (displayln "")
  (displayln "用法:")
  (displayln "  regexmate match <pattern> <text> [--json]     匹配测试")
  (displayln "  regexmate validate <pattern> [--json]          验证正则语法")
  (displayln "  regexmate explain <pattern> [--json]           解释正则各部分")
  (displayln "  regexmate graph <pattern> [-o output.svg]      生成 railroad diagram")
  (displayln "")
  (displayln "选项:")
  (displayln "  --json     JSON 输出（方便 agent 解析）")
  (displayln "  -o FILE    输出到文件（graph 命令）")
  (exit 2))

;; 解析 flags
(define (parse-flags args)
  (define json? (member "--json" args))
  (define output-file
    (let loop ([as args])
      (cond
        [(null? as) #f]
        [(and (string=? (car as) "-o") (not (null? (cdr as)))) (cadr as)]
        [else (loop (cdr as))])))
  (values json? output-file))

;; match 命令
(define (cmd-match pattern text json?)
  (cond
    [(not (valid-regex? pattern))
     (if json?
         (displayln (format-validate-json pattern #f (get-regex-error pattern)))
         (begin
           (displayln (format "错误: 无效的正则表达式 - ~a" (get-regex-error pattern)))
           (exit 1)))]
    [else
     (define matches (match-regex-positions pattern text))
     (define values (match-regex pattern text))
     (define match-data
       (for/list ([pos (in-list matches)] [val (in-list values)])
         (hasheq 'value val 'start (car pos) 'end (cdr pos))))
     (if json?
         (displayln (format-match-json pattern text match-data))
         (displayln (highlight-matches text matches)))]))

;; validate 命令
(define (cmd-validate pattern json?)
  (define valid (valid-regex? pattern))
  (define err (and (not valid) (get-regex-error pattern)))
  (if json?
      (displayln (format-validate-json pattern valid err))
      (begin
        (displayln (format "正则表达式: ~a" pattern))
        (displayln (if valid "✓ 语法有效" (format "✗ 语法无效: ~a" err)))
        (unless valid (exit 1)))))

;; explain 命令
(define (cmd-explain pattern json?)
  (cond
    [(not (valid-regex? pattern))
     (if json?
         (displayln (format-validate-json pattern #f (get-regex-error pattern)))
         (begin
           (displayln (format "错误: 无效的正则表达式 - ~a" (get-regex-error pattern)))
           (exit 1)))]
    [else
     (define parts (explain-regex pattern))
     (if json?
         (displayln (format-explain-json pattern parts))
         (displayln (format-explain-human pattern parts)))]))

;; graph 命令
(define (cmd-graph pattern output-file)
  (cond
    [(not (valid-regex? pattern))
     (displayln (format "错误: 无效的正则表达式 - ~a" (get-regex-error pattern)))
     (exit 1)]
    [else
     (generate-railroad-svg pattern output-file)]))

;; 主入口
(define (main)
  (define args (vector->list (current-command-line-arguments)))
  (match args
    [(list "match" pattern text rest ...)
     (define-values (json? _) (parse-flags rest))
     (cmd-match pattern text json?)]
    [(list "validate" pattern rest ...)
     (define-values (json? _) (parse-flags rest))
     (cmd-validate pattern json?)]
    [(list "explain" pattern rest ...)
     (define-values (json? _) (parse-flags rest))
     (cmd-explain pattern json?)]
    [(list "graph" pattern rest ...)
     (define-values (_ output-file) (parse-flags rest))
     (cmd-graph pattern output-file)]
    [(or (list "help") (list "--help") (list "-h") (list)) (show-usage)]
    [_ (show-usage)]))

(main)
