;;; earthfile-mode.el --- Major mode for editing Earthly file -*- lexical-binding: t -*-

;; Author: Thanabodee Charoenpiriyakij <wingyminus@gmail.com>
;; URL: https://github.com/earthly/earthly-mode
;; Package-Version: 20210903.230
;; Package-Commit: 0f24876223a358d2718383e9e4975a26cee55f9d
;; Version: 0.1.0
;; Package-Requires: ((emacs "26"))
;; SPDX-License-Identifier: MPL-2.0

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This package provides syntax highlight and toggle comment support
;; for Earthly files.

;;; Code:

(defconst earthfile-keywords-regexp
  (rx line-start
      (* space)
      (or "FROM"
	  "RUN"
	  "COPY"
	  "ARG"
	  "SAVE ARTIFACT"
	  "SAVE IMAGE"
	  "BUILD"
	  "VERSION"
	  "GIT CLONE"
	  "CMD"
	  "LABEL"
	  "EXPOSE"
	  "ENV"
	  "ENTRYPOINT"
	  "VOLUME"
	  "USER"
	  "WORKDIR"
	  "HEALTHCHECK NONE"
	  "HEALTHCHECK CMD"
	  "FROM DOCKERFILE"
	  "WITH DOCKER"
	  "IF"
	  "ELSE"
	  "ELSE IF"
	  "FOR"
	  "END"
	  "LOCALLY"
	  "COMMAND"
	  "DO"
	  "IMPORT")
      (or (+ space) line-end))
  "All Earthfile keywords.")

(defconst earthfile-variable-regexp
  (rx (sequence "$" (? "{") (+ (in (?A . ?Z) (?a . ?z) (?0 . ?9) ?- ?_)) (? "}")))
  "Regular Expression for Earthfile variable.")

(defconst earthfile-for-keyword-regexp
  (rx line-start (* space) (group "FOR") word-boundary (*? (regex ".")) word-boundary (group "IN") word-boundary)
  "Regular Expression for Earthfile FOR .. IN syntax.")

(defconst earthfile-save-artifact-keyword-regexp
  (rx line-start (* space) (group "SAVE ARTIFACT") word-boundary (*? (regex ".")) word-boundary (group "AS LOCAL") word-boundary)
  "Regular Expression for Earthfile SAVE ARTIFACT .. AS LOCAL syntax.")

(defun earthfile-build-font-lock-keywords ()
  "Build font lock for Earthfile syntax."
  (list
    `(,earthfile-keywords-regexp . font-lock-keyword-face)
    `(,earthfile-variable-regexp . font-lock-variable-name-face)
    `(,earthfile-for-keyword-regexp (1 font-lock-keyword-face) (2 font-lock-keyword-face))
    `(,earthfile-save-artifact-keyword-regexp (1 font-lock-keyword-face) (2 font-lock-keyword-face))))

(defvar earthfile-syntax-table
  (let ((syntax-table (make-syntax-table)))
    (modify-syntax-entry ?\# "<" syntax-table)
    (modify-syntax-entry ?\n ">" syntax-table)
    (modify-syntax-entry ?\" "\"" syntax-table)
    (modify-syntax-entry ?\' "\"" syntax-table)
    syntax-table)
  "Syntax table for `earthfile-mode'.")

;;;###autoload
(define-derived-mode earthfile-mode prog-mode "Earthfile"
  "A major mode for editing Earthfile file."
  :syntax-table earthfile-syntax-table
  (setq-local comment-start "#")
  (setq-local comment-end "")
  (setq-local font-lock-defaults '(earthfile-build-font-lock-keywords)))

;;;###autoload
(progn
  (add-to-list 'auto-mode-alist '("Earthfile\\'" . earthfile-mode))
  (add-to-list 'auto-mode-alist '("\\.earth\\'" . earthfile-mode)))

(provide 'earthfile-mode)

;;; earthfile-mode.el ends here
