;;; editorconfig-custom-majormode.el --- Decide major-mode and mmm-mode from EditorConfig

;; Author: 10sr <8slashes+el [at] gmail [dot] com>
;; URL: https://github.com/10sr/editorconfig-custom-majormode-el
;; Package-Version: 20180816.244
;; Package-Commit: 13ad1c83f847bedd4b3a19f9df7fd925853b19de
;; Version: 0.0.3
;; Package-Requires: ((editorconfig "0.6.0"))
;; Keywords: editorconfig util

;; This file is not part of GNU Emacs.

;; This is free and unencumbered software released into the public domain.

;; Anyone is free to copy, modify, publish, use, compile, sell, or
;; distribute this software, either in source code form or as a compiled
;; binary, for any purpose, commercial or non-commercial, and by any
;; means.

;; In jurisdictions that recognize copyright laws, the author or authors
;; of this software dedicate any and all copyright interest in the
;; software to the public domain. We make this dedication for the benefit
;; of the public at large and to the detriment of our heirs and
;; successors. We intend this dedication to be an overt act of
;; relinquishment in perpetuity of all present and future rights to this
;; software under copyright law.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
;; OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
;; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;; OTHER DEALINGS IN THE SOFTWARE.

;; For more information, please refer to <http://unlicense.org>


;;; Commentary:

;; An EditorConfig extension that defines a property to specify which
;; Emacs major-mode to use for files.

;; For example, add emacs_mode to your .editorconfig as follows, and
;; `nginx-mode' will be always enabled when visiting *.conf files.

;; [*.conf]
;; emacs_mode = nginx

;; Also this library has an experimental mmm-mode support.
;; To use it, add properties like:

;; [*.conf.j2]
;; emacs_mode = nginx
;; emacs_mmm_classes = jinja2

;; Multiple mmm_classes can be specified by separating classes with
;; commmas.

;; To enable this plugin, add `editorconfig-custom-majormode' to
;; `editorconfig-custom-hooks':

;; (add-hook 'editorconfig-custom-hooks
;;           'editorconfig-custom-majormode)

;;; Code:

(eval-when-compile
  (defvar mmm-classes)
  (defvar mmm-classes-alist))

(defvar editorconfig-custom-majormode--already
  nil
  "Flag used internaly to avoid infinite loop.")

(defun editorconfig-custom-majormode--is-a-mode-p (target want)
  "Return non-nil if major mode TARGET is a major mode WANT."
  (or (eq target
          want)
      (let ((parent (get target 'derived-mode-parent)))
        (and parent
             (editorconfig-custom-majormode--is-a-mode-p parent want)))))

(defun editorconfig-custom-majormode--require-or-install (lib)
  "Try to install LIB if not found and load it.

Return non-nil if LIB has been successfully loaded."
  (or (require lib nil t)
      (and (eval-and-compile (require 'package nil t))
           (assq lib
                 package-archive-contents)
           (yes-or-no-p (format "editorconfig-custom-majormode: Library `%S' not found but available as a package. Install?"
                                lib))
           (progn
             (package-install lib)
             (require lib)))))

(defun editorconfig-custom-majormode--set-majormode (mode)
  "Set majormode to MODE."
  (when (and mode
             (not (editorconfig-custom-majormode--is-a-mode-p major-mode
                                                              mode)))
    (if (or (fboundp mode)
            (editorconfig-custom-majormode--require-or-install mode))
        (funcall mode)
      (display-warning :error (format "Major-mode `%S' not found"
                                      mode)))))

(defun editorconfig-custom-majormode--set-mmm-classes (classes)
  "Set mmm-classes to CLASSES."
  (setq mmm-classes nil)
  (dolist (class classes)
    ;; Expect class is available as mmm-<class> library
    ;; TODO: auto install
    (unless (assq class
                  mmm-classes-alist)
      (editorconfig-custom-majormode--require-or-install
       (intern (concat "mmm-"
                       (symbol-name class)))))
    ;; Make sure it has been loaded
    (require (intern (concat "mmm-"
                             (symbol-name class)))
             nil t)
    ;; Add even when package was not found
    (add-to-list 'mmm-classes
                 class)))

;;;###autoload
(defun editorconfig-custom-majormode (hash)
  "Get emacs_mode property from HASH and set major mode.

If `package' is installed on your Emacs and the major mode specified is
installable, this plugin asks whether you want to install and enable it
automatically."
  (when (not editorconfig-custom-majormode--already)
    (let* ((editorconfig-custom-majormode--already t)
           (mode-str (gethash 'emacs_mode
                              hash))
           (mode (and mode-str
                      (not (string= mode-str
                                    ""))
                      (intern (concat mode-str
                                      "-mode"))))
           (mmm-classes-str (gethash 'emacs_mmm_classes
                                     hash))
           ;; FIXME: Split by comma and make list
           (ed-mmm-classes (and mmm-classes-str
                                (not (string= ""
                                              mmm-classes-str))
                                (mapcar 'intern
                                        (split-string mmm-classes-str
                                                      ",")))))
      (when mode
        (editorconfig-custom-majormode--set-majormode mode))
      (when (and ed-mmm-classes
                 (editorconfig-custom-majormode--require-or-install 'mmm-mode))
        (editorconfig-custom-majormode--set-mmm-classes ed-mmm-classes)
        (mmm-mode-on)))))

(provide 'editorconfig-custom-majormode)

;;; editorconfig-custom-majormode.el ends here
