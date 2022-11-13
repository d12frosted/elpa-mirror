;;; ob-lurk.el --- Evaluate lurk code blocks in org mode -*- lexical-binding: t; -*-
;; Authors: Jeff Weiss <jweiss@protocol.ai>
;; Maintainer: Jeff Weiss <jweiss@protocol.ai>
;; URL: http://github.com/lurk-lang/lurk-emacs
;; Package-Version: 20221107.1338
;; Package-Commit: b341ffbf5959bbbc7dd33b35e207ce8b7bfbf565
;; Keywords: languages lurk lisp
;; Version: 0.1.3
;; SPDX-License-Identifier: Apache-2.0 AND MIT
;; Package-Requires: ((emacs "25.1") (lurk-mode "0.1.2"))

;;; Commentary:

;;  Requires that the variable `lurk-executable' be set to point to
;;  the binary build of lurk.  When you execute a babel code block with
;;  type `lurk', the binary will be called and passed the code block
;;  as stdin.  There is currently no support for :session or otherwise
;;  keeping state between execution of different babel code blocks.

;;; Code:

(require 'ob)
(require 'lurk-mode)

(defun org-babel-execute:lurk (body _)
  "Execute BODY (a block of lurk code) with org-babel."
  (org-babel-eval
   lurk-executable
   body))

(provide 'ob-lurk)
;;; ob-lurk.el ends here
