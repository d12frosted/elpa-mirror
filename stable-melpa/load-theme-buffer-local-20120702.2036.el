;;; load-theme-buffer-local.el --- Install emacs24 color themes by buffer.
;;; Version: 0.0.2
;;; Author: Victor Borja <vic.borja@gmail.com>
;;; URL: http://github.com/vic/color-theme-buffer-local
;;; Description: Set color-theme by buffer.
;;; Keywords: faces


;; This file is not part of GNU Emacs. Licensed on the same terms as
;; GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.


;;;
;;; Usage for emacs24 builtin themes:
;;;
;;;
;;; (add-hook 'java-mode-hook (lambda nil
;;;   (load-theme-buffer-local 'misterioso (current-buffer))))


(defun custom-theme-buffer-local-spec-attrs (spec)
  (let* ((spec (face-spec-choose spec))
         attrs)
    (while spec
      (when (assq (car spec) face-x-resources)
        (push (car spec) attrs)
        (push (cadr spec) attrs))
      (setq spec (cddr spec)))
    (nreverse attrs)))

(defun custom-theme-buffer-local-recalc-face (face buffer)
  (with-current-buffer buffer
    (let (attrs)
    
    (if (get face 'face-alias)
        (setq face (get face 'face-alias)))
    
    ;; first set the default spec
    (or (get face 'customized-face)
        (get face 'saved-face)
        (setq attrs
              (append
               attrs
               (custom-theme-buffer-local-spec-attrs
                (face-default-spec face)))))

    (let ((theme-faces (reverse (get face 'theme-face))))
      (dolist (spec theme-faces)
        (setq attrs (append
                     attrs
                     (custom-theme-buffer-local-spec-attrs (cadr spec))))))

    (and (get face 'face-override-spec)
         (setq attrs (append
                      attrs
                      (custom-theme-buffer-local-spec-attrs
                       (get face 'face-override-spec)))))

    (face-remap-set-base face attrs))))

(defun custom-theme-buffer-local-recalc-variable (variable buffer)
  (with-current-buffer buffer
    (make-variable-buffer-local variable)
    (let ((valspec (custom-variable-theme-value variable)))
      (if valspec
          (put variable 'saved-value valspec)
        (setq valspec (get variable 'standard-value)))
      (if (and valspec
               (or (get variable 'force-value)
                   (default-boundp variable)))
          (funcall (or (get variable 'custom-set) 'set-default) variable
                   (eval (car valspec)))))))


;;;###autoload
(defun load-theme-buffer-local (theme &optional buffer no-confirm no-enable)
  "Load an Emacs24 THEME only in BUFFER."
  (interactive
   (list (intern (completing-read
                  "Install theme: "
                  (mapcar 'symbol-name (custom-available-themes))))
         (read-buffer "on Buffer: " (current-buffer) t)))
  (or buffer (setq buffer (current-buffer)))
  (flet ((custom-theme-recalc-face
          (symbol) (custom-theme-buffer-local-recalc-face symbol buffer))
         (custom-theme-recalc-variable
          (symbol) (custom-theme-buffer-local-recalc-variable symbol buffer)))
    (load-theme theme no-confirm no-enable)))


(provide 'load-theme-buffer-local)

;;; load-theme-buffer-local.el ends here
