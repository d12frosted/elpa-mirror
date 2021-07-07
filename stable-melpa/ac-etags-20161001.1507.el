;;; ac-etags.el --- etags/ctags completion source for auto-complete

;; Copyright (C) 2015 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-ac-etags
;; Package-Version: 20161001.1507
;; Package-Commit: 7983e631c226fe0fa53af3b2d56bf4eca3d785ce
;; Version: 0.06
;; Package-Requires: ((auto-complete "1.4"))

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

;; `ac-etags.el' is etags/ctags completion source for auto-complete.

;; Sample configuration
;;
;; If you change `requires' auto-complete source attribute
;;
;;   (custom-set-variables
;;     '(ac-etags-requires 1))
;;
;;   (eval-after-load "etags"
;;     '(progn
;;         (ac-etags-setup)))
;;
;;   (defun my/c-mode-common-hook ()
;;     (add-to-list 'ac-sources 'ac-source-etags))
;;
;;   (add-hook 'c-mode-common-hook 'my/c-mode-common-hook)

;;; Code:

(require 'auto-complete)
(require 'etags)

(defgroup ac-etags nil
  "Auto completion with etags"
  :group 'auto-complete)

(defcustom ac-etags-requires 3
  "Minimum input for starting completion"
  :type 'integer
  :group 'ac-etags)

(defface ac-etags-candidate-face
  '((t (:inherit ac-candidate-face :foreground "navy")))
  "Face for etags candidate"
  :group 'ac-etags)

(defface ac-etags-selection-face
  '((t (:inherit ac-selection-face :background "navy")))
  "Face for the etags selected candidate."
  :group 'ac-etags)

(defvar ac-etags--completion-cache (make-hash-table :test 'equal))

(defun ac-etags--cache-candidates (prefix)
  (let ((candidates
         (all-completions
          prefix
          (with-demoted-errors "%s"
            (tags-completion-table)))))
    (when candidates
      (puthash prefix candidates ac-etags--completion-cache)
      candidates)))

(defun ac-etags--candidates ()
  (when tags-table-list
    (or (gethash ac-prefix ac-etags--completion-cache)
        (ac-etags--cache-candidates ac-prefix))))

;;;###autoload
(defun ac-etags-ac-setup ()
  "Add `ac-source-etags' to `ac-sources' and enable `auto-complete' mode"
  (interactive)
  (add-to-list 'ac-sources 'ac-source-etags)
  (unless auto-complete-mode
    (auto-complete-mode +1)))

;;;###autoload
(defun ac-etags-clear-cache ()
  (interactive)
  (clrhash ac-etags--completion-cache))

;;;###autoload
(defun ac-etags-setup ()
  (interactive)

  (ac-define-source etags
    `((candidates . ac-etags--candidates)
      (candidate-face . ac-etags-candidate-face)
      (selection-face . ac-etags-selection-face)
      (requires . ,ac-etags-requires)
      (symbol . "s"))))

(provide 'ac-etags)

;;; ac-etags.el ends here
