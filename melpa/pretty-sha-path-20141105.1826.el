;;; pretty-sha-path.el --- Prettify Guix/Nix store paths

;; Copyright © 2014 Alex Kost

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 27 Sep 2014
;; Version: 0.1
;; Package-Version: 20141105.1826
;; Package-Commit: beea38bdf34ed27059d6484e1e2a337a27e1f7ce
;; URL: https://gitorious.org/alezost-emacs/pretty-sha-path
;; URL: https://github.com/alezost/pretty-sha-path.el
;; Keywords: faces convenience

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

;; This package provides minor-mode for prettifying Guix/Nix store
;; paths, i.e. after enabling `pretty-sha-path-mode',
;; '/gnu/store/72f54nfp6g1hz873w8z3gfcah0h4nl9p-foo-0.1' paths will be
;; replaced with '/gnu/store/…-foo-0.1' paths in the current buffer.
;; There is also `global-pretty-sha-path-mode' for global prettifying.

;; To install, add the following to your emacs init file:
;;
;;   (add-to-list 'load-path "/path/to/pretty-sha-path")
;;   (autoload 'pretty-sha-path-mode "pretty-sha-path" nil t)
;;   (autoload 'global-pretty-sha-path-mode "pretty-sha-path" nil t)

;; If you want to enable/disable composition after "M-x font-lock-mode",
;; use the following setting:
;;
;;   (setq font-lock-extra-managed-props
;;         (cons 'composition font-lock-extra-managed-props))

;; Credits:
;;
;; Thanks to Ludovic Courtès for the idea of this package.
;;
;; Thanks to the authors of `prettify-symbols-mode' (part of Emacs 24.4)
;; and "pretty-symbols.el" <http://github.com/drothlis/pretty-symbols>
;; for the code.  It helped to write this package.

;;; Code:

(defgroup pretty-sha-path nil
  "Prettify Guix/Nix store paths."
  :prefix "pretty-sha-path-"
  :group 'font-lock
  :group 'convenience)

(defcustom pretty-sha-path-char ?…
  "Character used for prettifying."
  :type 'character
  :group 'pretty-sha-path)

(defcustom pretty-sha-path-decompose-force nil
  "If non-nil, remove any composition.

By default, after disabling `pretty-sha-path-mode',
compositions (prettifying paths with `pretty-sha-path-char') are
removed only from strings matching `pretty-sha-path-regexp', so
that compositions created by other modes are left untouched.

Set this variable to non-nil, if you want to remove any
composition unconditionally (like `prettify-symbols-mode' does).
Most likely it will do no harm and will make the process of
disabling `pretty-sha-path-mode' a little faster."
  :type 'boolean
  :group 'pretty-sha-path)

(defcustom pretty-sha-path-regexp
  (rx "/"
      (or "nix" "gnu")
      "/store/"
      ;; Hash-parts do not include "e", "o", "u" and "t".  See base32Chars
      ;; at <https://github.com/NixOS/nix/blob/master/src/libutil/hash.cc>
      (group (= 32 (any "0-9" "a-d" "f-n" "p-s" "v-z"))))
  "Regexp matching SHA paths.

Disable `pretty-sha-path-mode' before modifying this variable and
make sure to modify `pretty-sha-path-regexp-group' if needed.

Example of a \"deeper\" prettifying:

  (setq pretty-sha-path-regexp \"store/[[:alnum:]]\\\\\\={32\\\\}\"
        pretty-sha-path-regexp-group 0)

This will transform
'/gnu/store/72f54nfp6g1hz873w8z3gfcah0h4nl9p-foo-0.1' into
'/gnu/…-foo-0.1'"
  :type 'regexp
  :group 'pretty-sha-path)

(defcustom pretty-sha-path-regexp-group 1
  "Regexp group in `pretty-sha-path-regexp' for prettifying."
  :type 'integer
  :group 'pretty-sha-path)

(defvar pretty-sha-path-special-modes
  '(guix-info-mode ibuffer-mode)
  "List of special modes that support font-locking.

By default, \\[global-pretty-sha-path-mode] enables prettifying
in all buffers except the ones where `font-lock-defaults' is
nil (see Info node `(elisp) Font Lock Basics'), because it may
break the existing highlighting.

Modes from this list and all derived modes are exceptions
\(`global-pretty-sha-path-mode' enables prettifying there).")

(defvar pretty-sha-path-flush-function
  (cond ((fboundp 'font-lock-flush) #'font-lock-flush)
        ((fboundp 'jit-lock-refontify) #'jit-lock-refontify))
  "Function used to refontify buffer.
This function is called without arguments after
enabling/disabling `pretty-sha-path-mode'.
If nil, do nothing.")

(defun pretty-sha-path-compose ()
  "Compose matching region in the current buffer."
  (let ((beg (match-beginning pretty-sha-path-regexp-group))
        (end (match-end       pretty-sha-path-regexp-group)))
    (compose-region beg end pretty-sha-path-char 'decompose-region))
  ;; Return nil because we're not adding any face property.
  nil)

(defun pretty-sha-path-decompose-buffer ()
  "Remove path compositions from the current buffer."
  (with-silent-modifications
    (let ((inhibit-read-only t))
      (if pretty-sha-path-decompose-force
          (remove-text-properties (point-min)
                                  (point-max)
                                  '(composition nil))
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward pretty-sha-path-regexp nil t)
            (remove-text-properties
             (match-beginning pretty-sha-path-regexp-group)
             (match-end       pretty-sha-path-regexp-group)
             '(composition nil))))))))

;;;###autoload
(define-minor-mode pretty-sha-path-mode
  "Toggle Pretty SHA Path mode.

With a prefix argument ARG, enable Pretty SHA Path mode if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or nil.

When Pretty SHA Path mode is enabled, SHA-parts of the Guix/Nix
store paths (see `pretty-sha-path-regexp') are prettified,
i.e. displayed as `pretty-sha-path-char' character.  This mode
can be enabled programmatically using hooks:

  (add-hook 'shell-mode-hook 'pretty-sha-path-mode)

It is possible to enable the mode in any buffer, however not any
buffer's highlighting may survive after adding new elements to
`font-lock-keywords' (see `pretty-sha-path-special-modes' for
details).

Also you can use `global-pretty-sha-path-mode' to enable Pretty
SHA Path mode for all modes that support font-locking."
  :init-value nil
  :lighter " …"
  (let ((keywords `((,pretty-sha-path-regexp
                     (,pretty-sha-path-regexp-group
                      (pretty-sha-path-compose))))))
    (if pretty-sha-path-mode
        ;; Turn on.
        (font-lock-add-keywords nil keywords)
      ;; Turn off.
      (font-lock-remove-keywords nil keywords)
      (pretty-sha-path-decompose-buffer))
    (and pretty-sha-path-flush-function
         (funcall pretty-sha-path-flush-function))))

(defun pretty-sha-path-supported-p ()
  "Return non-nil, if the mode can be harmlessly enabled in current buffer."
  (or font-lock-defaults
      (apply #'derived-mode-p pretty-sha-path-special-modes)))

(defun pretty-sha-path-turn-on ()
  "Enable `pretty-sha-path-mode' in the current buffer if needed.
See `pretty-sha-path-special-modes' for details."
  (and (not pretty-sha-path-mode)
       (pretty-sha-path-supported-p)
       (pretty-sha-path-mode)))

;;;###autoload
(define-globalized-minor-mode global-pretty-sha-path-mode
  pretty-sha-path-mode pretty-sha-path-turn-on)

;;;###autoload
(defalias 'pretty-sha-path-global-mode 'global-pretty-sha-path-mode)

(provide 'pretty-sha-path)

;;; pretty-sha-path.el ends here
