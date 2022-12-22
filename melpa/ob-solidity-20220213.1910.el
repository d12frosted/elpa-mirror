;;; ob-solidity.el --- Org-babel functions for solidity evaluation

;; Copyright (C) hrkrshnn

;; Author: hrkrshnn
;; Keywords: solidity, literate programming, reproducible research, languages
;; Homepage: https://github.com/hrkrshnn/ob-solidity
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (solidity-mode "0.1.10"))

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Org-babel support for compiling solidity code.
;;
;; Example block:
;; #+begin_src solidity :args --asm --optimize
;;   contract A {
;;   }
;; #+end_src
;;
;; The ":args" field is optional, if provided, it forwards the arguments to "solc".
;;
;; The solc binary is found from the variable `solidity-solc-path`, defined in solidity-mode.

;;; Requirements:

;; solidity-mode https://github.com/ethereum/emacs-solidity.
;;
;; solidity compiler (solc) installed. The path is set at `solidity-solc-path`, defined in the above package (emacs-solidity).

(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)
(require 'solidity-mode)

;; optionally define a file extension for this language
;;; Code:

(add-to-list 'org-babel-tangle-lang-exts '("solidity" . "sol"))

;; This function expands the body of a source code block by doing
;; things like prepending argument definitions to the body, it should
;; be called by the `org-babel-execute:solidity' function below.
(defun org-babel-expand-body:solidity (body params &optional processed-params)
  "Expand BODY according to PARAMS, return the expanded body.
The optional argument PROCESSED-PARAMS exists for interface compatibility."
  body)

;; Modification of `org-babel-eval' that will show the error message in the same buffer
(defun org-babel-eval-solidity (cmd body)
  "Run CMD on BODY.
If CMD succeeds then return its results, otherwise display
STDERR with `org-babel-eval-error-notify'."
  (let ((err-buff (get-buffer-create " *Org-Babel Error*")) exit-code)
	(with-current-buffer err-buff (erase-buffer))
	(with-temp-buffer
	  (insert body)
	  (setq exit-code
			(org-babel--shell-command-on-region
			 (point-min) (point-max) cmd err-buff))
	  (if (or (not (numberp exit-code)) (> exit-code 0))
		  (with-current-buffer err-buff (buffer-string))
		(buffer-string)))))

;; This is the main function which is called to evaluate a code
;; block.
(defun org-babel-execute:solidity (body params)
  "Execute a block of Solidity code with org-babel.
The variable BODY is the Solidity source code.
The variable PARAMS is translated to parameters to solc.
This function is called by `org-babel-execute-src-block'"
  (message "Compiling Solidity source code block.")
  (let* ((processed-params (org-babel-process-params params))
		 (full-body (org-babel-expand-body:solidity
					 body params processed-params))
         ;; Can optionally provide arguments that should be forwarded to solc. For example
         ;; --ir-optimized --optimize to see the optimized IR output.
		 (args (cdr (assoc :args processed-params)))
         ;; Can optionally provide path to the "solc" binary. Useful when dealing with different
         ;; versions of solidity.
		 (solc-path (cdr (assoc :path processed-params)))
         (full-path (if (not solc-path) solidity-solc-path solc-path)))

    (org-babel-eval-solidity (concat full-path " " args " - ") full-body)))

(provide 'ob-solidity)
;;; ob-solidity.el ends here
