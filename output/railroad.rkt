#lang racket

(require pict
         file/convertible
         racket/draw
         racket/match
         "../core/ast.rkt"
         "../core/regex-parser.rkt")

;; 颜色主题
(define COLOR-NODE    (make-object color% 255 255 255))   ; white
(define COLOR-SPECIAL (make-object color% 232 245 233))   ; light green
(define COLOR-CLASS   (make-object color% 227 242 253))   ; light blue
(define COLOR-ANCHOR  (make-object color% 255 243 224))   ; light orange
(define COLOR-ESCAPE  (make-object color% 243 229 245))   ; light purple
(define COLOR-GROUP   (make-object color% 250 250 250))   ; light gray
(define COLOR-BORDER  (make-object color% 51 51 51))      ; dark gray
(define COLOR-TRACK   (make-object color% 102 102 102))   ; gray
(define COLOR-QUANT   (make-object color% 102 102 102))   ; gray

;; 节点尺寸
(define NODE-H 26)
(define NODE-PAD-X 8)
(define NODE-RADIUS 4)
(define TRACK-H 2)
(define GAP 4)
(define ALT-GAP 12)

;; 创建带文字的圆角矩形节点
(define (node-box label [bg-color COLOR-NODE])
  (define txt (text label 'default 12))
  (define w (+ (pict-width txt) (* NODE-PAD-X 2)))
  (cc-superimpose
   (colorize (filled-rounded-rectangle w NODE-H NODE-RADIUS) bg-color)
   (colorize (rectangle w NODE-H) COLOR-BORDER)
   txt))

;; 创建轨道线段
(define (track w)
  (colorize (hline w TRACK-H) COLOR-TRACK))

;; AST → Pict 转换
(define (ast->pict node)
  (match node
    [(re-literal c)
     (node-box (format "~a" c))]
    [(re-any)
     (node-box "." COLOR-SPECIAL)]
    [(re-char-class ranges neg?)
     (node-box (format-class ranges neg?) COLOR-CLASS)]
    [(re-anchor 'start)
     (node-box "^" COLOR-ANCHOR)]
    [(re-anchor 'end)
     (node-box "$" COLOR-ANCHOR)]
    [(re-escape type)
     (node-box (format-escape type) COLOR-ESCAPE)]
    [(re-sequence elems)
     (if (null? elems)
         (blank 0 NODE-H)
         (let ([pics (map ast->pict elems)])
           (apply hc-append (add-between pics (track GAP)))))]
    [(re-alternation left right)
     (alt-layout (ast->pict left) (ast->pict right))]
    [(re-quantifier base q-min q-max q-greedy?)
     (quant-layout (ast->pict base) q-min q-max q-greedy?)]
    [(re-group child capture? name)
     (group-layout (ast->pict child) capture? name)]))

;; 交替布局
(define (alt-layout left-pict right-pict)
  (define max-w (max (pict-width left-pict) (pict-width right-pict)))
  (define left-pad (/ (- max-w (pict-width left-pict)) 2))
  (define right-pad (/ (- max-w (pict-width right-pict)) 2))
  (define left-centered (hc-append (blank left-pad NODE-H) left-pict (blank right-pad NODE-H)))
  (define right-centered (hc-append (blank right-pad NODE-H) right-pict (blank left-pad NODE-H)))
  (vc-append ALT-GAP left-centered right-centered))

;; 量词布局（在节点上方/下方标注量词信息）
(define (quant-layout base-pict q-min q-max q-greedy?)
  (define label
    (cond
      [(and (= q-min 0) (eq? q-max #f)) (if q-greedy? " *" " *?")]
      [(and (= q-min 1) (eq? q-max #f)) (if q-greedy? " +" " +?")]
      [(and (= q-min 0) (= q-max 1)) (if q-greedy? " ?" " ??")]
      [(and (number? q-min) (number? q-max) (= q-min q-max)) (format " {~a}" q-min)]
      [(eq? q-max #f) (format " {~a,}" q-min)]
      [else (format " {~a,~a}" q-min q-max)]))
  (define label-pict (colorize (text label 'default 10) COLOR-QUANT))
  (define base-w (pict-width base-pict))
  (define label-w (pict-width label-pict))
  (vc-append -4
             (hc-append (/ (max 0 (- base-w label-w)) 2) label-pict)
             base-pict))

;; 分组布局（加框）
(define (group-layout child-pict capture? name)
  (define frame-color
    (if capture?
        (make-object color% 76 175 80)   ; green
        (make-object color% 158 158 158))) ; gray
  (define frame-pict
    (colorize
     (rectangle (+ (pict-width child-pict) 8) (+ (pict-height child-pict) 6))
     frame-color))
  (define grouped (cc-superimpose frame-pict child-pict))
  (if name
      (lc-superimpose
       (hc-append 2 (text "(" 'default 8) (text name 'default 8) (text ")" 'default 8))
       grouped)
      grouped))

;; 格式化字符类
(define (format-class ranges neg?)
  (define content
    (string-join
     (for/list ([r ranges])
       (match r
         [(cons a b) (format "~a-~a" a b)]
         [c (format "~a" c)]))
     ""))
  (format "[~a~a]" (if neg? "^" "") content))

;; 格式化转义序列
(define (format-escape type)
  (case type
    [(digit) "\\d"]
    [(non-digit) "\\D"]
    [(word) "\\w"]
    [(non-word) "\\W"]
    [(space) "\\s"]
    [(non-space) "\\S"]
    [(word-boundary) "\\b"]
    [(non-word-boundary) "\\B"]
    [else (format "\\~a" type)]))

;; 生成 railroad diagram SVG
(define (generate-railroad-svg pattern output-path)
  (define ast (parse-regex pattern))
  (define diagram (ast->pict ast))
  (define full-diagram (hc-append (track 16) diagram (track 16)))
  (define svg-bytes (convert full-diagram 'svg-bytes))
  (if output-path
      (begin
        (call-with-output-file output-path
          (lambda (out) (write-bytes svg-bytes out))
          #:exists 'truncate)
        (displayln (format "SVG 已保存到: ~a" output-path)))
      (write-bytes svg-bytes)))

(provide generate-railroad-svg ast->pict)
