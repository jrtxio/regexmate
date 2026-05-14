#lang racket

(require rackunit
         json
         "../output/json-format.rkt")

(define json-format-tests
  (test-suite
   "JSON 输出格式测试"

   (test-case "validate 有效正则"
     (define json-str (format-validate-json "^\\d+$" #t #f))
     (define data (string->jsexpr json-str))
     (check-equal? (hash-ref data 'valid) #t)
     (check-equal? (hash-ref data 'pattern) "^\\d+$"))

   (test-case "validate 无效正则"
     (define json-str (format-validate-json "[" #f "expected closing bracket"))
     (define data (string->jsexpr json-str))
     (check-equal? (hash-ref data 'valid) #f)
     (check-true (hash-has-key? data 'error)))

   (test-case "match 有结果"
     (define matches
       (list (hasheq 'value "123" 'start 4 'end 7)
             (hasheq 'value "456" 'start 12 'end 15)))
     (define json-str (format-match-json "\\d+" "abc 123 def 456" matches))
     (define data (string->jsexpr json-str))
     (check-equal? (hash-ref data 'count) 2)
     (check-equal? (length (hash-ref data 'matches)) 2))

   (test-case "match 无结果"
     (define json-str (format-match-json "\\d+" "abc" '()))
     (define data (string->jsexpr json-str))
     (check-equal? (hash-ref data 'count) 0)
     (check-equal? (hash-ref data 'matches) '()))

   (test-case "explain 输出"
     (define parts
       (list (hasheq 'type "re-escape" 'description "数字 (\\d)" 'raw "\\d")
             (hasheq 'type "re-quantifier" 'description "2 到 4 次" 'raw "{2,4}")))
     (define json-str (format-explain-json "\\d{2,4}" parts))
     (define data (string->jsexpr json-str))
     (check-equal? (hash-ref data 'pattern) "\\d{2,4}")
     (check-equal? (length (hash-ref data 'parts)) 2))

   (test-case "所有输出是合法 JSON"
     (check-not-exn (lambda () (string->jsexpr (format-validate-json "abc" #t #f))))
     (check-not-exn (lambda () (string->jsexpr (format-validate-json "abc" #f "error"))))
     (check-not-exn (lambda () (string->jsexpr (format-match-json "a" "b" '())))))
   ))

(provide json-format-tests)
