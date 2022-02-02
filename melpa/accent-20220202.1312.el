;;; accent.el --- Popup for accented characters (diacritics) -*- lexical-binding: t; -*-

;; Copyright (c) 2022 Elia Scotto

;; Author: Elia Scotto <eliascotto94@gmail.com>
;; Maintainer: Elia Scotto <eliascotto94@gmail.com>
;; URL: https://github.com/elias94/accent
;; Package-Version: 20220202.1312
;; Package-Commit: 6b502df6940587dae2dfbd349c22dfd44c803a86
;; Keywords: i18n
;; Version: 1.3
;; Package-Requires: ((emacs "24.3") (popup "0.5.8"))

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

;; accent.el enable a visual popup for using accented characters in Emacs.
;;
;; Is recommended to bind a global keybinding to use when typing such
;; as `C-x C-a`; add the following to your configuration:
;;
;; (global-set-key (kbd "C-x C-a") 'accent-menu)
;;
;; See README.md for more information.
;; https://github.com/elias94/accent/blob/main/README.md

;;; Code:

(require 'popup)

(defconst accent-version "1.3"
  "Version of accent.el.")

(defgroup accent nil
  "Shows popup with accented letters while pressing C-x C-a on an
accented character."
  :group 'convenience)

(defcustom accent-position 'before
  "If set to 'before (default) it takes the character before the cursor.
If set to 'after it takes the caracter after the cursor. Set it to 'after
if you have the `cursor-type` set to 'block and want to apply an accent to
the character under the cursor."
  :group 'accent
  :type 'symbol)

(defcustom accent-custom '()
  "Used to append custom accented characters to the default one.
It uses a list of characters associated to a single letter,
e.g. '(a (ằ)) ."
  :group 'accent
  :type '(alist :value-type (character (alist :value-type character))))

(defvar accent-diacritics '((a (à á â ä æ ã å ā))
                            (c (ç ć č))
                            (e (è é ê ë ē ė ę))
                            (i (î ï í ī į ì))
                            (l (ł))
                            (n (ñ ń))
                            (o (ô ö ò ó œ ø ō õ))
                            (s (ß ś š))
                            (u (û ü ù ú ū))
                            (y (ÿ))
                            (z (ž ź ż))
                            (A (À Á Â Ä Æ Ã Å Ā))
                            (C (Ç Ć Č))
                            (E (È É Ê Ë Ē Ė Ę))
                            (I (Î Ï Í Ī Į Ì))
                            (L (Ł))
                            (N (Ñ Ń))
                            (O (Ô Ö Ò Ó Œ Ø Ō Õ))
                            (S (Ś Š))
                            (U (Û Ü Ù Ú Ū))
                            (Y (Ÿ))
                            (Z (Ž Ź Ż)))
  "List of diacritics available.
For each character, includes a list
of available options to be displayed in the popup.")

(defun accent-lst ()
  "Merge `accent-custom` with default accenter characters."
  (cl-labels ((merge-custom (accent)
                (let ((custom-acc (cl-find (car accent) accent-custom :key #'car)))
                  (if custom-acc
                      (list (car accent)
                            (cl-concatenate 'list
                                            (cadr accent)
                                            (cadr custom-acc)))
                    accent))))
    (mapcar #'merge-custom accent-diacritics)))

;;;###autoload
(defun accent-menu ()
  "Display a popup menu with available accents if current character is matching."
  (interactive)
  (let* ((after? (eq accent-position 'after))
         (char (if after? (char-after) (char-before)))
         (curr (intern (string char)))
         (diac (assoc curr (accent-lst))))
    (if diac
        (let ((opt (popup-menu* (cadr diac))))
          (when opt
            (progn
              (delete-char (if after? 1 -1))
              (insert (symbol-name opt)))))
      (message "No accented characters available"))))

(provide 'accent)
;;; accent.el ends here
