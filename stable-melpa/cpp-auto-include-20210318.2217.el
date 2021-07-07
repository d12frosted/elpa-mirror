;;; cpp-auto-include.el --- Insert and delete C++ header files automatically

;; Copyright (C) 2015 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/emacsorphanage/cpp-auto-include
;; Package-Version: 20210318.2217
;; Package-Commit: 0ce829f27d466c083e78b9fe210dcfa61fb417f4
;; Version: 0.2.0
;; Package-Requires: ((cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provided the command `cpp-auto-include', which
;; automatically adds the needed C++ header files and/or removes
;; those that are no longer needed.

;;; Code:

(require 'cl-lib)
(require 'rx)

(defvar cpp-auto-include--header-regexp
  `(("cstdio" nil t
     ,(rx (and symbol-start
               (or  (and (or "scanf" "sscanf" "puts" "sprintf" "printf"
                             "gets" "fgets" "putchar")
                         (* space) "(")
                    (and  (or "FILE" "stdin" "stdout" "stderr")
                          symbol-end)))))
    ("cassert" nil t "\\bassert\\s-+(")
    ("cstring" nil t
     ,(rx (and symbol-start
               (or "memcpy" "memset" "memcmp" "memncmp"
                   "strlen" "strcmp" "strncmp" "strcpy" "strncpy" "strerr" "strcat"
                   "strstr" "strchr")
               symbol-end)))
    ("cstdlib" nil t
     ,(rx (and symbol-start
               (or (and (or "system" "abs" "atoi" "atof" "itoa"
                            "strtod" "strtold" "strtoul" "strtof" "strtol"
                            "strtoll" "strtoull" "strtoq" "strtouq"
                            "free" "exit" "labs" "srand" "srandom" "srandom_r"
                            "rand" "rand_r" "random" "random_r" "qsort")
                        (* space) "(")
                   (and (or (and "EXIT_" (1+ (in "A-Z")))
                            "NULL"))))))
    ("cmath" nil t
     ,(rx (and symbol-start
               (or (and (or "powf" "powl"
                            "acos" "acosf" "acosh" "acoshf" "acoshl" "acosl"
                            "asin" "asinf" "asinh" "asinhf" "asinhl" "asin"
                            "atan" "atan2" "atan2f" "atan2l" "atanf" "atanh" "atanhf"
                            "atanhl" "atanl" "exp" "expf" "expl" "exp10" "exp10f"
                            "exp10l" "exp2" "exp2f" "exp2l" "expm1" "expm1f" "expm1l"
                            "fabs" "fabsf" "fabsl" "log" "logf" "logl"
                            "log2" "log2f" "log2l" "log10" "log10f" "log10l" "log1p"
                            "log1pf" "log1pl" "nan" "nanf" "nanl"
                            "ceil" "ceilf" "ceill" "floor" "floorf" "floorl"
                            "round" "roundf" "roundl" "lround" "lroundf" "lroundl"
                            "llround" "llroundf" "llroundl" "sqrt" "sqrtf" "sqrtl")
                        (* space) "(")
                   (and (or "NAN" "INFINITY" "HUGE_VAL" "HUGE_VALF" "HUGE_VALL")
                        symbol-end)))))
    ("strings.h" nil t
     ,(rx (and symbol-start
               (or "bcmp" "bcopy" "bzero" "strcasecmp" "strncasecmp")
               (* space) "(")))
    ("typeinfo" nil t "\\btypeid\\b")
    ("new" t t ,(rx (and symbol-start
                         (or "set_new_handler" "nothrow")
                         (* space) "(")))
    ("limits" t t "\\bnumeric_limits\\s-*<\\b")
    ("algorithm" t t
     ,(rx (and symbol-start
               (or "sort" "stable_sort" "partial_sort" "partial_sort_copy"
                   "unique" "unique_copy" "reverse" "reverse_copy"
                   "nth_element" "lower_bound" "upper_bound" "binary_search"
                   "next_permutation" "prev_permutation"
                   "min" "max" "count" "random_shuffle" "swap" "transform")
               (* space) "(")))
    ("numeric" t t
     ,(rx (and symbol-start
               (or "partial_sum" "accumulate" "adjacent_difference" "inner_product")
               (* space) "(")))
    ("iostream" t t ,(rx (and symbol-start
                              (or "cin" "cout" "cerr")
                              symbol-end)))
    ("sstream" t t ,(rx (and symbol-start
                             (or "stringstream" "istringstream" "ostringstream")
                             symbol-end)))
    ("bitset" t t "\\bbitset\\s-*<\\b")
    ("complex" t t "\\bcomplex\\s-*<\\b")
    ("deque" t t "\\bdeque\\s-*<\\b")
    ("queue" t t ,(rx (and symbol-start
                           (or "queue" "priority_queue")
                           (* space) "<" word-boundary)))
    ("list" t t "\\blist\\s-*<")
    ("map" t t ,(rx (and symbol-start
                         (or "map" "multimap")
                         (* space) "<" word-boundary)))
    ("set" t t ,(rx (and symbol-start
                         (or "set" "multiset")
                         (* space) "<" word-boundary)))
    ("vector" t t "\\bvector\\s-*<")
    ("iomanip" t t ,(rx (and symbol-start
                             (or (and (or "setprecision" "setbase" "setw")
                                      (* space) "(")
                                 (and (or "fixed" "hex")
                                      symbol-end)))))
    ("fstream" t t "\\bfstream\\s-*<")
    ("ctime" nil t ,(rx (and symbol-start
                             (or (and (or "time" "clock")
                                      (* space) "(")
                                 (and (or "fixed" "hex")
                                      symbol-end)))))
    ("string" t t "\\bstring\\b")
    ("utility" t t "\\b\\(?:pair\\s-*<\\|make_pair\\)")))

(defun cpp-auto-include--include-line (header)
  (save-excursion
    (goto-char (point-min))
    (and (re-search-forward (concat "<" header ">") nil t)
         (line-number-at-pos))))

(defsubst cpp-auto-include--in-string-or-comment-p ()
  (nth 8 (syntax-ppss)))

(defun cpp-auto-include--has-keyword-p (regexp line)
  (save-excursion
    (goto-char (point-min))
    (when line
      (forward-line line))
    (let (finish)
      (while (and (not finish) (re-search-forward regexp nil t))
        (unless (cpp-auto-include--in-string-or-comment-p)
          (setq finish t)))
      finish)))

(defun cpp-auto-include--parse-file ()
  (cl-loop with use-std = nil
           with added = nil
           with removed = nil
           with case-fold-search = nil
           for info in cpp-auto-include--header-regexp
           for header = (nth 0 info)
           for regexp = (nth 3 info)
           for included-line = (cpp-auto-include--include-line header)
           for has-keyword = (cpp-auto-include--has-keyword-p regexp included-line)

           when (and (not use-std) has-keyword)
           do (setq use-std t)

           do
           (cond ((and has-keyword (not included-line))
                  (cl-pushnew header added :test 'equal))
                 ((and included-line (not has-keyword))
                  (cl-pushnew (cons header included-line) removed :test 'equal)))

           finally
           return (list :use-std use-std
                        :added added :removed removed)))

(defun cpp-auto-include--header-files ()
  (save-excursion
    (goto-char (point-min))
    (let ((re "^\\s-*#\\s-*include\\s-*<\\([^>]+\\)>")
          headers)
     (while (re-search-forward re nil t)
       (cl-pushnew (match-string-no-properties 1) headers :test 'equal))
     headers)))

(defun cpp-auto-include--header-insert-point ()
  (save-excursion
    (goto-char (point-max))
    (when (re-search-backward "^#\\s-*include\\s-*[<\"]" nil t)
      (forward-line 1)
      (point))))

(defun cpp-auto-include--add-headers (headers)
  (save-excursion
    (let ((insert-point (or (cpp-auto-include--header-insert-point) (point-min))))
      (goto-char insert-point)
      (dolist (header headers)
        (insert (format "#include <%s>\n" header)))
      (unless (re-search-forward "^\\s-*$" (line-end-position) t)
        (insert "\n")))))

(defun cpp-auto-include--remove-headers (headers)
  (save-excursion
    (cl-loop with deleted-lines = 0
             initially (goto-char (point-min))
             for (header . line) in (sort headers (lambda (a b) (< (cdr a) (cdr b))))
             for curline = 1 then (line-number-at-pos)
             do
             (progn
               (forward-line (- line curline deleted-lines))
               (let ((beg (point)))
                 (forward-line 1)
                 (delete-region beg (point))
                 (cl-incf deleted-lines))))))

;;;###autoload
(defun cpp-auto-include ()
  "Insert needed C++ headers and remove unneeded headers."
  (interactive)
  (let* ((info (cpp-auto-include--parse-file))
         (added (plist-get info :added))
         (removed (plist-get info :removed)))
    (when removed
      (cpp-auto-include--remove-headers removed))
    (when added
      (cpp-auto-include--add-headers added))))

(provide 'cpp-auto-include)

;;; cpp-auto-include.el ends here
