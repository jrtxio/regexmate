#lang racket

(require json)

;; 格式化 validate JSON 输出
(define (format-validate-json pattern valid error)
  (jsexpr->string
   (if valid
       (hasheq 'pattern pattern 'valid #t)
       (hasheq 'pattern pattern 'valid #f 'error error))))

;; 格式化 match JSON 输出
(define (format-match-json pattern text matches)
  (jsexpr->string
   (hasheq 'pattern pattern
           'text text
           'matches matches
           'count (length matches))))

;; 格式化 explain JSON 输出
(define (format-explain-json pattern parts)
  (jsexpr->string
   (hasheq 'pattern pattern 'parts parts)))

(provide format-validate-json format-match-json format-explain-json)
