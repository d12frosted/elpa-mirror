;;; ruled-switch-buffer.el --- Rule based buffer switching  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Kazuki Nishikawa

;; Author: Kazuki Nishikawa <kzkn@hey.com>
;; Keywords: convenience
;; Homepage: https://github.com/kzkn/ruled-switch-buffer
;; Package-Requires: ((emacs "24.3"))
;; Version: 0.1.0

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

;; This library provides a macro to define rules for moving between
;; related buffers, and a command to switch between buffers according
;; to the defined rules.
;;
;; An example of a switching rule is a rule to switch between .c and
;; .h file.  Once you have defined such a rule, you will be able to
;; quickly switch between .c and .h.
;;
;; You have to define the rules yourself.  This library does not
;; provide any specific rules.

;;; Code:

(require 'cl-lib)

(defgroup ruled-switch-buffer nil
  "Rule based buffer switching."
  :group 'convenience)

(defcustom ruled-switch-buffer-completing-read-fn 'completing-read
  "Function for completing read for choose a file name."
  :type 'function
  :group 'ruled-switch-buffer)

(cl-defstruct ruled-switch-buffer--rule
  name
  matcher
  mappers)

(defvar ruled-switch-buffer--rules '())

(defun ruled-switch-buffer--flatten (x)
  "Flatten tree X."
  (cl-labels ((rec (x acc)
                   (cond ((null x) acc)
                         ((atom x) (cons x acc))
                         (t (rec (car x) (rec (cdr x) acc))))))
    (rec x nil)))

(defun ruled-switch-buffer--push-rule (name matcher mappers)
  "Create a new buffer switching rule and register it.
The rule is named NAME and use MATCHER function as matching
and use MAPPERS as map from current buffer to the switching
target file names."
  (let ((rules (cl-remove-if (lambda (rule) (eq name (ruled-switch-buffer--rule-name rule))) ruled-switch-buffer--rules))
        (rule (make-ruled-switch-buffer--rule
               :name name
               :matcher matcher
               :mappers (if (functionp mappers) (list mappers) mappers))))
    (setq ruled-switch-buffer--rules (cons rule rules))))

(defun ruled-switch-buffer--rule-match-p (rule file-name)
  "Check the FILE-NAME is matched the RULE."
  (funcall (ruled-switch-buffer--rule-matcher rule) file-name))

(defun ruled-switch-buffer--matched-rules (file-name)
  "List rules which are matched to FILE-NAME."
  (cl-remove-if-not (lambda (rule)
                      (ruled-switch-buffer--rule-match-p rule file-name))
                    ruled-switch-buffer--rules))

(defun ruled-switch-buffer--mapped-file-names (rule file-name)
  "List file names which are mapped from FILE-NAME with mappers of RULE."
  (mapcar (lambda (mapper) (funcall mapper file-name))
          (ruled-switch-buffer--rule-mappers rule)))

(defun ruled-switch-buffer--switch-buffer-candidates (file-name)
  "List file names which are switching targeted by all rules from FILE-NAME."
  (cl-remove-if-not
   #'file-exists-p
   (ruled-switch-buffer--flatten
    (mapcar (lambda (rule) (ruled-switch-buffer--mapped-file-names rule file-name))
            (ruled-switch-buffer--matched-rules file-name)))))

(defun ruled-switch-buffer--select-file-name (candidate-file-names)
  "Choose a file name from CANDIDATE-FILE-NAMES."
  (if (<= (length candidate-file-names) 1)
      (car candidate-file-names)
    (let ((choices (mapcar #'file-relative-name candidate-file-names)))
      (funcall ruled-switch-buffer-completing-read-fn "Choose: " choices))))

;;;###autoload
(cl-defmacro ruled-switch-buffer-define (name &key matcher mappers)
  "Define a buffer switching rule.
Argument NAME: A symbol that the name of rule
Argument MATCHER: A function to check if the rule can be applied
to the given file path
Argument MAPPERS: A function or a list of functions to map from
given file path to the switching target file path"
  (declare (indent defun))
  `(progn
     (ruled-switch-buffer--push-rule ',name #',matcher ',mappers)
     t))

;;;###autoload
(defun ruled-switch-buffer ()
  "Switch buffer from the current buffer according to the defined rules."
  (interactive)
  (let* ((file-name (buffer-file-name))
         (candidate-file-names (ruled-switch-buffer--switch-buffer-candidates file-name))
         (selected-file-name (ruled-switch-buffer--select-file-name candidate-file-names)))
    (when selected-file-name
      (find-file selected-file-name))))

(provide 'ruled-switch-buffer)
;;; ruled-switch-buffer.el ends here
