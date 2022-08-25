;;; ivy-emoji.el --- Insert emojis with ivy -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Gabriele Bozzola

;; Author: Gabriele Bozzola <sbozzolator@gmail.com>
;; URL: https://github.com/sbozzolo/ivy-emoji.git
;; Package-Version: 20200316.2351
;; Package-Commit: 45894a1f8f8c67b142e1dd1113f47d703dea0b59
;; Version: 0.2
;; Package-Requires: ((emacs "26.1") (ivy "0.13.0"))
;; Keywords: emoji ivy convenience
;; Prefix: ivy-emoji

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

;; ivy-emoji provides a convenient way to insert any emoji in any buffer using
;; ivy to select the emoji by its name.

;; A font that supports emoji is needed.  The best results are obtained with Noto
;; Color Emoji or Symbola.  It might be necessary to instruct Emacs to use such
;; font with a line like the following.
;;
;; (set-fontset-font t 'symbol
;;                      (font-spec :family "Noto Color Emoji") nil 'prepend)

;;; Code:

(require 'ivy)

;; The idea of generating the list from code point ranges is taken from the
;; no-emoji package
(defconst ivy-emoji-codepoint-ranges
  '((#x1f000 . #x1f9ff))
  "List of code point ranges (inclusive) corresponding to all the emojis.")

(defun ivy-emoji--clean-name (name)
  "Convert NAME to the string that should be shown.
E.g. convert spaces to -, surround with :."
  (concat ":" (replace-regexp-in-string " " "-" (downcase name)) ":"))

(defun ivy-emoji--create-list ()
  "Create list of emojis with the emoji as first character.
This is done by parsing the code point ranges.

This function is used to produce the constant `ivy-emoji-list'."
  (let (emoji-list)
    (dolist (range ivy-emoji-codepoint-ranges) ; Loop over different ranges
      (dotimes (i (- (cdr range) (car range))) ; Loop over the code points in the range
        (let* ((codepoint (+ (car range) i))
               (name (get-char-code-property codepoint 'name)))
          (when name                    ; If the emoji is not available
                                        ; name would be nil
                                        ; Those emoji should not be included
            (setq emoji-list
                  (append emoji-list
                                        ; The way we want to format emoji is the following:
                                        ; 🌵 :cactus:
                          (list (format "%s %s"
                                        (char-to-string (char-from-name name))
                                        (ivy-emoji--clean-name name)))))))))
    emoji-list))

(defun ivy-emoji--insert-emoji (emoji)
  "Insert EMOJI by extracting the first character.

This function is supposed to be used with
`ivy-emoji--create-list'."
  (insert (substring emoji 0 1)))

;; Create list of emojis using the ranges in the code points
(defconst ivy-emoji-list (ivy-emoji--create-list)
  "Cached list of emojis with their name.

The format is:
...
🌵 :cactus:
🍝 :spaghetti:
...
The emoji character will be selected as substring and inserted by
`ivy-emoji--insert-emoji'.")

;;;###autoload
(defun ivy-emoji ()
  "Select an emoji and insert it."
  (interactive)
  (ivy-read "Emoji: "
            ivy-emoji-list
            :require-match t
            :action #'ivy-emoji--insert-emoji))

(provide 'ivy-emoji)

;;; ivy-emoji.el ends here
