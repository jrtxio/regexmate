#lang racket

(require rackunit
         rackunit/text-ui)

(require "tests/test-regex-engine.rkt")
(require "tests/test-regex-parser.rkt")
(require "tests/test-highlight.rkt")
(require "tests/test-json-format.rkt")

(define all-tests
  (test-suite
   "RegexMate 测试套件"
   regex-engine-tests
   regex-parser-tests
   highlight-tests
   json-format-tests))

(displayln "=== RegexMate 测试 ===")
(displayln "")

(define results (run-tests all-tests))

(displayln "")
(displayln "=== 测试完成 ===")

(if (or (number? results)
        (and (list? results) (= 0 (list-ref results 2) (list-ref results 3))))
    (exit 0)
    (exit 1))
