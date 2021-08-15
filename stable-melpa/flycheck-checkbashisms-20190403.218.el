;;; flycheck-checkbashisms.el --- checkbashisms checker for flycheck -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Cuong Le
;; All rights reserved.

;; Author: Cuong Le <cuong.manhle.vn@gmail.com>
;; Keywords: convenience, tools, sh, unix
;; Package-Version: 20190403.218
;; Package-Commit: 53598158fa8b74d2e7efea6210edb274e1f0273c
;; Version: 1.4-git
;; URL: https://github.com/cuonglm/flycheck-checkbashisms
;; Package-Requires: ((emacs "24") (flycheck "0.25"))

;; This file is not part of GNU Emacs.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:

;;     * Redistributions of source code must retain the above copyright
;;       notice, this list of conditions and the following disclaimer.

;;     * Redistributions in binary form must reproduce the above
;;       copyright notice, this list of conditions and the following
;;       disclaimer in the documentation and/or other materials provided
;;       with the distribution.

;;     * Neither the name of the @organization@ nor the names of its
;;       contributors may be used to endorse or promote products derived
;;       from this software without specific prior written permission.

;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL LE MANH CUONG
;; BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
;; BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
;; OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
;; IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; A flycheck linter for sh script using checkbashisms

;;; Code:

(require 'flycheck)

(defgroup flycheck-checkbashisms nil
  "checkbashisms intergrate with flycheck"
  :prefix "flycheck-checkbashisms"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/cuonglm/flycheck-checkbashisms"))

;; Variables used in other modes
(defvar sh-shell)                       ; From sh-script, for shell checker predicate

(flycheck-def-option-var flycheck-checkbashisms-newline nil sh-checkbashisms
  "Check for 'echo -n' usage"
  :safe #'booleanp
  :type 'boolean)

(flycheck-def-option-var flycheck-checkbashisms-posix nil sh-checkbashisms
  "Check non POSIX issues but required by Debian Policy 10.4
Enable this also make `flycheck-checkbashisms-newline' effects"
  :safe #'booleanp
  :type 'boolean)

(flycheck-define-checker sh-checkbashisms
  "A linter for sh script.
See URL: `https://anonscm.debian.org/cgit/collab-maint/devscripts.git/tree/scripts/checkbashisms.pl'"
  :command ("checkbashisms"
            "-f"
            (option-flag "-n" flycheck-checkbashisms-newline)
            (option-flag "-p" flycheck-checkbashisms-posix)
            "-")
  :standard-input t
  :error-patterns
  ((error line-start
          (one-or-more not-newline) " line " line " " (message) ":"
          line-end))
  :modes sh-mode
  :predicate (lambda () (eq sh-shell 'sh))
  :verify (lambda (_)
            (let ((bin-sh-p (eq sh-shell 'sh)))
              (list
               (flycheck-verification-result-new
                :label (format "Check shell %s" sh-shell)
                :message (if bin-sh-p "yes" "no")
                :face (if bin-sh-p 'success '(bold warning)))))))

;;;###autoload
(defun flycheck-checkbashisms-setup ()
  "Setup Flycheck checkbashisms.
Add `sh-checkbashisms' to the end of `flycheck-checkers'."
  (interactive)
  (add-to-list 'flycheck-checkers 'sh-checkbashisms t)
  (mapc (lambda (checker)
          (flycheck-add-next-checker checker '(warning . sh-checkbashisms) 'append))
        '(sh-posix-dash
          sh-posix-bash
          sh-shellcheck)))

(provide 'flycheck-checkbashisms)
;;; flycheck-checkbashisms.el ends here
