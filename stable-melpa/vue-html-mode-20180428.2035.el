;;; vue-html-mode.el --- Major mode for editing Vue.js templates

;; Copyright 2016, 2017 Adam Niederer

;; Author: Adam Niederer <adam.niederer@gmail.com>
;; URL: http://github.com/AdamNiederer/vue-html-mode
;; Package-Version: 20180428.2035
;; Package-Commit: 1514939804bad558584feeb6298b38d22eadf64e
;; Version: 0.2.0
;; Keywords: languages vue template
;; Package-Requires: ()

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary

;; The main features of this mode are syntax highlighting (enabled with
;; `font-lock-mode' or `global-font-lock-mode'), and html-mode
;; integration
;;
;; Exported names start with "vue-html-"; private names start with
;; "vue-html--".
;;
;; TODO: Chained filters, possible code folding with overlays and colors

;;; Code:

(defgroup vue-html nil
  "Major mode for vue template files"
  :prefix "vue-html-"
  :group 'languages
  :link '(url-link :tag "Github" "https://github.com/AdamNiederer/vue-html-mode")
  :link '(emacs-commentary-link :tag "Commentary" "vue-html-mode"))

(defconst vue-html-complex-interp-regex
  "\\({{\\)\\([^{].*?\\)?\\(|\\) *\\(.*?\\)(.*) *\\(}}\\)")

(defconst vue-html-filter-interp-regex
  "\\({{\\)\\([^{].*?\\)?\\(|\\) *\\([^\(\)]*?\\) *\\(}}\\)")

(defconst vue-html-simple-interp-regex
  "\\({{\\)\\(?:[^{].*?\\)?\\(}}\\)")

(defconst vue-html-shorthand-regex
  "\\s +\\([@:]\\)\\([A-z0-9-.]+\\)=.*?")

(defconst vue-html-directive-regex
  "\\b\\(v-[A-Za-z0-9-.]+\\)\\(:[A-z.]\\)?")

(defconst vue-html-keyword-regex
  "\\(v-\\(?:for\\|if\\|else-if\\|else\\|once\\)\\)[^-.A-Za-z0-9]")

(defcustom vue-html-tab-width 2
  "Tab width for vue-html-mode."
  :group 'vue-html
  :type 'integer)

(defcustom vue-html-extra-indent 0
  "The number of columns added to every line's indentation."
  :group 'vue-html
  :type 'integer)

(defcustom vue-html-color-interpolations nil
  "Whether to color the body of variable interpolations the same as delimiters.
Does not affect the colors of filters and their arguments."
  :group 'vue-html
  :type 'boolean)

(defconst vue-html-color-interpolations-font-lock-keywords
  `((,vue-html-simple-interp-regex . (0 font-lock-variable-name-face t))
    (,vue-html-filter-interp-regex . (2 font-lock-variable-name-face t))
    (,vue-html-complex-interp-regex . (2 font-lock-variable-name-face t)))
  "List of Font Lock rules applied if `vue-html-color-interpolations' is non-nil.")

(defconst vue-html-font-lock-keywords
  `((,vue-html-simple-interp-regex . (1 font-lock-variable-name-face t))
    (,vue-html-simple-interp-regex . (2 font-lock-variable-name-face t))
    (,vue-html-filter-interp-regex . (1 font-lock-variable-name-face t))
    (,vue-html-filter-interp-regex . (3 font-lock-function-name-face t))
    (,vue-html-filter-interp-regex . (4 font-lock-function-name-face t))
    (,vue-html-filter-interp-regex . (5 font-lock-variable-name-face t))
    (,vue-html-complex-interp-regex . (1 font-lock-variable-name-face t))
    (,vue-html-complex-interp-regex . (3 font-lock-function-name-face t))
    (,vue-html-complex-interp-regex . (4 font-lock-function-name-face t))
    (,vue-html-complex-interp-regex . (5 font-lock-variable-name-face t))
    (,vue-html-directive-regex . (1 font-lock-builtin-face t))
    (,vue-html-shorthand-regex . (1 font-lock-builtin-face t))
    (,vue-html-shorthand-regex . (2 font-lock-variable-name-face t))
    (,vue-html-keyword-regex . (1 font-lock-keyword-face t)))
  "List of Font Lock keywords which are applied regardless of settings.")

(defvar vue-html-mode-map
  (let ((map (make-keymap)))
    map)
  "Keymap for vue-html-mode.")

(defun vue-html-last-line-p ()
  "Return whether point is on the last line in the buffer."
  (save-excursion (= (line-number-at-pos) (line-number-at-pos (point-max)))))

(defun vue-html-line-empty-p ()
  "Return whether point is on an empty line."
  (string-match-p "^\s*$" (buffer-substring (point-at-bol) (point-at-eol))))

(defun vue-html-indent ()
  "Indent the line according to `vue-html-tab-width' and `vue-html-extra-indent'."
  (cond
   ((= 1 (line-number-at-pos)) (indent-line-to vue-html-extra-indent))
   ((and (vue-html-last-line-p) (vue-html-line-empty-p)) (indent-line-to 0))
   (t (sgml-indent-line))))

;;;###autoload
(define-derived-mode vue-html-mode html-mode "vue-html"
  "Major mode for Vue.js templates."
  (setq tab-width vue-html-tab-width)
  (setq indent-line-function #'vue-html-indent)
  (font-lock-add-keywords nil vue-html-font-lock-keywords)
  (when vue-html-color-interpolations
    (font-lock-add-keywords nil vue-html-color-interpolations-font-lock-keywords)))

(provide 'vue-html-mode)
;;; vue-html-mode.el ends here
