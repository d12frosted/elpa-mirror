;;; teacode-expand.el --- Expansion of text by TeaCode program. -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Richard Guay

;; Author: Richard Guay <raguay@customct.com>
;; Keywords: lisp
;; Package-Version: 20181231.640
;; Package-Commit: 7df6f9ec95da1fb47bbae489bb3f2c27ed3a9b3a
;; URL: https://github.com/raguay/TeaCode-Expand
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4"))

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

;; This code is used to expand the current line in TeaCode
;; program on the macOS machine.  It is currently the bare bones
;; in terms of functionality.

;; To add a hotkey for this function, add this line to your config
;; file:

;;     (global-set-key (kbd "A-C-e") 'teacode-expand)

;;; Code:

(require 'json)

(defcustom teacode-default-language "any language"
       "The default language to use when expanding a expression. Typically used when the buffer isn't attached to a file."
       :type 'string
       :require 'teacode-expand)

;;;###autoload
(defun teacode-expand ()
  "Expand the current line with TeaCode."
  (interactive)
  (let*
      ((filename (buffer-file-name))
       (ext (if filename (file-name-extension filename t) teacode-default-language))
       (toExpand (concat
                  "Application(\"TeaCode\").expandAsJson(\""
                  (shell-quote-argument (replace-regexp-in-string "\n$" "" (thing-at-point 'line t)))
                  "\" , { \"extension\": \""
                  ext
                  "\" })" ))
       (ans (with-temp-buffer
              (call-process
               "osascript"
               nil
               (current-buffer)
               nil
               "-l"
               "JavaScript"
               "-e"
               toExpand)
              (buffer-string)))
       (tcjson (json-read-from-string ans))
       (txt (cdr (assoc 'text tcjson)))
       (cursorp (cdr (assoc 'cursorPosition tcjson))))
    ;; The foundText variable is also in the structure, but I'm not
    ;; sure when to use it. Just comment it out for now until I understand
    ;; its usability.
    ;;(foundText (cdr (assoc 'foundPattern tcjson)))
    (delete-region (line-beginning-position) (line-end-position))
    (insert txt)
    (backward-char (- (length txt) cursorp))))

(provide 'teacode-expand)
;;; teacode-expand.el ends here
