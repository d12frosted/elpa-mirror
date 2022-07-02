;;; markless.el --- Major mode for Markless documents -*- lexical-binding: t; -*-

;; Copyright (c) 2019 Nicolas Hafner
;;
;; Author: Nicolas Hafner <shinmera@tymoon.eu>
;; URL: http://github.com/shirakumo/markless.el/
;; Package-Version: 20220702.1154
;; Package-Commit: 9c846f58575a446812f7bade284021b625976757
;; Package-Requires: ((emacs "24.4"))
;; Version: 1.0
;; Keywords: languages, wp

;; This file is not part of GNU Emacs.

;;; License:
;; Licensed under the Artistic License 2.0

;;; Commentary:
;;
;; This package implements a major mode for Markless
;; documents.  Markless is a new document markup
;; standard.  You can find the Markless standard at
;;
;;   https://github.com/shirakumo/Markless
;;   https://shirakumo.github.io/markless
;;
;; This does *not* implement a full Markless parser
;; that is compliant with the specification.  It uses
;; a simplified grammar that should be adequate for
;; syntax highlighting.

;;; Code:

(require 'font-lock)
(require 'cl-lib)
(require 'url-parse)
(require 'thingatpt)

(defvar flyspell-generic-check-word-predicate)

(defconst markless-url-regex "[[:alpha:]][[:alnum:]+\\-.]*://[[:alnum:]$\\-_.+!*'()&,/:;=?@%#\\\\]+"
  "Regex to match URLs as specified by Markless.")

(defvar markless-mode-map
  (let ((map (make-keymap)))
    map)
  "Keymap for the Markless mode.")

(defvar markless-mode-mouse-map
  (let ((map (make-sparse-keymap)))
    (define-key map [follow-link] 'mouse-face)
    (define-key map [mouse-2] 'markless-follow-link-at-point)
    map)
  "Keymap for mouse interactions in Markless mode.")

(defgroup markless nil
  "Markless settings"
  :group 'text
  :link '(url-link "https://github.com/shirakumo/markless.el"))

(defgroup markless-faces nil
  "Faces used in Markless mode"
  :group 'markless
  :group 'faces)

(defmacro markless--defface (name prop &optional doc)
  "Shorthand to define faces.
NAME PROP DOC, shut up, checkdoc."
  `(defface ,name
       '((t ,prop))
     ,(or doc "")
     :group 'markless-faces))

(markless--defface markless-markup-face (:inherit shadow))
(markless--defface markless-italic-face (:inherit italic))
(markless--defface markless-bold-face (:inherit bold))
(markless--defface markless-underline-face (:underline t))
(markless--defface markless-strikethrough-face (:strike-through t))
(markless--defface markless-literal-face (:inherit (font-lock-constant-face fixed-pitch)))
(markless--defface markless-url-face (:inherit link))
(markless--defface markless-spoiler-face (:background "black" :foreground "black"))
(markless--defface markless-quote-source-face (:inherit font-lock-variable-name-face))
(markless--defface markless-quote-face (:inherit font-lock-doc-face))
(markless--defface markless-instruction-face (:inherit font-lock-function-name-face))
(markless--defface markless-keyword-face (:inherit font-lock-type-face))
(markless--defface markless-warning-face (:inherit font-lock-warning-face))
(markless--defface markless-error-face (:inherit font-lock-warning-face))
(markless--defface markless-comment-face (:inherit font-lock-comment-face))
(markless--defface markless-embed-face (:inherit font-lock-type-face))
(markless--defface markless-list-mark-face (:inherit markless-markup-face))
(markless--defface markless-footnote-face (:inherit markless-quote-face))
(markless--defface markless-highlight-face (:inherit highlight))

(cl-defun markless-mark (start end prop)
  "Shorthand to mark up a text between START and END with PROP."
  (if (or (symbolp prop) (keywordp (car prop)))
      (add-face-text-property start end prop)
      (add-text-properties start end prop)))

(cl-defun markless-match (string)
  "Attempt to match STRING.  If successful, return t.

This does not alter the point."
  (when (<= (+ (point) (length string)) (point-max))
    (cl-loop for i from (point)
             for char across string
             always (= char (char-after i)))))

(cl-defun markless-num-p (point)
  "Return t if the char at POINT is a numeric char."
  (<= ?0 (char-after point) ?9))

(cl-defun markless-inline-directive (pre post prop)
  "Process the inline directive recursively.

If PRE matches, recurses until POST is found.
Marks PRE and POST as markup and the content with PROP."
  (when (markless-match pre)
    (let ((start (point)))
      (forward-char (length pre))
      (markless-mark start (point) 'markless-markup-face)
      (cond ((markless-match-inline post)
             (markless-mark (point) (+ (point) (length post)) 'markless-markup-face)
             (markless-mark (+ start (length pre)) (point) prop)
             (forward-char (length post)))
            (t
             (markless-mark (+ start (length pre)) (point) prop)))
      t)))

(cl-defun markless-parse-option (option)
  "Parse the compound OPTION to a face."
  (cond ;; Font style names
        ((string= option "bold") 'markless-bold-face)
        ((string= option "italic") 'markless-italic-face)
        ((string= option "underline") 'markless-underline-face)
        ((string= option "strikethrough") 'markless-strikethrough-face)
        ((string= option "spoiler") 'markless-spoiler-face)
        ;; Colour names
        ((color-defined-p option)
         `(:foreground ,option))
        ;; Font size names
        ((string= option "microscopic") `(:height 0.25))
        ((string= option "tiny") `(:height 0.5))
        ((string= option "small") `(:height 0.8))
        ((string= option "normal") `(:height 1.0))
        ((string= option "big") `(:height 1.5))
        ((string= option "large") `(:height 2.0))
        ((string= option "huge") `(:height 2.5))
        ((string= option "gigantic") `(:height 4.0))
        ;; Complex options
        ((string-prefix-p "font" option)
         `(:family ,(cl-subseq option 5)))
        ((string-prefix-p "color" option)
         (if (= ?# (aref option 6))
             `(:foreground ,(cl-subseq option 6))
             (let ((rgb (mapcar #'string-to-number
                                (split-string (cl-subseq option 6) " +"))))
               `(:foreground ,(apply 'format "#%02x%02x%02x" rgb)))))
        ((string-prefix-p "size" option)
         (let ((size (cl-subseq option 5 (- (length option) 2)))
               (unit (cl-subseq option (- (length option) 2))))
           (if (string= unit "em")
               `(:height ,(float (string-to-number size)))
               `(:height ,(round (* 10 (string-to-number size)))))))
        ((or (string-prefix-p "link" option)
             (string-match markless-url-regex option))
         'markless-url-face)))

(cl-defun markless-compute-options-faces (options)
  "Parse the list of compound OPTIONS to a list of faces."
  (cl-loop for option in options
           for face = (markless-parse-option option)
           when face collect face))

(cl-defun markless-match-inline (&optional end)
  "Markup inline directives until the END is matched or until the end of line is found."
  (cl-loop
   (or (when (= (point) (point-at-eol))
         (cl-return-from markless-match-inline nil))
       (when (and end (markless-match end))
         (cl-return-from markless-match-inline t))
       (markless-inline-directive "**" "**" 'markless-bold-face)
       (markless-inline-directive "//" "//" 'markless-italic-face)
       (markless-inline-directive "__" "__" 'markless-underline-face)
       (markless-inline-directive "``" "``" 'markless-literal-face)
       (markless-inline-directive "<-" "->" 'markless-strikethrough-face)
       (markless-inline-directive "v(" ")" '(display ((raise -0.2) (height 0.9))))
       (markless-inline-directive "^(" ")" '(display ((raise +0.2) (height 0.9))))
       (when (markless-match "\"")
         (let ((start (point)))
           (forward-char)
           (when (markless-match-inline "\"(")
             (markless-mark start (1+ start) 'markless-markup-face)
             (let ((end (point)))
               (re-search-forward ")" (point-at-eol) t)
               (markless-mark end (point) 'markless-markup-face)
               (let ((options (split-string (buffer-substring (+ end 2) (1- (point))) ", *")))
                 (dolist (face (markless-compute-options-faces options))
                   (markless-mark (1+ start) end face)))))))
       (forward-char))))

(cl-defun markless-in-code-block-p ()
  "Return t if the `point' is within a code block."
  (let ((middle (point-at-bol))
        (block-size nil))
    (cl-flet ((find-block-size ()
               (let ((start (point)))
                 (cl-loop while (and (< (point) (point-max)) (= ?: (char-after (point))))
                          do (forward-char))
                 (- (point) start))))
      (save-excursion
       (goto-char (point-min))
       (cl-loop until (or (and (not block-size)
                               (<= middle (point)))
                          (< middle (point)))
                do (when (markless-match "::")
                     (cond ((null block-size)
                            (setq block-size (find-block-size)))
                           ((and (= block-size (find-block-size))
                                 (= (point) (point-at-eol)))
                            (setq block-size nil))))
                (forward-line))
       (not (null block-size))))))

(cl-defun markless-header-scale-factor (depth)
  "Return the relative font height scaling factor for a header of DEPTH."
  (+ 1.0 (/ (expt (max 0 (- 6 depth)) 2)
            30.0)))

(cl-defun markless-match-block (end)
  "Markup block directives until the end of the line or `point-max'."
  (when (markless-in-code-block-p)
    (markless-mark (point) (point-at-eol) 'markless-literal-face)
    (move-end-of-line 1)
    (cl-return-from markless-match-block))
  (cl-loop while (and (< (point) end) (= ?  (char-after (point))))
           do (forward-char))
  (cond ((markless-match "#")
         (let ((start (point)))
           (cl-loop while (and (< (point) (point-max)) (= ?# (char-after (point))))
                    do (forward-char))
           (cond ((= ?  (char-after (point)))
                  (let ((depth (- (point) start)))
                    (markless-mark start (point) 'markless-markup-face)
                    (markless-mark start (point-at-eol) (list :height (markless-header-scale-factor depth)))
                    (markless-match-inline)))
                 (t
                  (goto-char start)
                  (markless-match-inline)))))
        ((markless-match "~ ")
         (markless-mark (point) (+ 2 (point)) 'markless-quote-source-face)
         (forward-char 2)
         (markless-match-inline))
        ((markless-match "| ")
         (markless-mark (point) (point-at-eol) 'markless-quote-face)
         (forward-char 2)
         (markless-match-block end))
        ((markless-match "[ ")
         (let ((start (point)))
           (move-end-of-line 1)
           (markless-mark start (point) 'markless-embed-face)))
        ((markless-match "! ")
         (let ((start (point)))
           (move-end-of-line 1)
           (markless-mark start (point) 'markless-instruction-face)))
        ((markless-match "; ")
         (let ((start (point)))
           (move-end-of-line 1)
           (markless-mark start (point) 'markless-comment-face)))
        ((markless-match "::")
         (let ((start (point)))
           (move-end-of-line 1)
           (markless-mark start (point) 'markless-markup-face)))
        ((markless-match "==")
         (let ((start (point)))
           (move-end-of-line 1)
           (markless-mark start (point) 'markless-markup-face)))
        ((and (markless-match "[") (markless-num-p (1+ (point))))
         (let ((start (point)))
           (forward-char)
           (cl-loop while (and (< (point) (point-max)) (markless-num-p (point)))
                    do (forward-char))
           (cond ((= ?\] (char-after (point)))
                  (forward-char)
                  (markless-mark start (point-at-eol) 'markless-footnote-face)
                  (markless-match-inline))
                 (t
                  (goto-char start)
                  (markless-match-inline)))))
        ((markless-match "- ")
         (markless-mark (point) (+ 2 (point)) 'markless-list-mark-face)
         (forward-char 2)
         (markless-match-block end))
        ((markless-num-p (point))
         (let ((start (point)))
           (cl-loop while (and (< (point) (point-max)) (markless-num-p (point)))
                    do (forward-char))
           (cond ((= ?. (char-after (point)))
                  (forward-char)
                  (markless-mark start (point) 'markless-list-mark-face)
                  (markless-match-block end))
                 (t
                  (goto-char start)
                  (markless-match-inline)))))
        (t
         (markless-match-inline))))

(cl-defun markless-fontify (end)
  "Generate markup for Markless until END."
  (cl-loop while (< (point) end)
           do (markless-match-block end)
           (when (< (point) end)
             (forward-char))))

(cl-defun markless-fontify-url (end)
  "Markup URLs until the END."
  (when (re-search-forward markless-url-regex end t)
    (goto-char (1+ (match-end 0)))
    (let ((props `(keymap ,markless-mode-mouse-map
                          face markless-url-face
                          mouse-face markless-highlight-face
                          rear-nonsticky t
                          font-lock-multiline t)))
      (add-text-properties (match-beginning 0) (match-end 0) props)
      t)))

(cl-defun markless-follow-link-at-point ()
  "Follow the URL at the current point, if any."
  (interactive)
  (if (thing-at-point-looking-at markless-url-regex)
      (let* ((url (match-string 0))
             (struct (url-generic-parse-url url)))
        (if (url-fullness struct)
            (browse-url url)
            (let ((file (car (url-path-and-query struct))))
              (when (and file (< 0 (length file))) (find-file file)))))
      (user-error "Point is not at a link or URL")))

(cl-defun markless-at-word-p ()
  "Return t if the current point is a word that should be spell-checked."
  (not (let ((faces (get-text-property (point) 'face)))
         (unless (listp faces) (setq faces (list faces)))
         (or (memq 'markless-url-face faces)
             (memq 'markless-literal-face faces)
             (memq 'markless-keyword-face faces)
             (memq 'markless-embed-face faces)
             (memq 'markless-markup-face faces)))))

(defvar markless-font-lock-keywords '((markless-fontify-url)
                                      (markless-fontify))
  "Font lock keywords for Markless mode.")

;;;###autoload
(define-derived-mode markless-mode text-mode "Markless"
  "Major mode for Markless documents."
  (setq font-lock-defaults '(markless-font-lock-keywords
                             nil nil nil nil
                             (font-lock-multiline . t)))
  (setq-local flyspell-generic-check-word-predicate
              #'markless-at-word-p)
  (setq-local comment-start ";")
  (setq-local comment-start-skip ";+ ")
  (setq-local paragraph-start
              (mapconcat #'identity
                         '(
                           "\f" ; linefeed
                           "[ \t\f]*$" ; whitespace-only line
                           "[ \t]*\|[ \t\f]*$" ; empty blockquote line
                           "[ \t]*-[ \t]+" ; unordered list item
                           "[ \t]*[0-9]+\\.[ \t]+" ; ordered list item
                           "\\[[0-9]+\\]" ; footnote
                           )
                         "\\|"))
  (setq-local paragraph-separate
              (mapconcat #'identity
                         '(
                           "\\([ \t]*\\|| \\)+~[ \t]*" ; blockquote header
                           "\\([ \t]*\\|| \\)+$" ; empty (blockquote) line
                           "\\([ \t]*\\|| \\)+#+" ; heading
                           "\\([ \t]*\\|| \\)+! " ; instruction
                           "\\([ \t]*\\|| \\)+;+ " ; comment
                           "\\([ \t]*\\|| \\)+\\[ " ; embed
                           "\\([ \t]*\\|| \\)+==+" ; horizontal rule
                           "\\([ \t]*\\|| \\)+[\d+] " ; footnote
                           )
                         "\\|")))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.mess\\'" . markless-mode))
(add-to-list 'auto-mode-alist '("\\.spess\\'" . markless-mode))

(provide 'markless)

;;; markless.el ends here
