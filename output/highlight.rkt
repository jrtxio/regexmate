#lang racket

;; ANSI 颜色代码
(define ANSI-RED "\033[31m")
(define ANSI-GREEN "\033[32m")
(define ANSI-YELLOW "\033[33m")
(define ANSI-BOLD "\033[1m")
(define ANSI-RESET "\033[0m")

;; 检测是否为终端
(define (tty?)
  (terminal-port? (current-output-port)))

;; 高亮匹配区域
(define (highlight-matches text positions)
  (cond
    [(null? positions) text]
    [(not (tty?)) (format-plain-matches text positions)]
    [else (highlight-with-ansi text (sort positions < #:key car))]))

;; 纯文本格式（无颜色时显示匹配上下文）
(define (format-plain-matches text positions)
  (define count (length positions))
  (define matches
    (for/list ([pos positions])
      (define start (car pos))
      (define end (cdr pos))
      (format "  位置 ~a-~a: \"~a\"" start end (substring text start end))))
  (string-append
   (format "找到 ~a 个匹配:\n" count)
   (string-join matches "\n")))

;; ANSI 颜色高亮
(define (highlight-with-ansi text sorted-positions)
  (define out (open-output-string))
  (let loop ([i 0] [remaining sorted-positions])
    (cond
      [(>= i (string-length text))
       (get-output-string out)]
      [(null? remaining)
       (write-string (substring text i) out)
       (get-output-string out)]
      [else
       (define pos (car remaining))
       (define start (car pos))
       (define end (cdr pos))
       (cond
         [(< i start)
          (write-string (substring text i start) out)
          (loop start remaining)]
         [(= i start)
          (write-string ANSI-BOLD out)
          (write-string ANSI-GREEN out)
          (write-string (substring text i (min end (string-length text))) out)
          (write-string ANSI-RESET out)
          (loop end (cdr remaining))]
         [else
          (loop i (cdr remaining))])])))

(provide highlight-matches tty? format-plain-matches)
