;;; ert-modeline.el --- displays ert test results in the modeline.

;; Copyright (C) 2013 Chris Barrett

;; Author: Chris Barrett <chris.d.barrett@me.com>
;; Version: 0.2.3
;; Package-Version: 20140115.1015
;; Package-Commit: 7c6340834387f749519616f9601821cb73fd657b
;; Package-Requires: ((s "1.3.1")(dash "1.2.0")(emacs "24.1")(projectile "0.9.1"))
;; Keywords: tools tests convenience

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Runs ERT tests whenever you save an elisp buffer or eval an
;; expression. Displays the results in the modeline.

;;; Code:

(require 'ert)
(require 'dash)
(require 's)
(autoload 'projectile-project-p "projectile")

;;; Customization

(defgroup ert-modeline nil
  "Runs ert tests while you edit and displays the results in the modeline."
  :prefix "ertml-"
  :group 'tools)

(defcustom ertml-selector t
  "The selector to use for running ERT tests."
  :group 'ert-modeline
  :type 'symbol)

(defcustom ertml-setup-commands '(ertml--load-project-tests)
  "A list of functions that will be called when the mode is activated.
The default action is to search for test files in the project."
  :group 'ert-modeline)

(defface ertml-failing-face
  '((t :inherit error))
  "Face for error indicator."
  :group 'ert-modeline)

(defface ertml-warning-face
  '((t :inherit warning))
  "Face for warning indicator."
  :group 'ert-modeline)

(defface ertml-passing-face
  '((t (:inherit success)))
  "Face for passing tests indicator."
  :group 'ert-modeline)

;;; ----------------------------------------------------------------------------

(defun ertml--load-project-tests ()
  "Load the ert test files in the current project.

Tests should include the term \"test\" in the filename.

If a test-runner is found, that will be loaded first.  A test
runner is expected to be an elisp file that includes the term
\"runner\" or \"fixture\" in the filename.

These files may be located in the project root, or in folders
called \"test\" or \"tests\"."
  (interactive)
  (-when-let (root (projectile-project-p))
    (let* (
           (files (->> (list root (concat root "test/") (concat root "tests/"))
                    ;; Find all tests in possible test directories.
                    (-filter 'file-exists-p)
                    (--mapcat (directory-files it t (rx "test" (* nonl) ".el")))
                    (-remove 'null)
                    (-filter 'file-exists-p)
                    ;; Find test runners.
                    (--group-by (s-matches? (rx (or "runner" "fixture")) it))))
           (runners (assoc t files))
           (tests   (assoc nil files))
           )
      (--each (cdr runners)
        ;; Do not execute tests when loading test runners.
        (flet ((ert-run-tests-batch-and-exit (&rest _))
               (ert-run-tests-batch (&rest _)))
          (load it)))

      (--each (cdr tests)
        (load it))

      (when (or runners tests)
        (message "Loaded %s test files"
                 (+ (length (cdr runners))
                    (length (cdr tests))))))))

;;; ----------------------------------------------------------------------------
;;; Mode functions


(defvar ertml--status-text ""
  "The string to use to represent the current status in the modeline.")

;;;###autoload
(define-minor-mode ert-modeline-mode
  "Displays the current status of ERT tests in the modeline."
  :init-value nil
  :lighter (:eval ertml--status-text)

  (cond
   (ert-modeline-mode

    ;; Run setup commands. The default action is to load tests in the project.
    (--each ertml-setup-commands
      (funcall it))

    (ertml--run-tests)
    (add-hook 'after-save-hook 'ertml--run-tests nil t))

   (t
    (remove-hook 'after-save-hook 'ertml--run-tests t))))

(defun ertml--run-tests (&rest _)
  "Run ERT and update the modeline."
  ;; Rebind `message' so that we do not see printed results.
  (flet ((message (&rest _)))
    (-when-let (result (ert-run-tests-batch ertml-selector))
      (setq ertml--status-text (ertml--summarize result)))))

(defun ertml--summarize (results)
  "Select a circle corresponding to the type and number of RESULTS."
  (let ((failing (ert--stats-failed-unexpected results)))
    (cond
     ;; No tests are enabled - do not show lighter.
     ((>= 0 (length (ert--stats-tests results)))
      "")
     ;; Indicate number of failing tests.
     ((< 0 failing)
      (propertize (format " [%s]" failing) 'font-lock-face 'ertml-failing-face))
     ;; Show OK for all passing.
     (t
      (propertize " [OK]" 'font-lock-face 'ertml-passing-face)))))

;;; ----------------------------------------------------------------------------
;;; Eval advice
;;;
;;; Ensures that tests are re-run when the buffer is evaluated.

(dolist (fn '(eval-buffer
              eval-defun
              eval-current-buffer
              eval-region)
            )
  (eval `(defadvice ,fn (after ertml--run activate)
           (when (and (boundp 'ert-modeline-mode) ert-modeline-mode)
             (ertml--run-tests)))))

(provide 'ert-modeline)

;; Local Variables:
;; lexical-binding: t
;; byte-compile-warnings: (not obsolete)
;; End:

;;; ert-modeline.el ends here
