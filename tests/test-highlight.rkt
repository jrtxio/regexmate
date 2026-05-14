#lang racket

(require rackunit
         "../output/highlight.rkt")

(define highlight-tests
  (test-suite
   "终端高亮测试"

   (test-case "无匹配时返回原文"
     (check-equal? (highlight-matches "hello" '()) "hello"))

   (test-case "纯文本格式包含匹配信息"
     ;; 在非 TTY 环境下测试纯文本格式
     (define result (format-plain-matches "abc 123 def" '((4 . 7))))
     (check-true (string-contains? result "1 个匹配"))
     (check-true (string-contains? result "123")))

   (test-case "多个匹配的纯文本格式"
     (define result (format-plain-matches "abc 123 def 456" '((4 . 7) (12 . 15))))
     (check-true (string-contains? result "2 个匹配")))

   (test-case "空文本无匹配"
     (check-equal? (highlight-matches "" '()) ""))
   ))

(provide highlight-tests)
