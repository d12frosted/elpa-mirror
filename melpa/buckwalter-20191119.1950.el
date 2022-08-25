;;; buckwalter.el --- Write arabic using Buckwalter transliteration

;; Copyright (C) 2017 Joe HAKIM RAHME <joehakimrahme@gmail.com>

;; Author: Joe HAKIM RAHME <joehakimrahme@gmail.com>
;; Version: 20171126.1
;; Package-Version: 20191119.1950
;; Package-Commit: 1ef6f210f38c0686bc5b445b9704190f168f30ea
;; Keywords: arabic, transliteration, i18n
;; URL: https://github.com/joehakimrahme/buckwalter-arabic

;;; Commentary:

;; This package provides interactive functions to translate latin characters
;; to unicode in arabic scripts, using the Buckwalter transliteration.
;;
;; For more info on the transliteration table:
;;     http://www.qamus.org/transliteration.htm"

;;; License:

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License v3 as
;; published by the Free Software Foundation.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:
(defvar buckwalter-to-unicode '(
    ; alphabet
    ("'" . "ء") ("|" . "آ") (">" . "أ") ("&" . "ؤ") ("<" . "إ") ("}" . "ئ")
    ("A" . "ا") ("b" . "ب") ("p" . "ة") ("t" . "ت") ("v" . "ث") ("j" . "ج")
    ("H" . "ح") ("x" . "خ") ("d" . "د") ("*" . "ذ") ("r" . "ر") ("z" . "ز")
    ("s" . "س") ("$" . "ش") ("S" . "ص") ("D" . "ض") ("T" . "ط") ("Z" . "ظ")
    ("E" . "ع") ("g" . "غ") ("_" . "ـ") ("f" . "ف") ("q" . "ق") ("k" . "ك")
    ("l" . "ل") ("m" . "م") ("n" . "ن") ("h" . "ه") ("w" . "و")
    ("Y" . "ى") ("y" . "ي") ("F" . "ً") ("N" . "ٌ") ("K" . "ٍ") ("a" . "َ")
    ("u" . "ُ")("i" . "ِ") ("~" . "ّ") ("o" . "ْ") ("`" . "ٰ") ("{" . "ٱ")

    ; punctuation
    ("?" . "؟") ("," . "،") (";" . "؛")

    ; digits
    ("0" . "٠") ("1" . "١") ("2" . "٢") ("3" . "٣") ("4" . "٤") ("5" . "٥")
    ("6" . "٦") ("7" . "٧") ("8" . "٨") ("9" . "٩")
    ))



;; originally taken from s.el. The function is modified to avoid tripping
;; on case-fold-search
(defun buckwalter-replace-all (replacements s)
  (let ((case-fold-search nil))
    (replace-regexp-in-string (regexp-opt (mapcar 'car replacements))
                              (lambda (it) (cdr (assoc-string it replacements)))
                              s nil nil)))

;;;###autoload
(defun buckwalter-transliterate (string &optional from to)
  "Replace latin letters with arabic using the Buckwalter transliteration.

When called interactively, work on current paragraph or text selection.

When called in Lisp code, if STRING is non-nil, returns a changed string.
If STRING nil, change the text in the region between positions FROM and TO.

More detailed info on the Buckwalter transliteration can be found here:
http://www.qamus.org/transliteration.htm"
  (interactive
   (if (use-region-p)
       (list nil (region-beginning) (region-end))
     (let ((bds (bounds-of-thing-at-point 'paragraph)))
       (list nil (car bds) (cdr bds)))))
  (let (work-on-string-p input-str output-str)
    (setq work-on-string-p (if string t nil))
    (setq input-str (if work-on-string-p string (buffer-substring-no-properties from to)))
    (setq output-str (buckwalter-replace-all buckwalter-to-unicode input-str))
    (setq unicode-to-buckwalter (mapcar (lambda (x) (cons (cdr x) (car x))) buckwalter-to-unicode))
    (if work-on-string-p
        output-str
      (save-excursion
        (delete-region from to)
        (goto-char from)
          (insert output-str)))))

;;;###autoload
(defun buckwalter-transliterate-reverse (string &optional from to)
  "Replace arabic letters with latin using the Buckwalter transliteration.

When called interactively, work on current paragraph or text selection.

When called in Lisp code, if STRING is non-nil, returns a changed string.
If STRING nil, change the text in the region between positions FROM and TO.

More detailed info on the Buckwalter transliteration can be found here:
http://www.qamus.org/transliteration.htm"
  (interactive
   (if (use-region-p)
       (list nil (region-beginning) (region-end))
     (let ((bds (bounds-of-thing-at-point 'paragraph)))
       (list nil (car bds) (cdr bds)))))
  (let (work-on-string-p input-str output-str)
    (setq work-on-string-p (if string t nil))
    (setq input-str (if work-on-string-p string (buffer-substring-no-properties from to)))
    (setq output-str (buckwalter-replace-all unicode-to-buckwalter input-str))
    (if work-on-string-p
        output-str
      (save-excursion
        (delete-region from to)
        (goto-char from)
        (insert output-str)))))

;;;###autoload
(defun buckwalter-table ()
  "Displays the buckwalter-unicode conversion table for reference"
  (interactive)
  (describe-variable 'buckwalter-to-unicode))

(provide 'buckwalter)
;;; buckwalter.el ends here
