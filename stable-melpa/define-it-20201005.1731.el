;;; define-it.el --- Define, translate, wiki the word  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Shen, Jen-Chieh
;; Created date 2019-10-24 11:18:00

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Define the word.
;; Keyword: dictionary explanation search wiki
;; Version: 0.2.4
;; Package-Version: 20201005.1731
;; Package-Commit: 57a9c601e732c85b0b45550434b04d996c1b92a3
;; Package-Requires: ((emacs "25.1") (s "1.12.0") (request "0.3.0") (popup "0.5.3") (pos-tip "0.4.6") (google-translate "0.11.18") (wiki-summary "0.1"))
;; URL: https://github.com/jcs-elpa/define-it

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Define, translate, wiki the word.
;;

;;; Code:

(require 'cl-lib)
(require 'dom)
(require 's)
(require 'subr-x)

(require 'request)
(require 'pos-tip)
(require 'popup)

(require 'google-translate)
(require 'wiki-summary)

(eval-when-compile
  ;; This stops the compiler from complaining.
  (defvar url-http-end-of-headers))

(defgroup define-it nil
  "Define the word."
  :prefix "define-it-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/define-it"))

(defcustom define-it-output-choice 'view
  "Option to show output."
  :type '(choice (const :tag "view" view)
                 (const :tag "pop" pop))
  :group 'define-it)

(defcustom define-it-show-header t
  "To display defining word on the top."
  :type 'boolean
  :group 'define-it)

(defcustom define-it-define-word-header "DEFINE\n\n"
  "Header for current defining word."
  :type 'string
  :group 'define-it)

(defcustom define-it-definition-header "\n\nDICTIONARY\n\n"
  "Header for dictionary definition."
  :type 'string
  :group 'define-it)

(defcustom define-it-translate-header "\n\nTRANSLATION\n\n"
  "Header to translation."
  :type 'string
  :group 'define-it)

(defcustom define-it-wiki-summary-header "\n\nWIKIPEDIA SUMMARY\n\n"
  "Header for wikipedia summary."
  :type 'string
  :group 'define-it)

(defcustom define-it-show-dictionary-definition t
  "Option to show dictionary definition."
  :type 'boolean
  :group 'define-it)

(defcustom define-it-show-google-translate t
  "Option to show google-translate."
  :type 'boolean
  :group 'define-it)

(defcustom define-it-show-wiki-summary t
  "Option to show wiki summary."
  :type 'boolean
  :group 'define-it)

(defcustom define-it-timeout 300
  "Time to hide tooltip after these seconds."
  :type 'integer
  :group 'define-its)

(defface define-it-pop-tip-color
  '((t (:foreground "#000000" :background "#FFF08A")))
  "Pop tip color, for graphic mode only."
  :group 'define-it)
(defvar define-it-pop-tip-color 'define-it-pop-tip-color)

(defface define-it-headline-face
  '((t (:foreground "gold4" :bold t :height 200)))
  "Face for headline."
  :group 'define-it)
(defvar define-it-headline-face 'define-it-headline-face)

(defface define-it-var-face
  '((t (:foreground "#17A0FB" :bold t)))
  "Face for synonyms."
  :group 'define-it)
(defvar define-it-var-face 'define-it-var-face)

(defface define-it-sense-number-face
  '((t (:foreground "#C12D51" :bold t)))
  "Face for sense number."
  :group 'define-it)
(defvar define-it-sense-number-face 'define-it-sense-number-face)

(defface define-it-type-face
  '((t (:foreground "#B5CCEB")))
  "Face for type."
  :group 'define-it)
(defvar define-it-type-face 'define-it-type-face)

(defvar define-it--define-timer nil
  "Timer for defining.")
(defvar define-it--update-time 0.1
  "Run every this seconds until all information is received.")

(defconst define-it--buffer-name-format "*define-it: %s*"
  "Format for buffer name.")

(defvar define-it--current-word "" "Record the search word.")

(defvar define-it--dictionary-it nil "Flag to check if dictionary search done.")
(defvar define-it--google-translated nil "Flag to check if google translated done.")
(defvar define-it--wiki-summarized nil "Flag to check if wiki summary done.")

(defvar define-it--dictionary-content "" "Dictionary content string.")
(defvar define-it--google-translated-content "" "Google translate content string.")
(defvar define-it--wiki-summary-content "" "Wiki summary content string.")

(defvar define-it--get-def-index 0 "Record index for getting definition order.")


(defun define-it--search-backward (str)
  "Seach backward from point for STR."
  (search-backward str nil t))

(defun define-it--search-forward (str)
  "Seach forward from point for STR."
  (search-forward str nil t))

(defun define-it--re-search-backward (regexp &optional case)
  "Seach backward from point for regular expression REGEXP with no error.
CASE are flag for `case-fold-search'."
  (let ((case-fold-search case))
    (re-search-backward regexp nil t)))

(defun define-it--re-search-forward (regexp &optional case)
  "Seach forward from point for regular expression REGEXP with no error.
CASE are flag for `case-fold-search'."
  (let ((case-fold-search case))
    (re-search-forward regexp nil t)))

(defun define-it--current-line-empty-p ()
  "Current line empty, but accept spaces/tabs in there."
  (save-excursion
    (beginning-of-line)
    (looking-at "[[:space:]\t]*$")))

(defun define-it--next-blank-line ()
  "Goto next blank line."
  (forward-line 1)
  (while (and (not (define-it--current-line-empty-p))
              (not (= (point) (point-max))))
    (forward-line 1)))

(defun define-it--next-not-blank-line ()
  "Goto next not blank line."
  (forward-line 1)
  (while (define-it--current-line-empty-p)
    (forward-line 1)))

(defun define-it--delete-line (n)
  "Delete N line from current point."
  (let ((index 0))
    (while (< index n)
      (setq index (1+ index))
      (delete-region (line-beginning-position)
                     (if (< (point-max) (1+ (line-end-position)))
                         (point-max)
                       (1+ (line-end-position)))))))

(defun define-it--line-match-p (regexp)
  "Check REGEXP with current line."
  (string-match-p regexp (thing-at-point 'line)))

(defun define-it--strip-string-from-buffer (str)
  "Strip the STR from current buffer."
  (goto-char (point-min))
  (let ((len (length str)))
    (while (define-it--search-forward str)
      (backward-char len)
      (delete-region (point) (1+ (line-end-position))))))

(defun define-it--strip-string-from-buffer-with-line (str)
  "Strip the STR from current buffer with line."
  (goto-char (point-min))
  (while (define-it--search-forward str)
    (beginning-of-line)
    (define-it--delete-line 1)))

(defun define-it--put-text-property-by-string (str fc)
  "Put the text property by STR and FC."
  (goto-char (point-min))
  (let ((st-pt -1) (end-pt -1))
    (while (define-it--re-search-forward str)
      (setq end-pt (point))
      (save-excursion
        (when (define-it--re-search-backward str)
          (setq st-pt (point))))
      (put-text-property st-pt end-pt 'face fc))))

(defun define-it--buffer-replace (fnc)
  "FNC should return a string to replace current buffer."
  (let ((current-content (buffer-string)))
    (delete-region (point-min) (point-max))  ; Remove all content.
    (insert (funcall fnc current-content))))

(defun define-it--through-buffer-by-line (fnc)
  "Go through buffer by line and execute FNC on each line."
  (goto-char (point-min))
  (while (not (= (point) (point-max)))
    (funcall fnc (thing-at-point 'line))
    (forward-line 1)))

(defun define-it--through-buffer-by-blank-line (fnc)
  "Go through buffer by blank line and execute FNC on each line."
  (goto-char (point-min))
  (while (not (= (point) (point-max)))
    (funcall fnc (thing-at-point 'line))
    (define-it--next-blank-line)))

(defun define-it--fix-gap-between-same-sections (str)
  "Fixed the same sections' gap lines by STR."
  (define-it--through-buffer-by-blank-line
    (lambda (_line)
      (let ((last-line-str nil) (next-line-str nil))
        (save-excursion
          (forward-line -1)
          (setq last-line-str (define-it--line-match-p str)))
        (save-excursion
          (forward-line 1)
          (setq next-line-str (define-it--line-match-p str)))
        (when (and next-line-str last-line-str) (define-it--delete-line 1))))))

(defun define-it--parse-dictionary (data)
  "Parse dictionary HTML from DATA."
  (let ((content "") (dom nil) (text ""))
    (setq
     content
     (with-temp-buffer
       (insert data)
       (setq dom (libxml-parse-html-region (point-min) (point-max)))
       (delete-region (point-min) (point-max))  ; Remove all content.
       (setq text (dom-texts (dom-by-class dom "dictentry")))
       (setq text (s-replace-regexp "\\(^\\s-*$\\)\n" "\n" text))
       (insert text)
       (progn  ; Start tweeking buffer.
         (progn  ; Removed useless header section.
           (goto-char (point-min))
           (while (define-it--search-forward "Word Frequency")
             (define-it--delete-line 1)
             (let ((word-pt (point)))
               (define-it--search-forward define-it--current-word)
               (delete-region word-pt (point)))))
         (progn  ; Removed Copyright.
           (define-it--strip-string-from-buffer-with-line "Copyright")
           (define-it--strip-string-from-buffer-with-line "All rights reserved"))
         (progn  ; Removed embedded scripts. (For AdBlock)
           (goto-char (point-min))
           (while (define-it--search-forward "googletag.cmd")
             ;; Code is always 12 line embedded.
             (define-it--delete-line 12)))
         (progn
           (define-it--strip-string-from-buffer "    More Synonyms of")
           (define-it--strip-string-from-buffer "More Synonyms of"))
         (progn
           (goto-char (point-min))
           (let ((case-fold-search nil))
             (while (define-it--re-search-forward "[0-9]+[. ]+[^A-Z0-9]+")
               (save-excursion
                 (define-it--re-search-backward "[0-9]+[. ]+[^A-Z0-9]+")
                 (while (not (string= (string (char-before)) " ")) (forward-char -1))
                 (insert "\n\n"))
               (insert "\n\n"))))
         (progn  ; Minimize sense number.
           (goto-char (point-min))
           (while (define-it--re-search-forward "[0-9]+[.  ]+")
             (define-it--next-not-blank-line)
             (let ((st-pt (line-beginning-position)) (end-pt -1)
                   (old-content "") (new-content ""))
               (ignore-errors (search-forward-regexp "^[ \t]*\n"))
               (forward-line -1)
               (setq end-pt (line-end-position))
               (setq old-content (buffer-substring st-pt end-pt))
               (setq new-content (s-replace-regexp "[ ]*\n[ ]*" " " old-content))
               (delete-region st-pt end-pt)
               (insert (format "%s\n" new-content)))))
         ;; Pretty syntax
         (define-it--buffer-replace
           (lambda (current-content)
             (setq current-content (s-replace "]  " "]  \n\n" current-content))
             (setq current-content (s-replace-regexp "[ ]+" " " current-content))
             (setq current-content (s-replace-regexp "[ ]+[.]" "." current-content))
             (setq current-content (s-replace-regexp "[ \n]*,[ \n]*" ", " current-content))
             (setq current-content (s-replace-regexp "Synonyms:[ ]*\n " "Synonyms: " current-content))
             (setq current-content (s-replace-regexp "[ ]*Synonyms:[ ]*" "Synonyms: " current-content))
             (setq current-content (s-replace-regexp "Synonyms: " "  Synonyms: " current-content))
             (setq current-content (s-replace-regexp "Synonyms: " "\n\n  Synonyms: " current-content))
             (setq current-content (s-replace-regexp "[ \n]*[[] " " [ " current-content))
             (setq current-content (s-replace-regexp "[ \n]+)" " )" current-content))
             (setq current-content (s-replace-regexp "  " " " current-content))
             (setq current-content (s-replace " " "" current-content))
             ;; Cleaned last trailing empty lines with `string-trim'.
             (setq current-content (s-replace-regexp "\\(^\\s-*$\\)\n" "\n" (string-trim current-content)))
             current-content))
         ;; Fixed missing headline
         (progn
           (goto-char (point-min))
           (while (define-it--re-search-forward "^[0-9]+[.]+[ ]*")
             (when (= (line-end-position) (point))
               (delete-char 1))))
         ;; Split all ]
         (progn
           (goto-char (point-min))
           (while (define-it--re-search-forward "[]][ ][^\n]")
             (forward-char -1)
             (insert "\n")))
         ;; Add Example
         (let ((blank-line-count 0))
           (define-it--through-buffer-by-line
             (lambda (line)
               (if (or (string-match-p "[0-9]+[.] " line) (string-match-p "[:]" line))
                   (setq blank-line-count 0)
                 (let ((blank-ln (define-it--current-line-empty-p)))
                   ;; Found example.
                   (when (and (= blank-line-count 2) (not blank-ln))
                     (move-to-column 0) (insert " Example: "))
                   (when blank-ln (setq blank-line-count (1+ blank-line-count))))))))
         ;; Post process
         (define-it--buffer-replace
           (lambda (current-content)
             (setq current-content (s-replace "  " " " current-content))
             (setq current-content (s-replace "[^ ]\n[^ ]" " " current-content))
             (setq current-content (s-replace-regexp "[.][^\n][\n]*See" ". See" current-content))
             (setq current-content (s-replace-regexp "\\(^\\s-*$\\)\n" "\n" current-content))
             current-content))
         ;; Fix Synonyms and Example gap.
         (define-it--fix-gap-between-same-sections "Synonyms:")
         (define-it--fix-gap-between-same-sections "Example:")
         ;; Fix definition
         (let ((blank-line-count 0))
           (define-it--through-buffer-by-line
             (lambda (line)
               (if (or (string-match-p "[0-9]+[.] " line) (string-match-p "[:]" line))
                   (setq blank-line-count 0)
                 (let ((blank-ln (define-it--current-line-empty-p)))
                   ;; Found definition.
                   (when (and (= blank-line-count 1) (not blank-ln))
                     (let ((st-pt -1) (end-pt -1) (old-content "") (new-content ""))
                       (setq st-pt (line-beginning-position))
                       (save-excursion
                         (define-it--next-blank-line)
                         (forward-line -1)
                         (setq end-pt (line-end-position)))
                       (setq old-content (buffer-substring st-pt end-pt))
                       (delete-region st-pt end-pt)
                       (setq new-content (s-replace "\n" " " old-content))
                       (setq new-content (s-replace "  " " " new-content))
                       (insert new-content)))
                   (when blank-ln (setq blank-line-count (1+ blank-line-count))))))))
         ;; Fixed missing line break
         (progn
           (goto-char (point-min))
           (while (define-it--re-search-forward "[A-Z][a-z]")
             (let ((in-block nil))
               (save-excursion
                 (forward-char -2)
                 (setq in-block (looking-back "[[\n.][a-zA-Z ]*" -10))
                 (when (and (not in-block) (not (define-it--line-match-p "[:]")))
                   (insert "\n * "))))))
         (define-it--through-buffer-by-line
           (lambda (_line)
             (let ((last-line-char nil) (next-char nil))
               (save-excursion
                 (forward-line -1)
                 (move-to-column (1- (line-end-position)))
                 (setq last-line-char (char-before)))
               (save-excursion
                 (move-to-column 1)
                 (setq next-char (char-before)))
               (when (and
                      last-line-char next-char
                      (not (string-match-p "[ \n]" (string last-line-char)))
                      (not (string-match-p "[ \n]" (string next-char))))
                 (ignore-errors (delete-char -1))
                 (insert " ")))))
         ;; Propertize text.
         (progn
           (define-it--put-text-property-by-string "Word forms:" define-it-var-face)
           (define-it--put-text-property-by-string "Example:" define-it-var-face)
           (define-it--put-text-property-by-string "Synonyms:" define-it-var-face)
           (define-it--put-text-property-by-string "Phrasal verbs:" define-it-var-face)
           (define-it--put-text-property-by-string "^[0-9]+[.][^\n]+" define-it-sense-number-face)
           (define-it--put-text-property-by-string "[[][a-zA-Z +-=_]*[]]" define-it-type-face)))
       (buffer-string)))
    content))

(defun define-it--get-dictionary-definition-as-string (search-str)
  "Return the dictionary definition as a string with SEARCH-STR."
  (setq define-it--dictionary-it nil)
  (request
    (format "https://www.collinsdictionary.com/dictionary/english/%s" search-str)
    :type "GET"
    :parser 'buffer-string
    :success
    (cl-function
     (lambda (&key data &allow-other-keys)
       (setq define-it--dictionary-it t)
       (setq define-it--dictionary-content
             (if (string-match-p "Sorry, no results" data)
                 "No definition found"
               (define-it--parse-dictionary data)))))
    :error
    ;; NOTE: Accept, error.
    (cl-function
     (lambda (&rest args &key _error-thrown &allow-other-keys)
       (setq define-it--dictionary-it t)))))

(defun define-it--get-google-translate-as-string (search-str)
  "Return the google translate as a string with SEARCH-STR."
  (setq define-it--google-translated nil)
  (let* ((langs (google-translate-read-args nil nil))
         (source-language (car langs))
         (target-language (cadr langs))
         (kill-ring kill-ring))  ; Preserved `kill-ring'.
    (google-translate-translate source-language target-language search-str 'kill-ring)
    (message "")  ; Clear the annoying minibuffer display.
    (setq define-it--google-translated-content (nth 0 kill-ring)))
  (setq define-it--google-translated t))

(defun define-it--get-wiki-summary-as-string (search-str)
  "Return the wiki summary as a string with SEARCH-STR."
  (setq define-it--wiki-summarized nil)
  (url-retrieve
   (wiki-summary/make-api-query search-str)
   (lambda (_events)
     (message "")  ; Clear the annoying minibuffer display.
     (goto-char url-http-end-of-headers)
     (let* ((json-object-type 'plist) (json-key-type 'symbol) (json-array-type 'vector)
            (result (json-read))
            (summary (wiki-summary/extract-summary result)))
       (setq define-it--wiki-summary-content (if summary summary "No article found")))
     (setq define-it--wiki-summarized t))))

(defun define-it--show-count ()
  "Check how many services is showing."
  (let ((counter 0))
    (when define-it-show-dictionary-definition (setq counter (1+ counter)))
    (when define-it-show-google-translate (setq counter (1+ counter)))
    (when define-it-show-wiki-summary (setq counter (1+ counter)))
    counter))

(defun define-it--form-title-format ()
  "Form the title format."
  (if define-it-show-header
      (format "%s%s"
              (propertize define-it-define-word-header 'face define-it-headline-face)
              define-it--current-word)
    ""))

(defun define-it--form-info-format ()
  "Form the info format."
  (let ((index 0) (count (define-it--show-count))
        (output ""))
    (while (< index count)
      (setq output (concat output "%s"))
      (setq index (1+ index)))
    output))

(defun define-it--return-info-by-start-index (index)
  "Return the info pointer by start INDEX."
  (let ((info-ptr "") (start index))
    (setq
     info-ptr
     (cl-case start
       (0 (if define-it-show-dictionary-definition
              (format "%s%s"
                      (propertize define-it-definition-header 'face define-it-headline-face)
                      define-it--dictionary-content)
            nil))
       (1 (if define-it-show-google-translate
              (format "%s%s"
                      (propertize define-it-translate-header 'face define-it-headline-face)
                      define-it--google-translated-content)
            nil))
       (2 (if define-it-show-wiki-summary
              (format "%s%s"
                      (propertize define-it-wiki-summary-header 'face define-it-headline-face)
                      define-it--wiki-summary-content)
            nil))
       (t "")))  ; Finally returned something to prevent error/infinite loop.
    (if info-ptr
        (setq define-it--get-def-index (1+ start))  ; Add one, ready for next use.
      (setq start (1+ start))
      (setq info-ptr (define-it--return-info-by-start-index start)))
    info-ptr))

(defun define-it--get-definition ()
  "Use all services/resources to get the definition string."
  (let ((define-it--get-def-index 0))
    (string-trim
     (format
      (concat (define-it--form-title-format) (define-it--form-info-format))
      (define-it--return-info-by-start-index define-it--get-def-index)
      (define-it--return-info-by-start-index define-it--get-def-index)
      (define-it--return-info-by-start-index define-it--get-def-index)))))

(cl-defun define-it--in-pop (content &key point)
  "Define in the pop with CONTENT.
The location POINT.  TIMEOUT for not forever delay."
  (if (display-graphic-p)
      (progn
        (pos-tip-show
         (pos-tip-fill-string content (frame-width))
         define-it-pop-tip-color point nil define-it-timeout)
        (define-it--kill-timer))
    (popup-tip content :point point :around t :scroll-bar t :margin t)))

(defun define-it--in-buffer (content)
  "Define in the buffer with CONTENT."
  (let* ((name (format define-it--buffer-name-format define-it--current-word))
         (buf (if (get-buffer name) (get-buffer name) (generate-new-buffer name))))
    (with-current-buffer buf
      (view-mode -1)
      (delete-region (point-min) (point-max))  ; Remove all content.
      (insert content) (insert "\n")
      (goto-char (point-min))
      (view-mode 1)
      (visual-line-mode 1))
    (save-selected-window (pop-to-buffer buf))))

(defun define-it--received-info-p ()
  "Check if received all informations."
  (let ((checker t))
    (when define-it-show-dictionary-definition
      (unless define-it--dictionary-it (setq checker nil)))
    (when define-it-show-google-translate
      (unless define-it--google-translated (setq checker nil)))
    (when define-it-show-wiki-summary
      (unless define-it--wiki-summarized (setq checker nil)))
    checker))

(defun define-it--display-info ()
  "Display the info after receving all necessary information."
  (if (define-it--received-info-p)
      (let* ((content (define-it--get-definition)))
        (cl-case define-it-output-choice
          ('pop (define-it--in-pop content :point (point)))
          (t (define-it--in-buffer content))))
    (define-it--reset-timer)))

(defun define-it--kill-timer ()
  "Kill the timer."
  (when (timerp define-it--define-timer)
    (cancel-timer define-it--define-timer)
    (setq define-it--define-timer nil)))

(defun define-it--reset-timer ()
  "Reset the timer for searching."
  (define-it--kill-timer)
  (setq define-it--define-timer
        (run-with-timer define-it--update-time nil 'define-it--display-info)))

(defun define-it--register-events (word)
  "Call all events for receving all info depends WORD."
  (when define-it-show-dictionary-definition
    (define-it--get-dictionary-definition-as-string word))
  (when define-it-show-google-translate
    (define-it--get-google-translate-as-string word))
  (when define-it-show-wiki-summary
    (define-it--get-wiki-summary-as-string word)))

;;;###autoload
(defun define-it (word)
  "Define by inputing WORD."
  (interactive "MWord: ")
  (when (string-empty-p word) (user-error "[WARNINGS] Invalid search string: %s" word))
  (let ((show-count (define-it--show-count)))
    (when (= 0 show-count) (user-error "[CONFIG] Nothing to show: %s" show-count)))
  (setq define-it--current-word word)
  (define-it--register-events word)
  (define-it--reset-timer))

;;;###autoload
(defun define-it-at-point ()
  "Use `define-it' to define word at point."
  (interactive)
  (if (use-region-p)
      (define-it (buffer-substring-no-properties (region-beginning) (region-end)))
    (define-it (ignore-errors (substring-no-properties (thing-at-point 'word))))))

(provide 'define-it)
;;; define-it.el ends here
