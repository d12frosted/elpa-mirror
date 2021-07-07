;;; flatbuffers-mode.el --- major mode for editing flatbuffers.

;; Author: Asal Mirzaieva <asalle.kim@gmail.com>
;; Created: 12-Nov-2019
;; Version: 0.2
;; Package-Version: 20191120.2218
;; Package-Commit: 1b563b450e5353797083bcb03ab02f456e9a7361
;; Keywords: flatbuffers languages

;; Installation:
;;   - Put `flatbuffers-mode.el' in your Emacs load-path.
;;   - Add this line to your .emacs file:
;;       (require 'flatbuffers-mode)
;;
;;; Code:

;; Font-locking definitions and helpers
(defconst flatbuffers-mode-keywords
  '("namespace" "root_type"))

(defconst flatbuffers-special-types
  '("double" "bool" "uint" "ulong"))

(defconst flatbuffers-re-ident "[[:word:][:multibyte:]_][[:word:][:multibyte:]_[:digit:]]*")

(defconst flatbuffers-re-generic
  (concat "<[[:space:]]*'" flatbuffers-re-ident "[[:space:]]*>"))

(defun flatbuffers-re-word (inner) (concat "\\<" inner "\\>"))
(defun flatbuffers-re-grab (inner) (concat "\\(" inner "\\)"))
(defun flatbuffers-re-shy (inner) (concat "\\(?:" inner "\\)"))
(defun flatbuffers-re-item-def (itype)
  (concat (flatbuffers-re-word itype)
	  (flatbuffers-re-shy flatbuffers-re-generic) "?"
	  "[[:space:]]+" (flatbuffers-re-grab flatbuffers-re-ident)))


(defvar flatbuffers-mode-font-lock-keywords
  (append
   `(
     ;; Keywords proper
     (,(regexp-opt flatbuffers-mode-keywords 'symbols) . font-lock-keyword-face)

     ;; Special types
     (,(regexp-opt flatbuffers-special-types 'symbols) . font-lock-type-face)

     ;; The keywords
     ("\\_<struct\\_>" . 'font-lock-keyword-face)
     ("\\_<table\\_>" . 'font-lock-keyword-face)
     ("\\_<enum\\_>" . 'font-lock-keyword-face)
     ("\\_<union\\_>" . 'font-lock-keyword-face)
     ("\\_<required\\_>" . 'font-lock-keyword-face)
     ("\\_<kek\\_>" . 'font-lock-keyword-face)

     (,(concat (flatbuffers-re-grab flatbuffers-re-ident) "[[:space:]]*:[^:]") 1 font-lock-variable-name-face)

     ;; Ensure we highlight `Foo' in a:Foo
     (,(concat ":[[:space:]]*" (flatbuffers-re-grab flatbuffers-re-ident)) 1 font-lock-type-face)
     )

    ;; Ensure we highlight `Foo` in `struct Foo` as a type.
    (mapcar #'(lambda (x)
                (list (flatbuffers-re-item-def (car x))
                      1 (cdr x)))
            '(("enum" . font-lock-type-face)
              ("struct" . font-lock-type-face)
              ("union" . font-lock-type-face)
              ("table" . font-lock-type-face))
     )))

;;;###autoload
(define-derived-mode flatbuffers-mode prog-mode "Flatbuffers"
  "Major mode for Flatbuffers code.

\\{flatbuffers-mode-map}"
  :group 'flatbuffers-mode
  ;; :syntax-table flatbuffers-mode-syntax-table

  ;; Fonts
  (setq-local font-lock-defaults '(flatbuffers-mode-font-lock-keywords
                                   nil nil nil nil
                                   (font-lock-syntactic-face-function . flatbuffers-mode-syntactic-face-function)
                                   ))
)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.fbs\\'" . flatbuffers-mode))

(defun flatbuffers-mode-reload ()
  (interactive)
  (unload-feature 'flatbuffers-mode)
  (require 'flatbuffers-mode)
  (flatbuffers-mode))

(provide 'flatbuffers-mode)

;;; flatbuffers-mode.el ends here
