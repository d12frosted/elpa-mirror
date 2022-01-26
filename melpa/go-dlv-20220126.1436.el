;;; go-dlv.el --- Go Delve - Debug Go programs interactively with the GUD.

;; Copyright (C) 2015, 2019 Marko Bencun

;; Author: Marko Bencun <mbencun@gmail.com>
;; URL: https://github.com/benma/go-dlv.el/
;; Package-Version: 20220126.1436
;; Package-Commit: 0a296bc3b7b4dcf0c140a78c5ca3e1a8c6b7ea1a
;; Version: 0.6
;; Package-Requires: ((go-mode "1.3.1"))
;; Keywords: Go, debug, debugger, delve, interactive, gud

;; This file is part of go-dlv.

;; go-dlv is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; go-dlv is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with go-dlv.  If not, see <http://www.gnu.org/licenses/>.

;;; Installation

;; If you are using Emacs 24 or later, you can get go-dlv from [melpa](https://melpa.org/) with the package manager.
;; Add the following code to your init file.
;; ----------------------------------------------------------
;; (add-to-list 'load-path "folder-in-which-go-dlv-files-are-in/") ;; if the files are not already in the load path
;; (require 'go-dlv)
;; ----------------------------------------------------------

;;; Code:

;; The code below is based on gud's pdb debugger, adapted to dlv:
;; https://github.com/emacs-mirror/emacs/blob/8badbad184c75d6a9b17b72900ca091a1bd11397/lisp/progmodes/gud.el#L1594-1698

(require 'gud)
(require 'go-mode)

;; Sample marker lines:
;; > main.main() ./test.go:10 (hits goroutine(5):1 total:1)
;; > [unrecovered-panic] runtime.fatalpanic() /usr/lib/golang/src/runtime/panic.go:681 (hits goroutine(16):1 total:1) (PC: 0x435140)
;; Frame 2: /usr/lib/golang/src/testing/testing.go:792 (PC: 50fc82)
(defvar go-dlv-marker-regexp
  "^\\(?:\\(?:> .+?(.*?) \\)\\|\\(?:Frame [0-9]+: \\)\\)\\(.+?\\)\\:\\([0-9]+\\)")

(defvar go-dlv-marker-regexp-file-group 1)
(defvar go-dlv-marker-regexp-line-group 2)

(defvar go-dlv-marker-regexp-start "^> ")

(defvar go-dlv-marker-acc "")
(make-variable-buffer-local 'go-dlv-marker-acc)

;; There's no guarantee that Emacs will hand the filter the entire
;; marker at once; it could be broken up across several strings.  We
;; might even receive a big chunk with several markers in it.  If we
;; receive a chunk of text which looks like it might contain the
;; beginning of a marker, we save it here between calls to the
;; filter.
(defun go-dlv-marker-filter (string)
  (setq go-dlv-marker-acc (concat go-dlv-marker-acc string))
  (let ((output ""))
    ;; Process all the complete markers in this chunk.
    (while (string-match go-dlv-marker-regexp go-dlv-marker-acc)
      (setq

       ;; Extract the frame position from the marker.
       gud-last-frame
       (let ((file (match-string go-dlv-marker-regexp-file-group
                                 go-dlv-marker-acc))
             (line (string-to-number
                    (match-string go-dlv-marker-regexp-line-group
                                  go-dlv-marker-acc))))
         (cons file line))

       ;; Output everything instead of the below
       output (concat output (substring go-dlv-marker-acc 0 (match-end 0)))
       ;;	  ;; Append any text before the marker to the output we're going
       ;;	  ;; to return - we don't include the marker in this text.
       ;;	  output (concat output
       ;;		      (substring go-dlv-marker-acc 0 (match-beginning 0)))

       ;; Set the accumulator to the remaining text.
       go-dlv-marker-acc (substring go-dlv-marker-acc (match-end 0))))

    ;; Does the remaining text look like it might end with the
    ;; beginning of another marker?  If it does, then keep it in
    ;; go-dlv-marker-acc until we receive the rest of it.  Since we
    ;; know the full marker regexp above failed, it's pretty simple to
    ;; test for marker starts.
    (if (string-match go-dlv-marker-regexp-start go-dlv-marker-acc)
        (progn
          ;; Everything before the potential marker start can be output.
          (setq output (concat output (substring go-dlv-marker-acc
                                                 0 (match-beginning 0))))

          ;; Everything after, we save, to combine with later input.
          (setq go-dlv-marker-acc
                (substring go-dlv-marker-acc (match-beginning 0))))

      (setq output (concat output go-dlv-marker-acc)
            go-dlv-marker-acc ""))

    output))

(define-obsolete-variable-alias 'go-dlv-command-name
  'gud-dlv-command-name
  "0.4")

(defcustom gud-dlv-command-name "dlv"
  "File name for executing the Go Delve debugger.
This should be an executable on your path, or an absolute file name."
  :type 'string
  :group 'gud)

;;;###autoload
(defun dlv (command-line)
  "Run dlv on program FILE in buffer `*gud-FILE*'.
The directory containing FILE becomes the initial working directory
and source-file directory for your debugger."
  (interactive
   (list (gud-query-cmdline 'dlv "debug")))

  (gud-common-init command-line nil 'go-dlv-marker-filter)
  (set (make-local-variable 'gud-minor-mode) 'dlv)

  (gud-def gud-break  "break %d%f:%l"    "\C-b" "Set breakpoint at current line.")
  (gud-def gud-trace  "trace %d%f:%l"    "\C-t" "Set trace at current line.")
  (gud-def gud-remove "clearall %d%f:%l" "\C-d" "Remove breakpoint at current line")
  (gud-def gud-step   "step"             "\C-s" "Step one source line with display.")
  (gud-def gud-finish "stepout"          "\C-f" "Finish executing current function.")
  (gud-def gud-next   "next"             "\C-n" "Step one line (skip functions).")
  (gud-def gud-cont   "continue"         "\C-r" "Continue running program.")
  (gud-def gud-until  "continue %d%f:%l" "\C-u" "Continue to current line.")
  (gud-def gud-print  "print %e"         "\C-p" "Evaluate Go expression at point.")
  (gud-def gud-watch  "display -a %e"    "\C-w" "Print expression at point on every step.")
  (gud-def gud-up     "up %p"            "<"    "Up N stack frames (numeric arg).")
  (gud-def gud-down   "down %p"          ">"    "Down N stack frames (numeric arg).")

  (setq comint-prompt-regexp "^(Dlv) *")
  (setq paragraph-start comint-prompt-regexp)
  (run-hooks 'go-dlv-mode-hook))

;;;###autoload
(defun dlv-current-func ()
  "Debug the current program or test stopping at the beginning of the current function."
  (interactive)
  (let (current-test-name current-bench-name current-func-loc)
    ;; find the location of the current function and (if it is a test function) its name
    (save-excursion
      (when (go-beginning-of-defun)
        (setq current-func-loc (format "%s:%d" buffer-file-name (line-number-at-pos)))
        ;; Check for Test or Benchmark function, set current-test-name/current-bench-name
        (when (looking-at go-func-regexp)
          (let ((func-name (match-string 1)))
            (when (string-match-p "_test\.go$" buffer-file-name)
              (cond
               ((string-match-p "^Test\\|^Example" func-name)
                (setq current-test-name func-name))
               ((string-match-p "^Benchmark" func-name)
                (setq current-bench-name func-name))))))))

    (if current-func-loc
        (let (gud-buffer-name dlv-command)
          (cond
           (current-test-name
            (setq gud-buffer-name "*gud-test*")
            (setq dlv-command (concat gud-dlv-command-name " test -- -test.run " current-test-name)))
           (current-bench-name
            (setq gud-buffer-name "*gud-test*")
            (setq dlv-command (concat gud-dlv-command-name " test -- -test.run='^$' -test.bench=" current-bench-name)))
           (t
            (setq gud-buffer-name "*gud-debug*")
            (setq dlv-command (concat gud-dlv-command-name " debug"))))

          ;; stop the current active dlv session if any
          (let ((gud-buffer (get-buffer gud-buffer-name)))
            (when gud-buffer (kill-buffer gud-buffer)))

          ;; run dlv and stop at the beginning of the current function
          (dlv dlv-command)
          (gud-call (format "break %s" current-func-loc))
          (gud-call "continue"))
      (error "Not in function"))))

(provide 'go-dlv)

;;; go-dlv.el ends here
