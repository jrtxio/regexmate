#lang racket

(require racket/match
         "../core/ast.rkt"
         "../core/regex-parser.rkt")

;; AST 节点 → 解释描述
(define (ast->description node)
  (match node
    [(re-literal c) (format "字面量: ~a" c)]
    [(re-any) "任意字符 (.)"]
    [(re-char-class ranges neg?)
     (define class-str
       (string-join
        (for/list ([r ranges])
          (match r
            [(cons a b) (format "~a-~a" a b)]
            [c (format "~a" c)]))
        ", "))
     (format "字符类: [~a~a]" (if neg? "^" "") class-str)]
    [(re-anchor 'start) "锚点: 行首 (^)"]
    [(re-anchor 'end) "锚点: 行尾 ($)"]
    [(re-quantifier base min max greedy?)
     (define base-desc (ast->description base))
     (define quant-desc
       (cond
         [(and (= min 0) (eq? max #f)) (if greedy? "*" "*? (非贪婪)")]
         [(and (= min 1) (eq? max #f)) (if greedy? "+" "+? (非贪婪)")]
         [(and (= min 0) (= max 1)) (if greedy? "?" "?? (非贪婪)")]
         [(eq? max #f) (format "{~a,}" min)]
         [(= min max) (format "{~a}" min)]
         [else (format "{~a,~a}" min max)]))
     (format "~a × ~a" base-desc quant-desc)]
    [(re-group child capture? name)
     (define inner (ast->description child))
     (cond
       [(and capture? name) (format "命名组 (?<~a> ...): ~a" name inner)]
       [capture? (format "捕获组 (...): ~a" inner)]
       [else (format "非捕获组 (?:...): ~a" inner)])]
    [(re-alternation left right)
     (format "交替: ~a | ~a" (ast->description left) (ast->description right))]
    [(re-sequence elems)
     (string-join (map ast->description elems) " → ")]
    [(re-escape type)
     (case type
       [(digit) "数字 (\\d)"]
       [(non-digit) "非数字 (\\D)"]
       [(word) "单词字符 (\\w)"]
       [(non-word) "非单词字符 (\\W)"]
       [(space) "空白 (\\s)"]
       [(non-space) "非空白 (\\S)"]
       [(word-boundary) "单词边界 (\\b)"]
       [else (format "转义: \\~a" type)])]))

;; AST 节点 → 原始字符串表示
(define (ast->raw node)
  (match node
    [(re-literal c) (format "~a" c)]
    [(re-any) "."]
    [(re-char-class ranges neg?)
     (format "[~a~a]"
             (if neg? "^" "")
             (string-join
              (for/list ([r ranges])
                (match r
                  [(cons a b) (format "~a-~a" a b)]
                  [c (format "~a" c)]))
              ""))]
    [(re-anchor 'start) "^"]
    [(re-anchor 'end) "$"]
    [(re-quantifier base min max greedy?)
     (define base-raw (ast->raw base))
     (define quant-raw
       (cond
         [(and (= min 0) (eq? max #f)) "*"]
         [(and (= min 1) (eq? max #f)) "+"]
         [(and (= min 0) (= max 1)) "?"]
         [(eq? max #f) (format "{~a,}" min)]
         [(= min max) (format "{~a}" min)]
         [else (format "{~a,~a}" min max)]))
     (string-append base-raw quant-raw (if greedy? "" "?"))]
    [(re-group child capture? name)
     (define inner (ast->raw child))
     (cond
       [(and capture? name) (format "(?<~a>~a)" name inner)]
       [capture? (format "(~a)" inner)]
       [else (format "(?:~a)" inner)])]
    [(re-alternation left right)
     (format "~a|~a" (ast->raw left) (ast->raw right))]
    [(re-sequence elems)
     (string-join (map ast->raw elems) "")]
    [(re-escape type)
     (case type
       [(digit) "\\d"]
       [(non-digit) "\\D"]
       [(word) "\\w"]
       [(non-word) "\\W"]
       [(space) "\\s"]
       [(non-space) "\\S"]
       [(word-boundary) "\\b"]
       [else (format "\\~a" type)])]))

;; 解释正则表达式 → parts 列表
(define (explain-regex pattern)
  (define ast (parse-regex pattern))
  (define (node->part node)
    (hasheq 'type (symbol->string (node-type node))
            'description (ast->description node)
            'raw (ast->raw node)))
  (match ast
    [(re-sequence elems) (map node->part elems)]
    [single (list (node->part single))]))

;; 人类可读的格式化输出
(define (format-explain-human pattern parts)
  (string-append
   (format "正则表达式: ~a\n\n" pattern)
   "组成部分:\n"
   (string-join
    (for/list ([p parts] [i (in-naturals 1)])
      (format "  ~a. [~a] ~a  ← ~a"
              i
              (hash-ref p 'type)
              (hash-ref p 'raw)
              (hash-ref p 'description)))
    "\n")))

(provide explain-regex format-explain-human ast->description ast->raw)
