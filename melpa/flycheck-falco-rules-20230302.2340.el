;;; flycheck-falco-rules.el --- On-the-fly syntax checking for falco rules files -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 The Falco Authors.
;;
;;
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.
;;

;; Author: The Falco Developers (https://falco.org)
;; URL: https://github.com/falcosecurity/flycheck-falco-rules
;; Package-Version: 20230302.2340
;; Package-Commit: 1ad301d497ade9556327053ca571ee51bf0c0633
;; Keywords: tools, convenience
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.3") (flycheck "0.25") (let-alist "1.0.1"))

;;; Commentary:

;; Flycheck checker for Falco Rules Files.

;;; Code:

(require 'flycheck)

(defcustom flycheck-falco-rules-validate-command
  "docker run --rm -v/tmp:/tmp falcosecurity/falco-no-driver falco -o json_output=True -V"
  "The command and arguments to use to validate the falco rules content.
The default uses 'docker run' to run a falco-no-driver container
with the -V argument.  The file to be validated will be appended to
the end of this command line"
  :type 'string
  :group 'flycheck-falco-rules)

(defun flycheck-falco-rules-find-last-location (locations)
  "Return either the last or second-to-last location from a list of locations.
LOCATIONS are a list of locations.  Returns the second-to last if the last
location represents a condition expression."
  (if (let-alist (car (last locations))
	(string= .item_type "condition expression"))
      (car (last (butlast locations)))
    (car (last locations))))

(defun flycheck-falco-rules-create-flycheck-error (checker buffer filename error_or_warning_obj kind)
  "Create an error or warning object from the provided json object.
CHECKER, BUFFER and FILENAME are provided from a call to
flycheck-falco-rules-parse.  ERROR_OR_WARNING_OBJ is from
 a falco yaml json object.  KIND is either warning or error."
  (let-alist error_or_warning_obj
    (let ((code .code) (message .message))
      (let-alist .context
	(let-alist (flycheck-falco-rules-find-last-location .locations)
	  (let-alist .position
	    (flycheck-error-new-at
	     (+ .line 1)
	     (+ .column 1)
	     kind message
	     :id code
	     :checker checker
	     :buffer buffer
	     :filename filename)))))))

(defun flycheck-falco-rules-parse (output checker buffer)
    "Parse Falco Rules errors/warnings from Falco's validate json output.
CHECKER and BUFFER denote the CHECKER that returned OUTPUT and
the BUFFER that was checked respectively.
See URL <https://falco.org> for more information
about Falco."
    (let ((errors nil))
      (let ((message (car (flycheck-parse-json output))))
	(let-alist message
	  (dolist (result .falco_load_results)
	    (let-alist result
	      (let ((filename .name))
		(progn
		  (dolist (error_obj .errors)
		    (push (flycheck-falco-rules-create-flycheck-error checker buffer filename error_obj 'error)
			  errors))
		  (dolist (warning_obj .warnings)
		    (push (flycheck-falco-rules-create-flycheck-error checker buffer filename warning_obj 'warning)
			  errors))))))))
      (nreverse errors)))

(flycheck-define-command-checker 'falco-rules
  "A Falco rules checker using the falco executable"
  :command (append (split-string flycheck-falco-rules-validate-command) '(source))
  :error-parser 'flycheck-falco-rules-parse
  
  :modes '(yaml-mode))

;;;###autoload
(defun flycheck-falco-rules-setup ()
  "Set up Flycheck for Falco Rules files."
  (add-to-list 'flycheck-checkers 'falco-rules))

(provide 'flycheck-falco-rules)

;;; flycheck-falco-rules.el ends here
