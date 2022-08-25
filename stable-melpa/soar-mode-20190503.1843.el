;;; soar-mode.el --- A major mode for the Soar language

;; Version: 0.1
;; Package-Version: 20190503.1843
;; Package-Commit: ebb79789cd35530aea2c6d0eb4f4b280e97107d4
;; Keywords: languages, soar
;; URL: https://github.com/adeschamps/soar-mode

;;; License:

;; BSD 3-Clause License
;;
;; Copyright (c) 2019, Anthony Deschamps
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;;
;; * Redistributions of source code must retain the above copyright notice, this
;;   list of conditions and the following disclaimer.
;;
;; * Redistributions in binary form must reproduce the above copyright notice,
;;   this list of conditions and the following disclaimer in the documentation
;;   and/or other materials provided with the distribution.
;;
;; * Neither the name of the copyright holder nor the names of its
;;   contributors may be used to endorse or promote products derived from
;;   this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; This package provides syntax highlighting and indentation for the
;; Soar language (https://soar.eecs.umich.edu/).

;;; Code:

(defcustom soar-mode-tab-width
  4
  "Default tab width inside productions."
  :type 'integer
  :group 'soar-mode)

(defconst soar-mode-font-lock-keywords
  "\\b\\(source\\|sp\\|state\\)\\b")

(defconst soar-font-lock-keywords
  (list
   '("\\$[^ \.]+"                     . font-lock-preprocessor-face)  ;; $OUTPUT-LINK
   (list soar-mode-font-lock-keywords 1 font-lock-keyword-face)       ;; keywords
   '("#[^\n]*"                        . font-lock-comment-face)       ;; # comment
   '("\\^[^ ]+"                       . font-lock-variable-name-face) ;; ^this.that
   '("<[^>]+>"                        . font-lock-constant-face)      ;; <s>
   '("\\[ *\\([^ ]+\\)"               1 font-lock-function-name-face) ;; [ngs-tag ... ]
   )
  "Highlighting expressions for Soar mode.")

(defvar soar-font-lock-keywords soar-font-lock-keywords-1
  "Highlighting for Soar mode.")

(defun soar-indent-line ()
  "Indent current line as Soar code."
  (interactive)
  (save-excursion
    (back-to-indentation)
    (indent-line-to
     (cond
      ((bobp)             0)
      ((looking-at "sp")  0)
      ((looking-at "-->") 0)
      ((looking-at "\(")  soar-mode-tab-width)
      ((looking-at "\\[") soar-mode-tab-width)
      ((looking-at "-?\\^") (- (save-excursion (forward-line -1) (beginning-of-line)
                                               (if (looking-at "^[^^]+\\(\\^\\)")
                                                   (- (match-beginning 1) (match-beginning 0)) 0))
                               (if (looking-at "-") 1 0)))
      (t 0))))
  (if (bolp) (back-to-indentation)))

(defun soar-blank-line-p ()
  "Predicate to test whether a line is empty."
  (= (current-indentation)
     (- (line-end-position) (line-beginning-position))))

(define-derived-mode soar-mode prog-mode "Soar"
  "Major mode for editing Soar files"
  (setq font-lock-defaults '(soar-font-lock-keywords))
  (setq indent-line-function 'soar-indent-line)
  (setq font-lock-keywords-only t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.soar\\'" . soar-mode))

(provide 'soar-mode)
;;; soar-mode.el ends here
