;;; inline-docs.el --- Show inline contextual docs.

;; Author: stardiviner <numbchild@gmail.com>
;; Keywords: inline docs overlay
;; Package-Version: 20220210.1402
;; Package-Commit: cda596d9ff4c2aa5035692a97c430f6589eafbb1
;; URL: https://repo.or.cz/inline-docs.git
;; Created: 20th Jan 2017
;; Version: 1.0.1
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; This is a library for showing inline contextual docs above or below.
;;
;; You can use this library function `inline-docs` in packages like
;; https://repo.or.cz/eldoc-overlay.git
;;
;; ```eldoc
;; (setq eldoc-message-function #'inline-docs)
;; ```
;;
;; ```elisp
;; (inline-docs "FORMATED-STRING")
;; (inline-docs "STRING")
;; ```

;;; Code:
;;; ----------------------------------------------------------------------------

(require 'cl-lib)

(defvar inline-docs-overlay nil)

(defgroup inline-docs nil
  "Show inline contextual docs."
  :group 'docs)

(defcustom inline-docs-position 'above
  "Specify inline-docs display position, up or down.

Set `inline-docs-position' to `up' to fix issue that `inline-docs' does not show on single line which don't has next line."
  :type '(choice
          :tag "Specify inline-docs display position."
          (const :tag "up" above)
          (const :tag "down" below))
  :group 'inline-docs)

(defcustom inline-docs-border-symbol ?―
  "Specify symbol for inline-docs border."
  :type 'character
  :group 'inline-docs)

(defcustom inline-docs-prefix-symbol ?\s
  "Specify symbol for inline-docs prefix."
  :type 'character
  :group 'inline-docs)

(defcustom inline-docs-indicator-symbol "➜"
  "Specify symbol for inline-docs indicator."
  :type 'character
  :group 'inline-docs)

(defface inline-docs-face
  '((t (:inherit font-lock-string-face)))
  "Face for `inline-docs-mode'."
  :group 'inline-docs)

(defface inline-docs-border-face
  '((t (:inherit font-lock-doc-face)))
  "Face for inline docs border lines."
  :group 'inline-docs)

(defface inline-docs-prefix-face
  '((t (:inherit default)))
  "Face for inline docs prefix."
  :group 'inline-docs)

(defface inline-docs-indicator-face
  '((t (:inherit font-lock-doc-face)))
  "Face for inline docs indicator."
  :group 'inline-docs)

(defun inline-docs--clear-overlay ()
  "Clear inline-docs overlays."
  (when (overlayp inline-docs-overlay)
    (delete-overlay inline-docs-overlay))
  (remove-hook 'post-command-hook 'inline-docs--clear-overlay))

(defun inline-docs--string-display (string apply-face)
  "Show STRING contents below point line until next command with APPLY-FACE."
  (let* ((border-line (make-string (window-body-width) inline-docs-border-symbol))
         (offset (make-string
                  (if (= (current-indentation) 0) ; fix (wrong-type-argument wholenump -1) when current indentation is 0 minus 1 will caused wholenump exception.
                      (current-indentation)
                    (- (current-indentation) 1))
                  inline-docs-prefix-symbol))
         (str (concat (propertize border-line
                                  'face 'inline-docs-border-face)
                      "\n"
                      offset
                      (propertize (concat inline-docs-indicator-symbol " ")
                                  'face 'inline-docs-indicator-face)
                      (copy-sequence string) ; original eldoc string with format.
                      "\n"
                      (propertize border-line
                                  'face 'inline-docs-border-face)
                      "\n"
                      ))
         start-pos end-pos)
    (unwind-protect
        (save-excursion
          ;; clear overlay
          (inline-docs--clear-overlay)
          ;; decide overlay positions
          (cl-case inline-docs-position
            ('above (forward-line 0))
            ('below (forward-line)))
          (setq start-pos (point))
          (end-of-line)
          (setq end-pos (point))
          ;; create overlay
          (setq inline-docs-overlay (make-overlay start-pos end-pos (current-buffer)))
          ;; change the face
          (if apply-face
              (overlay-put inline-docs-overlay 'face 'inline-docs-face))
          ;; hide full line
          ;; (overlay-put inline-docs-overlay 'display "")
          ;; (overlay-put inline-docs-overlay 'display :height 20)
          ;; pre-pend indentation spaces
          ;; (overlay-put inline-docs-overlay 'line-prefix prefix)
          ;; auto delete overlay
          (overlay-put inline-docs-overlay 'evaporate t)
          ;; display message
          (overlay-put inline-docs-overlay 'before-string str))
      (add-hook 'post-command-hook 'inline-docs--clear-overlay))))

;;;###autoload
(defun inline-docs-display-docs-momentary (format-string &rest args)
  "Display inline docs FORMAT-STRING under point with extra ARGS."
  (when format-string
    (inline-docs--string-display
     (apply 'format format-string args)
     t)))

;;;###autoload
(defalias 'inline-docs 'inline-docs-display-docs-momentary)

;;; ----------------------------------------------------------------------------

(provide 'inline-docs)

;;; inline-docs.el ends here
