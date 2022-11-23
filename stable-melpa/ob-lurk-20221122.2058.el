;;; ob-lurk.el --- Evaluate lurk code blocks in org mode -*- lexical-binding: t; -*-
;; Authors: Jeff Weiss <jweiss@protocol.ai>
;; Maintainer: Jeff Weiss <jweiss@protocol.ai>
;; URL: http://github.com/lurk-lang/lurk-emacs
;; Package-Version: 20221122.2058
;; Package-Commit: bd7cf661ccb31bfbfab542018c361bd79064d4f4
;; Keywords: languages lurk lisp
;; Version: 0.1.7
;; SPDX-License-Identifier: Apache-2.0 AND MIT
;; Package-Requires: ((emacs "25.1") (lurk-mode "0.1.6"))

;;; Commentary:

;;  Requires that the variable `lurk-executable' be set to point to
;;  the binary build of lurk.  When you execute a babel code block with
;;  type `lurk', the binary will be called and passed the code block
;;  as stdin.  There is currently no support for :session or otherwise
;;  keeping state between execution of different babel code blocks.

;;; Code:

(require 'ob)
(require 'lurk-mode)

(defun org-babel-execute:lurk (body params)
  "Execute BODY (a block of lurk code) with org-babel. Use :var
debug='t for detailed logging"
  (let ((debug (assq 'debug (org-babel--get-vars params))))
    (org-babel-eval (format "%s%s"
			    (if debug "RUST_LOG=info " "")
			    lurk-executable)
		    body)))

(provide 'ob-lurk)
;;; ob-lurk.el ends here
