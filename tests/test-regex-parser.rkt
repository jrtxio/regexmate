#lang racket

(require rackunit
         "../core/ast.rkt"
         "../core/regex-parser.rkt")

(define regex-parser-tests
  (test-suite
   "正则解析器测试"

   ;; 字面量
   (test-case "解析字面量"
     (define ast (parse-regex "a"))
     (check-true (re-literal? ast))
     (check-equal? (re-literal-char ast) #\a))

   (test-case "解析多字面量序列"
     (define ast (parse-regex "abc"))
     (check-true (re-sequence? ast))
     (check-equal? (length (re-sequence-elements ast)) 3))

   ;; 任意字符
   (test-case "解析点号"
     (define ast (parse-regex "."))
     (check-true (re-any? ast)))

   ;; 转义序列
   (test-case "解析 \\d"
     (define ast (parse-regex "\\d"))
     (check-true (re-escape? ast))
     (check-equal? (re-escape-type ast) 'digit))

   (test-case "解析 \\w"
     (define ast (parse-regex "\\w"))
     (check-true (re-escape? ast))
     (check-equal? (re-escape-type ast) 'word))

   (test-case "解析 \\s"
     (define ast (parse-regex "\\s"))
     (check-true (re-escape? ast))
     (check-equal? (re-escape-type ast) 'space))

   (test-case "解析 \\D \\W \\S"
     (check-equal? (re-escape-type (parse-regex "\\D")) 'non-digit)
     (check-equal? (re-escape-type (parse-regex "\\W")) 'non-word)
     (check-equal? (re-escape-type (parse-regex "\\S")) 'non-space))

   ;; 字符类
   (test-case "解析字符类 [abc]"
     (define ast (parse-regex "[abc]"))
     (check-true (re-char-class? ast))
     (check-false (re-char-class-negated? ast)))

   (test-case "解析范围字符类 [a-z]"
     (define ast (parse-regex "[a-z]"))
     (check-true (re-char-class? ast))
     (define ranges (re-char-class-ranges ast))
     (check-true (pair? (car ranges)))
     (check-equal? (caar ranges) #\a)
     (check-equal? (cdar ranges) #\z))

   (test-case "解析否定字符类 [^a-z]"
     (define ast (parse-regex "[^a-z]"))
     (check-true (re-char-class? ast))
     (check-true (re-char-class-negated? ast)))

   ;; 锚点
   (test-case "解析 ^"
     (define ast (parse-regex "^"))
     (check-true (re-anchor? ast))
     (check-equal? (re-anchor-type ast) 'start))

   (test-case "解析 $"
     (define ast (parse-regex "$"))
     (check-true (re-anchor? ast))
     (check-equal? (re-anchor-type ast) 'end))

   ;; 量词
   (test-case "解析 ? 量词"
     (define ast (parse-regex "a?"))
     (check-true (re-quantifier? ast))
     (check-equal? (re-quantifier-min ast) 0)
     (check-equal? (re-quantifier-max ast) 1)
     (check-true (re-quantifier-greedy? ast)))

   (test-case "解析 * 量词"
     (define ast (parse-regex "a*"))
     (check-true (re-quantifier? ast))
     (check-equal? (re-quantifier-min ast) 0)
     (check-false (re-quantifier-max ast)))

   (test-case "解析 + 量词"
     (define ast (parse-regex "a+"))
     (check-true (re-quantifier? ast))
     (check-equal? (re-quantifier-min ast) 1)
     (check-false (re-quantifier-max ast)))

   (test-case "解析非贪婪量词"
     (define ast (parse-regex "a*?"))
     (check-true (re-quantifier? ast))
     (check-false (re-quantifier-greedy? ast)))

   (test-case "解析 {n} 量词"
     (define ast (parse-regex "a{3}"))
     (check-true (re-quantifier? ast))
     (check-equal? (re-quantifier-min ast) 3)
     (check-equal? (re-quantifier-max ast) 3))

   (test-case "解析 {n,m} 量词"
     (define ast (parse-regex "a{2,5}"))
     (check-true (re-quantifier? ast))
     (check-equal? (re-quantifier-min ast) 2)
     (check-equal? (re-quantifier-max ast) 5))

   (test-case "解析 {n,} 量词"
     (define ast (parse-regex "a{2,}"))
     (check-true (re-quantifier? ast))
     (check-equal? (re-quantifier-min ast) 2)
     (check-false (re-quantifier-max ast)))

   ;; 分组
   (test-case "解析捕获组"
     (define ast (parse-regex "(ab)"))
     (check-true (re-group? ast))
     (check-true (re-group-capture? ast))
     (check-false (re-group-name ast)))

   (test-case "解析非捕获组"
     (define ast (parse-regex "(?:ab)"))
     (check-true (re-group? ast))
     (check-false (re-group-capture? ast)))

   (test-case "解析命名组"
     (define ast (parse-regex "(?<name>ab)"))
     (check-true (re-group? ast))
     (check-true (re-group-capture? ast))
     (check-equal? (re-group-name ast) "name"))

   ;; 交替
   (test-case "解析交替 a|b"
     (define ast (parse-regex "a|b"))
     (check-true (re-alternation? ast))
     (check-true (re-literal? (re-alternation-left ast)))
     (check-true (re-literal? (re-alternation-right ast))))

   (test-case "解析多路交替 a|b|c"
     (define ast (parse-regex "a|b|c"))
     (check-true (re-alternation? ast))
     (check-true (re-alternation? (re-alternation-right ast))))

   ;; 复杂组合
   (test-case "解析邮箱正则"
     (define ast (parse-regex "[a-zA-Z0-9]+@[a-zA-Z]+\\.[a-zA-Z]{2,}"))
     (check-true (re-sequence? ast)))

   (test-case "解析空字符串"
     (define ast (parse-regex ""))
     (check-true (re-sequence? ast))
     (check-equal? (re-sequence-elements ast) '()))

   ;; node-type 测试
   (test-case "node-type 正确返回类型"
     (check-equal? (node-type (parse-regex "a")) 're-literal)
     (check-equal? (node-type (parse-regex ".")) 're-any)
     (check-equal? (node-type (parse-regex "^")) 're-anchor)
     (check-equal? (node-type (parse-regex "\\d")) 're-escape)
     (check-equal? (node-type (parse-regex "[a-z]")) 're-char-class)
     (check-equal? (node-type (parse-regex "a|b")) 're-alternation))
   ))

(provide regex-parser-tests)
