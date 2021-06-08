;;; spark.el --- sparkline generation -*- lexical-binding: t -*-

;; This software uses code ported from cl-spark:
;; Copyright (c) 2013 Takaya OCHIAI <tkych.repl@gmail.com>
;; Copyright (c) 2016 alvinfrancis <alvin.francis.dumalus@gmail.com>
;; This software is released under the MIT License.
;; For more details, see spark/LICENSE

;; Author: Alvin Francis Dumalus
;; URL: https://github.com/alvinfrancis/spark
;; Version: 20160412.1606
;; Keywords: lisp, data
;; Package-Requires: ((emacs "24.3"))

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; Spark is a straightforward Emacs Lisp port of Takaya OCHIAI's
;; cl-spark: https://github.com/tkych/cl-spark

;; Note: The characters used by spark is also dependent on face.

;; Use `spark' to generate a sparkline string.  Use `spark-v' to
;; instead create a vertical bar graph.

;; The `spark-ticks' and `spark-vticks' variables hold the
;; characters used to draw the graph for `spark' and `spark-v'
;; respectively.

;; Usage:

;; (require 'spark)
;; (spark '(0 30 55 80 33 150)) => \"▁▂▃▅▂█\"

;;; Code:

(require 'cl-lib)

;;--------------------------------------------------------------------
;; Spark
;;--------------------------------------------------------------------

(defcustom spark-ticks
  [?▁ ?▂ ?▃ ?▄ ?▅ ?▆ ?▇ ?█]
  "A simple-vector of characters for representation of sparklines.
Default is [?▁ ?▂ ?▃ ?▄ ?▅ ?▆ ?▇ ?█].

Examples:

  (defvar ternary '(-1 0 1 -1 1 0 -1 1 -1))

  (spark ternary)              => \"▁▄█▁█▄▁█▁\"

  (let ((spark-ticks (vector ?_ ?- ?¯)))
    (spark ternary))           => \"_-¯_¯-_¯_\"

  (let ((spark-ticks (vector ?▄ ?⎯ ?▀)))
    (spark ternary))           => \"▄⎯▀▄▀⎯▄▀▄\""
  :group 'spark
  :type 'sexp)

;;;###autoload
(cl-defun spark (numbers &key min max key)
  "Generates a sparkline string for a list of real numbers.

Usage: SPARK <numbers> &key <min> <max> <key>

  * <numbers> ::= <list> of <real-number>
  * <min>     ::= { <null> | <real-number> }, default is NIL
  * <max>     ::= { <null> | <real-number> }, default is NIL
  * <key>     ::= <function>

  * <numbers> ~ data.
  * <min>    ~ lower bound of output.
               NIL means the minimum value of the data.
  * <max>    ~ upper bound of output.
               NIL means the maximum value of the data.
  * <key>    ~ function for preparing data.

Examples:

  (spark '(1 0 1 0))     => \"█▁█▁\"
  (spark '(1 0 1 0 0.5)) => \"█▁█▁▄\"
  (spark '(1 0 1 0 -1))  => \"█▄█▄▁\"

  (spark '(0 30 55 80 33 150))                 => \"▁▂▃▅▂█\"
  (spark '(0 30 55 80 33 150) :min -100)       => \"▃▄▅▆▄█\"
  (spark '(0 30 55 80 33 150) :max 50)         => \"▁▅██▅█\"
  (spark '(0 30 55 80 33 150) :min 30 :max 80) => \"▁▁▄█▁█\"

  (spark '(0 1 2 3 4 5 6 7 8) :key (lambda (x) (sin (* x pi (/ 1.0 4)))))
  => \"▄▆█▆▄▂▁▂▄\"
  (spark '(0 1 2 3 4 5 6 7 8) :key (lambda (x) (cos (* x pi (/ 1.0 4)))))
  => \"█▆▄▂▁▂▄▆█\""
  (check-type numbers list)
  (check-type min     (or null real))
  (check-type max     (or null real))
  (check-type key     (or symbol function))
  (when key (setf numbers (mapcar key numbers)))

  ;; Empty data case:
  (when (null numbers)
    (cl-return-from spark ""))

  ;; Ensure min is the minimum number.
  (if (null min)
      (setf min (cl-reduce #'min numbers))
    (setf numbers (mapcar (lambda (n) (max n min)) numbers)))

  ;; Ensure max is the maximum number.
  (if (null max)
      (setf max (cl-reduce #'max numbers))
    (setf numbers (mapcar (lambda (n) (min n max)) numbers)))

  (when (< max min)
    (error "max %s < min %s." max min))

  (let ((unit (/ (- max min) (float (1- (length spark-ticks))))))
    (when (zerop unit) (setf unit 1))
    (with-output-to-string
      (cl-loop for n in numbers
               for nth = (floor (- n min) unit)
               do (princ (char-to-string (aref spark-ticks nth)))))))

;;--------------------------------------------------------------------
;; Spark-V
;;--------------------------------------------------------------------

(defcustom spark-vticks
  [?▏ ?▎ ?▍ ?▌ ?▋ ?▊ ?▉ ?█]
  "A simple-vector of characters for representation of vertical sparklines.
Default is [?▏ ?▎ ?▍ ?▌ ?▋ ?▊ ?▉ ?█].

Examples:

  ;; Japan GDP growth rate, annual
  ;; see:  http://data.worldbank.org/indicator/NY.GDP.MKTP.KD.ZG
  (defvar growth-rate
   '((2007 . 2.192186) (2008 . -1.041636) (2009 . -5.5269766)
     (2010 . 4.652112) (2011 . -0.57031655) (2012 . 1.945)))

  (spark-v growth-rate :key #'cdr :labels (mapcar #'car growth-rate))
  =>
  \"
       -5.5269766        -0.4374323         4.652112
       ˫---------------------+---------------------˧
  2007 ██████████████████████████████████▏
  2008 ███████████████████▊
  2009 ▏
  2010 ████████████████████████████████████████████
  2011 █████████████████████▉
  2012 █████████████████████████████████▏
  \"

  (let ((spark-vticks (vector ?- ?0 ?+)))
    (spark-v growth-rate :key (lambda (y-r) (signum (cdr y-r)))
                        :labels (mapcar #'car growth-rate)
                        :size 1))
  =>
  \"
  2007 +
  2008 -
  2009 -
  2010 +
  2011 -
  2012 +
  \""
  :group 'spark
  :type 'sexp)

;;;###autoload
(cl-defun spark-v
    (numbers &key min max key (size 50) labels title (scale? t) (newline? t))
  "Generates a vertical sparkline string for a list of real numbers.

Usage: SPARK-V <numbers> &key <min> <max> <key> <size>
                             <labels> <title> <scale?> <newline?>

  * <numbers>  ::= <list> of <real-number>
  * <min>      ::= { <null> | <real-number> }, default is NIL
  * <max>      ::= { <null> | <real-number> }, default is NIL
  * <key>      ::= <function>
  * <size>     ::= <integer 1 *>, default is 50
  * <labels>   ::= <list>
  * <title>    ::= <object>, default is NIL
  * <scale?>   ::= <generalized-boolean>, default is T
  * <newline?> ::= <generalized-boolean>, default is T

  * <numbers>  ~ data.
  * <min>      ~ lower bound of output.
                 NIL means the minimum value of the data.
  * <max>      ~ upper bound of output.
                 NIL means the maximum value of the data.
  * <key>      ~ function for preparing data.
  * <size>     ~ maximum number of output columns (contains label).
  * <labels>   ~ labels for data.
  * <title>    ~ If title is too big for size, it is not printed.
  * <scale?>   ~ If T, output graph with scale for easy to see.
                 If string length of min and max is too big for size,
                 the scale is not printed.
  * <newline?> ~ If T, output graph with newlines for easy to see.


Examples:

  ;; Life expectancy by WHO region, 2011, bothsexes
  ;; see. http://apps.who.int/gho/data/view.main.690
  (defvar life-expectancies '((\"Africa\" 56)
                              (\"Americans\" 76)
                              (\"South-East Asia\" 67)
                              (\"Europe\" 76)
                              (\"Eastern Mediterranean\" 68)
                              (\"Western Pacific\" 76)
                              (\"Global\" 70)))

  (spark-v life-expectancies :key #'second :scale? nil :newline? nil)
  =>
  \"▏
  ██████████████████████████████████████████████████
  ███████████████████████████▌
  ██████████████████████████████████████████████████
  ██████████████████████████████▏
  ██████████████████████████████████████████████████
  ███████████████████████████████████▏\"

  (spark-v life-expectancies :min 50 :max 80
                             :key    #'second
                             :labels (mapcar #'first life-expectancies)
                             :title \"Life Expectancy\")
  =>
  \"
                   Life Expectancy
                        50           65           80
                        ˫------------+-------------˧
                 Africa █████▋
              Americans ████████████████████████▎
        South-East Asia ███████████████▉
                 Europe ████████████████████████▎
  Eastern Mediterranean ████████████████▊
        Western Pacific ████████████████████████▎
                 Global ██████████████████▋
  \"

  (spark-v '(0 1 2 3 4 5 6 7 8) :key (lambda (x) (sin (* x pi (/ 1.0 4))))
                                :size 20)
  \"
  -1.0     0.0     1.0
  ˫---------+--------˧
  ██████████▏
  █████████████████▏
  ████████████████████
  █████████████████▏
  ██████████▏
  ██▉
  ▏
  ██▉
  █████████▉
  \"

  (spark-v '(0 1 2 3 4 5 6 7 8) :key (lambda (x) (sin (* x pi (/ 1.0 4))))
                                :size 10)
  =>
  \"
  -1.0   1.0
  ˫--------˧
  █████▏
  ████████▏
  ██████████
  ████████▏
  █████▏
  █▏
  ▏
  █▏
  ████▏
  \"

  (spark-v '(0 1 2 3 4 5 6 7 8) :key (lambda (x) (sin (* x pi (/ 1.0 4))))
                                :size 1)
  =>
  \"
  ▌
  ▊
  █
  ▊
  ▌
  ▎
  ▏
  ▎
  ▌
  \""

  (check-type numbers  list)
  (check-type min      (or null real))
  (check-type max      (or null real))
  (check-type key      (or symbol function))
  (check-type size     (integer 1 *))
  (check-type labels   list)

  (when key (setf numbers (mapcar key numbers)))

  ;; Empty data case:
  (when (null numbers)
    (cl-return-from spark-v ""))

  ;; Ensure min is the minimum number.
  (if (null min)
      (setf min (cl-reduce #'min numbers))
    (setf numbers (mapcar (lambda (n) (max n min)) numbers)))

  ;; Ensure max is the maximum number.
  (if (null max)
      (setf max (cl-reduce #'max numbers))
    (setf numbers (mapcar (lambda (n) (min n max)) numbers)))

  ;; Check max ~ min.
  (cond ((< max min) (error "max %s < min %s." max min))
        ((= max min) (incf max))        ; ensure all bars are in min.
        (t nil))

  (let ((max-lengeth-label nil))
    (when labels
      ;; Ensure num labels equals to num numbers.
      (let ((diff (- (length numbers) (length labels))))
        (cond ((plusp diff)
               ;; Add padding lacking labels not to miss data.
               (setf labels (append labels (cl-loop repeat diff collect ""))))
              ((minusp diff)
               ;; Remove superfluous labels to remove redundant spaces.
               (setf labels (butlast labels (abs diff))))
              (t nil)))
      ;; Find max-lengeth-label.
      (setf max-lengeth-label
            (cl-reduce #'max labels
                       :key (lambda (label)
                              (if (stringp label)
                                  (length label)
                                (length (format "%s" label))))))

      ;; ;; Canonicalize labels.
      (let* ((control-string (format "%%0%ds " max-lengeth-label)))
        (setf labels
              (mapcar (lambda (label) (format control-string label))
                      labels)))

      ;; Reduce size for max-lengeth-label.
      ;;  * 1 is space between label and bar
      ;;  * ensure minimum size 1
      (setf size (max 1 (- size 1 max-lengeth-label))))

    (let* ((num-content-ticks (1- (length spark-vticks)))
           (unit (/ (float (- max min)) (* size num-content-ticks)))
           (result '()))
      (when (zerop unit) (setf unit 1))

      (cl-loop for n in numbers
               for i from 0
               do (when labels (push (nth i labels) result))
               (push (spark--generate-bar n unit min max num-content-ticks)
                     result)
               finally (setf result (nreverse result)))

      (when scale?
        (let ((it (spark--generate-scale min max size max-lengeth-label)))
          (when it (push it result))))

      (when title
        (let ((it (spark--generate-title title size max-lengeth-label)))
          (when it (push it result))))

      (if newline?
          (apply 'concat (push (char-to-string ?\n) result))
        ;; string-right-trim
        (replace-regexp-in-string (rx (* (any " \t\n")) eos)
                                  ""
                                  (apply 'concat result))))))

(defun spark--generate-bar (number unit min max num-content-ticks)
  (multiple-value-bind
      (units frac) (cl-floor (- number min) (* unit num-content-ticks))
    (with-output-to-string
      (let ((most-tick (aref spark-vticks num-content-ticks)))
        (dotimes (_ units) (princ (char-to-string most-tick)))
        (unless (= number max)
          ;; max number need not frac.
          ;; if number = max, then always frac = 0.
          (princ (char-to-string (aref spark-vticks (floor frac unit)))))
        (terpri)))))

(defun spark--generate-title (title size max-lengeth-label)
  (let* ((title-string (format "%s" title))
         (mid (floor (- (if max-lengeth-label
                            (+ 1 size max-lengeth-label)
                          size)
                        (length title-string)) 2)))
    (when (plusp mid)
      (format "%s\n"
              (cl-replace (make-string (if max-lengeth-label
                                           (+ 1 size max-lengeth-label)
                                         size)
                                       ?\s)
                          title-string :start1 mid)))))

(defun spark--justify-space-lengths (num-spaces num-elements)

  (if (<= num-elements 1)
      nil
    (let* ((lengths (make-list (1- num-elements) 0)))
      (cl-loop repeat num-spaces
               with n = 0
               do (progn
                    (incf (nth n lengths))
                    (if (< n (1- (1- num-elements)))
                        (incf n)
                      (setf n 0))))
      lengths)))

(defun spark--justify-interleave-spaces (strs spaces)
  (cond ((and (eql strs nil) (eql spaces nil)) nil)
        ((eql strs nil) (cons nil (spark--justify-interleave-spaces spaces strs))) ;; rule #2, current value is nil
        (t (cons (first strs) (spark--justify-interleave-spaces spaces (rest strs))))))

(defun spark--justify-strings (mincol strs &optional padchar)
  (let* ((padchar (or padchar 32))
         (leftover-space (- mincol
                            (length (apply #'concatenate 'string strs))))
         (spaces (mapcar (lambda (l)
                           (make-string l padchar))
                         (spark--justify-space-lengths leftover-space (length strs)))))
    (apply #'concatenate 'string (spark--justify-interleave-spaces strs spaces))))

(defun spark--generate-scale (min max size max-lengeth-label)
  (let* ((min-string  (number-to-string min))
         (max-string  (number-to-string max))
         (num-padding (- size (length min-string) (length max-string))))
    (when (plusp num-padding)
      (let* ((mid        (/ (+ max min) 2.0))
             (mid-string (number-to-string mid))
             (num-indent (if max-lengeth-label (1+ max-lengeth-label) 0)))
        (if (and (< (length mid-string) num-padding)
                 (/= min mid)
                 (/= mid max))
            ;; A. mid exist case:
            (format "%s%s\n%s%s\n"
                    (make-string num-indent 32)
                    (spark--justify-strings size
                                            (list min-string
                                                  mid-string
                                                  max-string))
                    (make-string num-indent 32)
                    (spark--justify-strings size
                                            (list (char-to-string 747)
                                                  "+"
                                                  (char-to-string 743))
                                            ?\-))
          ;; B. no mid exist case:
          (format "%s%s\n%s%s\n"
                  (make-string num-indent 32)
                  (spark--justify-strings size
                                          (list min-string
                                                max-string))
                  (make-string num-indent 32)
                  (spark--justify-strings size
                                          (list (char-to-string 747)
                                                (char-to-string 743))
                                          ?\-)))))))

(provide 'spark)

;;; spark.el ends here
