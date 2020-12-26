;;; centimacro.el --- Assign multiple macros as global key bindings

;; Copyright (C) 2014 Oleh Krehel

;; Author: Oleh Krehel <ohwoeowho@gmail.com>
;; URL: https://github.com/abo-abo/centimacro
;; Package-Version: 20201225.1132
;; Package-Commit: 0149877584b333c4f1953f0767f0cae23881b0df
;; Version: 0.1
;; Keywords: macros

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Main function is `centi-assign'.  It's very similar to <f3>, except
;; `centi-assign' prompts you for a key combination to use, while for
;; <f3> this key combination is always <f4>.
;;
;; With `centi-assign' you can have as many macros as you wish, bound to
;; whatever global keys you wish.
;;
;; Here's an example, assuming (global-set-key (kbd "<f5>") 'centi-assign)
;;     <f5><f6>foo<f6>                 ;; Now <f6> inserts "foo".
;;     <f5><f7><f6>bar<f7>             ;; Now <f7> inserts "foobar".
;;     <f5><f8><f6>-<f7>-<f6><f8>      ;; Now <f8> inserts "foo-foobar-foo".
;;     <f5><f6>omg<f6>                 ;; Now <f6> inserts "omg",
;;                                     ;;     <f7> - "omgbar",
;;                                     ;;     <f8> - "omgbar-omg-omg".
;;
;;
;; And here's the result of `centi-summary':
;;     [f8]: [f6 f7 f6] (was bookmark-bmenu-list)
;;     [f7]: [f6 98 97 114] (was winner-undo)
;;     [f6]: foo (was next-error)
;;
;; `centi-assign' will work with any global binding, i.e. you could even
;; re-bind "a" to insert "b" if you wanted.
;;
;; Calling `centi-restore-all' will restore the previous global bindings.

;;; Code:

(defgroup centimacro nil
  "Assign multiple macros."
  :group 'bindings
  :prefix "centi-")

(defcustom centi-assign-key [f5]
  "The global key binding that calls `centi-assign'."
  :set (lambda (symbol value)
         (when value
           (global-set-key value 'centi-assign))
         (set-default symbol value)))

(defvar centi-keys-alist nil
  "Assigned keys.  Key currently being assigned to is the first.")

;;;###autoload
(defun centi-assign ()
  "Read a KEY and start recording a macro for it.
Pressing KEY again stops recording and assigns the macro to KEY.
Aborts if KEY belongs to a minor mode.
Use `centi-summary' to list bound macros.
Use `centi-restore-all' to un-bind macros and restore the old key bindings."
  (interactive)
  (let ((key (read-key-sequence "Enter key: ")))
    (cond ((equal key "")
           (error "Aborting"))
          ((minor-mode-key-binding key)
           (error "Key belongs to %s.  Aborting"
                  (caar (minor-mode-key-binding key))))
          (t
           (let ((item (assoc key centi-keys-alist)))
             (if item
                 (progn
                   (setq centi-keys-alist (delete item centi-keys-alist))
                   (push item centi-keys-alist))
               (push (cons key (global-key-binding key))
                     centi-keys-alist)))
           (local-set-key key 'centi-finish)
           (kmacro-start-macro nil)))))

(defun centi-finish (arg)
  "Similar to (`kmacro-end-or-call-macro' ARG)."
  (interactive "p")
  (kmacro-end-or-call-macro arg)
  (local-set-key (caar centi-keys-alist) nil)
  (global-set-key
   (caar centi-keys-alist)
   (fset
    (intern (format "mcr-%s" last-command-event))
    last-kbd-macro)))

(defun centi-restore-all ()
  "Unbind all bound macros, restoring the previous key bindings."
  (interactive)
  (mapc (lambda(x) (global-set-key (car x) (cdr x)))
        centi-keys-alist)
  (setq centi-keys-alist nil))

(defun centi-summary ()
  "Show a summary of bound macros."
  (interactive)
  (message
   (if centi-keys-alist
       (mapconcat
        (lambda(x) (format "%s: %s (was %s)"
                      (car x)
                      (global-key-binding (car x))
                      (cdr x)))
        centi-keys-alist
        "\n")
     "no macros bound currently")))

(defun centi--macro->defun (str)
  "Convert macro representation STR to an Elisp string."
  (let ((i 0)
        (j 1)
        (n (length str))
        forms s f)
    (while (< i n)
      (setq s (substring str i j))
      (setq f (key-binding s))
      (if (keymapp f)
          (setq j (1+ j))
        (push (list f) forms)
        (setq i j)
        (setq j (1+ i))))
    (with-temp-buffer
      (emacs-lisp-mode)
      (insert
       "(defun foo ()\n  (interactive)")
      (mapc (lambda (f)
              (newline-and-indent)
              (insert (prin1-to-string f)))
            (nreverse forms))
      (insert ")")
      (buffer-string))))

(defun centi-insert-last-as-defun ()
  "Insert last macro as defun at point."
  (interactive)
  (insert (centi--macro->defun last-kbd-macro)))

(provide 'centimacro)

;;; centimacro.el ends here
