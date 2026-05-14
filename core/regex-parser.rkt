#lang racket

(require racket/match
         "ast.rkt")

;; 正则表达式递归下降解析器
;; 将正则字符串解析为 AST

(define (parse-regex str)
  (define pos 0)
  (define len (string-length str))

  (define (peek)
    (and (< pos len) (string-ref str pos)))

  (define (advance)
    (begin0 (peek) (set! pos (add1 pos))))

  (define (at-end?) (>= pos len))

  (define (expect c)
    (unless (and (peek) (char=? (peek) c))
      (error 'parse-regex "expected '~a' at position ~a in ~v" c pos str))
    (advance))

  ;; 顶层：解析交替
  (define (parse-alt)
    (define left (parse-seq))
    (cond
      [(and (peek) (char=? (peek) #\|))
       (advance)
       (re-alternation left (parse-alt))]
      [else left]))

  ;; 序列：量词化的原子的连接
  (define (parse-seq)
    (define elems
      (let loop ()
        (cond
          [(or (at-end?)
               (and (peek) (char=? (peek) #\)))
               (and (peek) (char=? (peek) #\|)))
           '()]
          [else
           (define q (parse-quantified))
           (if q (cons q (loop)) '())])))
    (match elems
      ['() (re-sequence '())]
      [(list single) single]
      [_ (re-sequence elems)]))

  ;; 量词化的原子
  (define (parse-quantified)
    (define atom (parse-atom))
    (cond
      [(not atom) #f]
      [(at-end?) atom]
      [(memq (peek) '(#\? #\* #\+ #\{))
       (parse-quantifier-spec atom)]
      [else atom]))

  ;; 量词规格
  (define (parse-quantifier-spec base)
    (case (peek)
      [(#\?)
       (advance)
       (if (and (not (at-end?)) (char=? (peek) #\?))
           (begin (advance) (re-quantifier base 0 1 #f))
           (re-quantifier base 0 1 #t))]
      [(#\*)
       (advance)
       (if (and (not (at-end?)) (char=? (peek) #\?))
           (begin (advance) (re-quantifier base 0 #f #f))
           (re-quantifier base 0 #f #t))]
      [(#\+)
       (advance)
       (if (and (not (at-end?)) (char=? (peek) #\?))
           (begin (advance) (re-quantifier base 1 #f #f))
           (re-quantifier base 1 #f #t))]
      [(#\{) (parse-counted-quantifier base)]
      [else base]))

  ;; {n} {n,m} {n,} 量词
  (define (parse-counted-quantifier base)
    (advance) ; consume {
    (define n (parse-number))
    (define-values (min-val max-val)
      (cond
        [(and (peek) (char=? (peek) #\,))
         (advance)
         (if (and (peek) (char-numeric? (peek)))
             (values n (parse-number))
             (values n #f))]
        [else (values n n)]))
    (expect #\})
    (define greedy?
      (if (and (not (at-end?)) (char=? (peek) #\?))
          (begin (advance) #f)
          #t))
    (re-quantifier base min-val max-val greedy?))

  ;; 解析数字
  (define (parse-number)
    (define chars
      (let loop ()
        (if (and (peek) (char-numeric? (peek)))
            (cons (advance) (loop))
            '())))
    (if (null? chars)
        0
        (string->number (list->string chars))))

  ;; 解析单个原子
  (define (parse-atom)
    (cond
      [(at-end?) #f]
      [(char=? (peek) #\.) (advance) (re-any)]
      [(char=? (peek) #\^) (advance) (re-anchor 'start)]
      [(char=? (peek) #\$) (advance) (re-anchor 'end)]
      [(char=? (peek) #\() (parse-group)]
      [(char=? (peek) #\[) (parse-char-class)]
      [(char=? (peek) #\\) (parse-escape)]
      [(memq (peek) '(#\? #\* #\+ #\{ #\| #\))) #f]
      [else (re-literal (advance))]))

  ;; 分组: (...) (?:...) (?<name>...)
  (define (parse-group)
    (advance) ; consume (
    (define-values (capture? name)
      (cond
        [(and (peek) (char=? (peek) #\?))
         (advance)
         (cond
           [(and (peek) (char=? (peek) #\:))
            (advance)
            (values #f #f)]
           [(and (peek) (char=? (peek) #\<))
            (advance)
            (values #t (parse-group-name))]
           [else (values #t #f)])]
        [else (values #t #f)]))
    (define child (parse-alt))
    (expect #\))
    (re-group child capture? name))

  (define (parse-group-name)
    (define chars
      (let loop ()
        (if (and (peek) (not (char=? (peek) #\>)))
            (cons (advance) (loop))
            '())))
    (when (and (peek) (char=? (peek) #\>)) (advance))
    (list->string chars))

  ;; 字符类: [abc] [a-z] [^a-z]
  (define (parse-char-class)
    (advance) ; consume [
    (define negated?
      (if (and (peek) (char=? (peek) #\^))
          (begin (advance) #t)
          #f))
    (define ranges (parse-class-items))
    (expect #\])
    (re-char-class ranges negated?))

  (define (parse-class-items)
    (let loop ()
      (cond
        [(and (peek) (char=? (peek) #\])) '()]
        [else
         (define c (parse-class-atom))
         (cond
           [(and (peek) (char=? (peek) #\-))
            (advance)
            (if (and (peek) (not (char=? (peek) #\])))
                (let ([end-c (parse-class-atom)])
                  (cons (cons c end-c) (loop)))
                (list* c #\- (loop)))]
           [else (cons c (loop))])])))

  (define (parse-class-atom)
    (cond
      [(char=? (peek) #\\)
       (advance)
       (case (peek)
         [(#\n) (advance) #\newline]
         [(#\t) (advance) #\tab]
         [(#\r) (advance) #\return]
         [else (advance)])]
      [else (advance)]))

  ;; 转义序列: \d \D \w \W \s \S \b 等
  (define (parse-escape)
    (advance) ; consume \
    (define c (advance))
    (case c
      [(#\d) (re-escape 'digit)]
      [(#\D) (re-escape 'non-digit)]
      [(#\w) (re-escape 'word)]
      [(#\W) (re-escape 'non-word)]
      [(#\s) (re-escape 'space)]
      [(#\S) (re-escape 'non-space)]
      [(#\b) (re-escape 'word-boundary)]
      [(#\B) (re-escape 'non-word-boundary)]
      [(#\n) (re-literal #\newline)]
      [(#\t) (re-literal #\tab)]
      [(#\r) (re-literal #\return)]
      [else (re-literal c)]))

  ;; 执行解析
  (if (string=? str "")
      (re-sequence '())
      (parse-alt)))

(provide parse-regex)
