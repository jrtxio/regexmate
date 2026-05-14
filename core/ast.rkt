#lang racket

;; 正则表达式 AST 数据结构

(struct re-literal (char) #:transparent)
(struct re-any () #:transparent)
(struct re-char-class (ranges negated?) #:transparent)
(struct re-anchor (type) #:transparent)
(struct re-quantifier (base min max greedy?) #:transparent)
(struct re-group (child capture? name) #:transparent)
(struct re-alternation (left right) #:transparent)
(struct re-sequence (elements) #:transparent)
(struct re-escape (type) #:transparent)

;; 获取节点类型名称
(define (node-type node)
  (cond
    [(re-literal? node) 're-literal]
    [(re-any? node) 're-any]
    [(re-char-class? node) 're-char-class]
    [(re-anchor? node) 're-anchor]
    [(re-quantifier? node) 're-quantifier]
    [(re-group? node) 're-group]
    [(re-alternation? node) 're-alternation]
    [(re-sequence? node) 're-sequence]
    [(re-escape? node) 're-escape]))

(provide (struct-out re-literal)
         (struct-out re-any)
         (struct-out re-char-class)
         (struct-out re-anchor)
         (struct-out re-quantifier)
         (struct-out re-group)
         (struct-out re-alternation)
         (struct-out re-sequence)
         (struct-out re-escape)
         node-type)
