;;; bpftrace-mode.el --- Major mode for editing bpftrace script files -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Jay Kamat <jaygkamat@gmail.com>

;; Author: Jay Kamat <jaygkamat@gmail.com>
;; Maintainer: Jay Kamat <jaygkamat@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20190608.2201
;; Package-Commit: 587b39ea7a1d786df5c04796d51bf2a5a4eda0d7
;; Keywords: highlight, c
;; URL: http://gitlab.com/jgkamat/bpftrace-mode
;; Package-Requires: ((emacs "24.0"))

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

;; bpftrace-mode is a simple mode for editing bpftrace files:
;;
;; https://github.com/iovisor/bpftrace
;;
;; bpftrace-mode builds atop of cc-mode for indentation and syntax highlighting.

;;; Code:

(require 'cc-mode)

(defvar bpftrace-mode-map (make-sparse-keymap)
  "Keymap for `bpftrace-mode' buffers.")

(defvar bpftrace-mode-syntax-table
  (let ((table (make-syntax-table c-mode-syntax-table)))
    ;; TODO possibly add syntax table mods
    table)
  "Syntax table for `bpftrace-mode'.")

;; Codification of bpftrace mode keywords
(defvar bpftrace-mode-font-lock-keywords
  (append
   `(

     ;; Builtins
     ;; http://github.com/iovisor/bpftrace/blob/master/docs/reference_guide.md#1-builtins
     (,(rx bow (or "pid" "tid" "uid" "gid" "nsecs" "elapsed" "cpu" "comm" "kstack" "ustack"
                   (and "arg" (1+ digit))
                   "retval" "func" "probe" "curtask" "rand" "cgroup"
                   (and "$" (1+ digit)))
           eow)
      . font-lock-keyword-face)

     ;; Global/per-thread variables
     (,(rx bow (or (and "$" word) "@") (0+ word) eow) . font-lock-variable-name-face)
     ;; General Functions
     ;; TODO properly handle coloring of overloaded symbols like ustack
     (,(rx bow
           (or "printf" "time" "join" "str" "ksym" "usym" "kaddr" "uaddr" "reg" "system"
               "exit" "cgroupid" "kstack" "ustack" "ntop" "cat")
           eow)
      . font-lock-builtin-face)
     ;; Map Functions
     (,(rx bow
           (or "count" "sum" "avg" "min" "max" "stats" "hist" "lhist"
               "delete" "print" "clear" "zero")
           eow)
      . font-lock-builtin-face)
     ;; Ouptut functions
     (,(rx bow (or "printf" "interval" "hist") eow)
      . font-lock-builtin-face)
     ;; Probes
     (,(rx bow
           (or "BEGIN" "END"
               "kprobe" "kretprobe"
               "uprobe" "uretprobe"
               "tracepoint" "usdt"
               ;; TODO what to do about shortforms?
               "t" "k" "kr" "u" "ur" "p" "h" "s" "i"
               "profile" "interval"
               "software" "hardware")
           eow)
      . font-lock-constant-face)
     )
   ;; Also add normal c keywords
   c-font-lock-keywords)
  "First level font lock keywords for `bpftrace-mode'.")

;;;###autoload
(define-derived-mode bpftrace-mode c-mode "bpftrace"
  "Major mode for editing bpftrace script files."
  ;; TODO support higher levels of syntax highlighting
  (setq font-lock-defaults
        '(bpftrace-mode-font-lock-keywords
          nil nil
          ((?_ . "w") (?$ . "w") (?@ . "w"))))
  (use-local-map bpftrace-mode-map))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.bt\\'" . bpftrace-mode))

(provide 'bpftrace-mode)

;;; bpftrace-mode.el ends here
