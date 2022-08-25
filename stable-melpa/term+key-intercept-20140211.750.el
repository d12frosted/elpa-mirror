;;; term+key-intercept.el --- term+ intercept key mapping

;; Author: INA Lintaro <tarao.gnn at gmail.com>
;; URL: http://github.com/tarao/term+-el
;; Package-Version: 20140211.750
;; Package-Commit: fd0771fd66b8c7a909aaac972194485c79ba48c4
;; Version: 0.1
;; Keywords: terminal, emulation
;; Package-Requires: ((term+ "0.1") (key-intercept "0.1"))

;; This file is NOT part of GNU Emacs.

;;; License:
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'term+vars)
(require 'key-intercept)

(defcustom term+intercept-key-alist
  '(("ESC" . (term+send-esc . 0.01))
    ("C-c" . term-interrupt-subjob))
  "Keys that are recognized by Emacs if immediately followed by
some other keys, or recognized in `term-char-mode' otherwize.
The value is a list of (KEY . COMMAND) pair or (KEY . (COMMAND
. DELAY)) where DELAY specifies how many seconds it will wait for
successive keys to determines whether the keys should be
recognized by Emacs."
  :type '(alist :key-type (choice string vector)
                :value-type (choice symbol (cons symbol number)))
  :group 'term+)

(defun term+key-intercept-setup ()
  ;; enable ESC and C-c both in terminal and in Emacs
  (make-local-variable 'emulation-mode-map-alists)
  (dolist (elt term+intercept-key-alist)
    (let* ((key (car elt)) (key (if (stringp key) (read-kbd-macro key) key))
           (cmd (cdr elt)) (mode 'term+char-mode))
      (if (consp cmd)
          (define-modal-intercept-key key mode (car cmd) (cdr cmd))
        (define-modal-intercept-key key mode cmd)))))

(add-hook 'term+char-mode-hook #'(lambda () (key-intercept-mode 1)))
(add-hook 'term+line-mode-hook #'(lambda () (key-intercept-mode 0)))
(add-hook 'term-mode-hook #'term+key-intercept-setup)

(provide 'term+key-intercept)
;;; term+key-intercept.el ends here
