;;; eg.el --- Norton Guide reader -*- lexical-binding: t -*-
;; Copyright 2017 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.1
;; Package-Version: 20170830.815
;; Package-Commit: 1c7f1613d2aaae728ef540305f6ba030616f86bd
;; Keywords: docs
;; URL: https://github.com/davep/eg.el
;; Package-Requires: ((cl-lib "0.5") (emacs "24.3"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; eg.el provides code for reading the content of help databases built with
;; Norton Guide and Expert Help. It also provides commands for viewing and
;; navigating the content of Norton Guide files.
;;
;; The main command is `eg'. Run this, select a Norton Guide database to
;; view, and off you go.

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General Norton Guide reading code.

(require 'cl-lib)
(require 'easymenu)

(defconst eg-magic-ng "NG"
  "Magic marker for a guide built with Norton Guide.")

(defconst eg-magic-eh "EH"
  "Magic marker for a guide built with Expert Help.")

(defconst eg-title-length 40
  "Maximum length of a guide title.")

(defconst eg-credit-length 66
  "Maximum length of a line in a guide's credits.")

(defconst eg-prompt-length 128
  "Maximum length of a prompt on a menu.")

(defconst eg-line-length 1024
  "Maximum length of a line in a guide entry.")

(defconst eg-entry-short 0
  "Id of a short entry in a guide.")

(defconst eg-entry-long 1
  "Id of a long entry in a guide.")

(defconst eg-entry-menu 2
  "Id of a menu in a guide.")

(defconst eg-max-see-alsos 20
  "Maximum number of see-also items for a single entry in a guide.

This is the limit published in the Expert Help Compiler manual
and, while this limit isn't really needed in this code, it does
help guard against corrupt guides.")

(defconst eg-rle-marker 255
  "Value of a guide's RLE marker.")

(defvar eg-buffer-name-function (lambda (file) (format " *EG: %s*" file))
  "Function that names a buffer for reading from a Norton guide file.")

(cl-defstruct eg-guide
  ;; Holds details about a guide.
  file
  buffer
  magic
  menu-count
  title
  credits
  menus
  first-entry-pos
  (pos 0))

(cl-defstruct eg-menu
  ;; Holds details about a menu found in a guide.
  title
  prompt-count
  prompts
  offsets)

(cl-defstruct eg-entry
  ;; Holds the details of a guide entry.
  offset
  type
  size
  line-count
  has-see-also
  parent-line
  parent
  parent-menu
  parent-prompt
  previous
  next
  offsets
  lines
  see-also)

(cl-defstruct eg-see-also
  ;; Holds the details of the see-alsos for a guide entry.
  prompt-count
  prompts
  offsets)

(cl-defun eg-skip (guide &optional (bytes 1))
  "Skip BYTES bytes in GUIDE."
  (cl-incf (eg-guide-pos guide) bytes))

(defun eg-goto (guide pos)
  "Move read location in GUIDE to POS."
  (setf (eg-guide-pos guide) pos))

(defun eg-goto-first (guide)
  "Go to the first entry in GUIDE."
  (eg-goto guide (eg-guide-first-entry-pos guide)))

(defmacro eg-save-excursion (guide &rest body)
  "Read from GUIDE and evaluate BODY but leave location unmoved."
  (declare (indent 1))
  (let ((saved-pos (cl-gensym "eg-saved-pos-")))
    `(let ((,saved-pos (eg-guide-pos ,guide)))
       (unwind-protect
           (progn
             ,@body)
         (eg-goto ,guide ,saved-pos)))))

(defmacro eg-with-guide-buffer (guide &rest body)
  "Make GUIDE the current buffer then evaluate BODY."
  (declare (indent 1))
  `(with-current-buffer (eg-guide-buffer ,guide)
     ,@body))

(defun eg-read (guide len)
  "Read bytes from GUIDE.

LEN is the number of bytes to read."
  (eg-with-guide-buffer guide
    (let* ((from (min (+ (point-min) (eg-guide-pos guide)) (point-max)))
           (to   (min (+ from len) (point-max))))
      (eg-skip guide len)
      (buffer-substring-no-properties from to))))

(cl-defun eg-decrypt (n &optional (decrypt t))
  "Decrypt value N if DECRYPT is non-nil."
  (if decrypt (logxor n 26) n))

(defun eg-make-signed-byte (n)
  "Ensure N is a signed byte."
  (if (zerop (logand n #x80))
      n
    (- n #x100)))

(cl-defun eg-read-byte (guide &optional (decrypt t))
  "Read a byte from GUIDE.

If DECRYPT is non-nil, decrypt it.

This has the side-effect of moving `eg-guide-pos'."
  (let ((byte (string-to-char (eg-read guide 1))))
    (eg-make-signed-byte (eg-decrypt byte decrypt))))

(defun eg-make-signed-word (n)
  "Ensure N is a signed word."
  (if (zerop (logand n #x8000))
      n
    (- n #x10000)))

(cl-defun eg-read-word (guide &optional (decrypt t))
  "Read a word from GUIDE.

If DECRYPT is non-nil, decrypt it.

This has the side-effect of moving `eg-guide-pos'"
  (let ((word (eg-read guide 2)))
    (let ((lo (eg-decrypt (aref word 0) decrypt))
          (hi (eg-decrypt (aref word 1) decrypt)))
      (eg-make-signed-word (+ (lsh hi 8) lo)))))

(defun eg-make-signed-long (n)
  "Ensure N is a signed long."
  (if (zerop (logand n #x80000000))
      n
    (- n #x100000000)))

(cl-defun eg-read-long (guide &optional (decrypt t))
  "Read a long from GUIDE.

If DECRYPT is non-nil, decrypt it.

This has the side-effect of moving `eg-guide-pos'"
  (let ((long (eg-read guide 4)))
    (let ((lolo (eg-decrypt (aref long 0) decrypt))
          (lohi (eg-decrypt (aref long 1) decrypt))
          (hilo (eg-decrypt (aref long 2) decrypt))
          (hihi (eg-decrypt (aref long 3) decrypt)))
      (eg-make-signed-long
       (+ (lsh (+ (lsh hihi 8) hilo) 16) (+ (lsh lohi 8) lolo))))))

(cl-defun eg-decrypt-string (s)
  "Decrypt string S."
  (mapconcat #'string (mapcar #'eg-decrypt s) ""))

(defun eg-rle-marker-p (c)
  "Does C look like an RLE marker?"
  (= c eg-rle-marker))

(defun eg-clean-string (s)
  "Clean string S of RLE-markers, but don't expand.

It's rare, but some guides seem to include an RLE marker or two
inside menu options, but with no actual RLE expansion value to
follow. This function can be used to clean strings of RLE markers
in situations where RLE-expansion is unlikely to make sense."
  (replace-regexp-in-string (string eg-rle-marker) " " s))

(defun eg-expand-string (s)
  "RLE-expand spaces in string S."
  (apply #'concat
         (cl-loop for c across s
                  with expand = nil
                  if expand collect (if (eg-rle-marker-p c)
                                        " "
                                      (make-string c 32))
                  and do (setq expand nil)
                  else if (eg-rle-marker-p c) do (setq expand t)
                  else collect (string c))))

(cl-defun eg-read-string (guide len &optional (decrypt t))
  "Read a string of LEN characters from GUIDE.

Any trailing NUL characters are removed."
  (let ((s (eg-read guide len)))
    (replace-regexp-in-string "\0[\0-\377[:nonascii:]]*" ""
                              (if decrypt
                                  (eg-decrypt-string s)
                                s))))

(cl-defun eg-read-string-z (guide len &optional (decrypt t))
  "Read string up to LEN characters, stopping if a nul is encountered."
  (let ((s (eg-save-excursion guide
             (eg-read-string guide len decrypt))))
    (eg-skip guide (1+ (length s)))
    s))

(defun eg-skip-entry (guide)
  "Skip an entry/menu in GUIDE."
  (eg-skip guide (+ 22 (eg-read-word guide))))

(defun eg-next-entry (guide)
  "Move GUIDE location to the next entry."
  (unless (eg-eof-p guide)
    (eg-read-word guide)
    (eg-skip-entry guide)))

(defun eg-read-header (guide)
  "Read the header of GUIDE."
  ;; Read the magic "number".
  (setf (eg-guide-magic guide) (eg-read guide 2))
  (when (eg-guide-good-magic-p guide)
    ;; Skip 4 bytes (I'm not sure what they are for).
    (eg-skip guide 4)
    ;; Get the count of menus.
    (setf (eg-guide-menu-count guide) (eg-read-word guide nil))
    ;; Get the title of the guide.
    (setf (eg-guide-title guide) (eg-read-string guide eg-title-length nil))
    ;; Load the credits for the guide.
    (setf (eg-guide-credits guide)
          (cl-loop for n from 0 to 4
                   collect (eg-read-string guide eg-credit-length nil))))
  guide)

(defun eg-read-menu (guide)
  "Read a menu from GUIDE."
  ;; Skip the byte size of the menu entry.
  (eg-read-word guide)
  (let ((menu (make-eg-menu)))
    ;; Get the number of prompts on the menu.
    (setf (eg-menu-prompt-count menu) (1- (eg-read-word guide)))
    ;; Skip 20 bytes.
    (eg-skip guide 20)
    ;; Get the offsets into the file for each prompt on the menu
    (setf (eg-menu-offsets menu)
          (cl-loop for n from 1 to (eg-menu-prompt-count menu)
                   collect (eg-read-long guide)))
    ;; Skip some unknown values.
    (eg-skip guide (* (1+ (eg-menu-prompt-count menu)) 8))
    ;; Get the menu's title.
    (setf (eg-menu-title menu) (eg-clean-string (eg-read-string-z guide eg-prompt-length)))
    ;; Now load up the prompts.
    (setf (eg-menu-prompts menu)
          (cl-loop for n from 1 to (eg-menu-prompt-count menu)
                   collect (eg-clean-string (eg-read-string-z guide eg-prompt-length))))
    ;; Finally, skip an unknown byte.
    (eg-skip guide)
    menu))

(defun eg-read-menus (guide)
  "Read the menus in GUIDE."
  (let ((i 0))
    (while (< i (eg-guide-menu-count guide))
      (let ((type (eg-read-word guide)))
        (cond ((= type eg-entry-short)
               (eg-skip-entry guide))
              ((= type eg-entry-long)
               (eg-skip-entry guide))
              ((= eg-entry-menu)
               (setf (eg-guide-menus guide)
                     (nconc (eg-guide-menus guide) (list (eg-read-menu guide))))
               (cl-incf i))
              (t
               (setq i (eg-guide-menu-count guide))))))))

(defun eg-entry-short-p (entry)
  "Is ENTRY a short entry?"
  (when entry
    (= (eg-entry-type entry) eg-entry-short)))

(defun eg-entry-long-p (entry)
  "Is ENTRY a long entry?"
  (when entry
    (= (eg-entry-type entry) eg-entry-long)))

(defun eg-entry-type-description (entry)
  "Describe the type of ENTRY."
  (cond ((eg-entry-short-p entry)
         "Short")
        ((eg-entry-long-p entry)
         "Long")
        (t
         "Unknown")))

(defun eg-load-see-alsos (guide)
  "Load a list of see also entries from current position in GUIDE."
  (let ((see-also (make-eg-see-also)))
    (setf (eg-see-also-prompt-count see-also) (min (eg-read-word guide) eg-max-see-alsos))
    (setf (eg-see-also-offsets see-also)
          (cl-loop for n from 1 to (eg-see-also-prompt-count see-also)
                   collect (eg-read-long guide)))
    (setf (eg-see-also-prompts see-also)
          (cl-loop for n from 1 to (eg-see-also-prompt-count see-also)
                   collect (eg-expand-string (eg-read-string-z guide eg-prompt-length))))
    see-also))

(defun eg-read-entry (guide)
  "Read the entry at the current location in GUIDE."
  (let ((entry (make-eg-entry)))
    ;; Load the main "header" information for an entry.
    (setf (eg-entry-offset entry) (eg-guide-pos guide))
    (setf (eg-entry-type   entry) (eg-read-word guide))
    (when (or (eg-entry-short-p entry) (eg-entry-long-p entry))
      (setf (eg-entry-size          entry) (eg-read-word guide))
      (setf (eg-entry-line-count    entry) (eg-read-word guide))
      (setf (eg-entry-has-see-also  entry) (not (zerop (eg-read-word guide))))
      (setf (eg-entry-parent-line   entry) (eg-read-word guide))
      (setf (eg-entry-parent        entry) (eg-read-long guide))
      (setf (eg-entry-parent-menu   entry) (eg-read-word guide))
      (setf (eg-entry-parent-prompt entry) (eg-read-word guide))
      (setf (eg-entry-previous      entry) (eg-read-long guide))
      (setf (eg-entry-next          entry) (eg-read-long guide))
      ;; If it's a short entry...
      (when (eg-entry-short-p entry)
        ;; ...load the offsets associated with each line.
        (setf (eg-entry-offsets entry)
              (cl-loop for n from 1 to (eg-entry-line-count entry)
                       do (eg-read-word guide) ; Skip unknown word.
                       collect (eg-read-long guide))))
      ;; Load the lines for the entry.
      (setf (eg-entry-lines entry)
            (cl-loop for n from 1 to (eg-entry-line-count entry)
                     collect (eg-expand-string (eg-read-string-z guide eg-line-length))))
      ;; If it's a long entry, and it has a see-also list...
      (when (and (eg-entry-long-p entry) (eg-entry-has-see-also entry))
        ;; ...load the see-alsos.
        (setf (eg-entry-see-also entry) (eg-load-see-alsos guide)))
      entry)))

(defun eg-load-entry (guide)
  "Load the current entry from the GUIDE."
  (eg-save-excursion guide
    (eg-read-entry guide)))

(defun eg-entry-text (entry)
  "Get the text of ENTRY as a single string.

New line markers are added at the end of each line."
  (cl-loop for line in (eg-entry-lines entry) concat line concat "\n"))

(defun eg-guide-good-magic-p (guide)
  "Does GUIDE appear to be a Norton Guide file?"
  (member (eg-guide-magic guide) (list eg-magic-ng eg-magic-eh)))

(defun eg-guide-type (guide)
  "Return a string that describes the type of GUIDE."
  (cond ((string= (eg-guide-magic guide) eg-magic-ng)
         "Norton Guide")
        ((string= (eg-guide-magic guide) eg-magic-eh)
         "Expert Help")
        (t
         "Unknown")))

(defun eg-guide-has-menus-p (guide)
  "Does GUIDE have menus?"
  (> (eg-guide-menu-count guide) 0))

(defun eg-entry-looking-at-short-p (guide)
  "Does it look like GUIDE is positioned on a short entry?"
  (eg-entry-short-p (eg-load-entry guide)))

(defun eg-entry-looking-at-long-p (guide)
  "Does it look like GUIDE is positioned on a long entry?"
  (eg-entry-long-p (eg-load-entry guide)))

(defun eg-valid-pointer-p (pointer)
  "Does POINTER look like a valid guide location?"
  (> pointer 0))

(defun eg-entry-has-parent-p (entry)
  "Does ENTRY appear to have a parent entry?"
  (eg-valid-pointer-p (eg-entry-parent entry)))

(defun eg-entry-has-previous-p (entry)
  "Does ENTRY appear to have a previous entry?"
  (eg-valid-pointer-p (eg-entry-previous entry)))

(defun eg-entry-has-next-p (entry)
  "Does ENTRY appear to have a next entry?"
  (eg-valid-pointer-p (eg-entry-next entry)))

(defun eg-entry-has-parent-menu-p (entry)
  "Does ENTRY have a parent menu?"
  (> (eg-entry-parent-menu entry) -1))

(defun eg-entry-has-parent-prompt-p (entry)
  "Does ENTRY know which parent menu prompt it relates to?"
  (> (eg-entry-parent-prompt entry) -1))

(defun eg-eof-p (guide)
  "Do we appear to be at the end of GUIDE?"
  (or
   (eg-with-guide-buffer guide
     (>= (+ (point-min) (eg-guide-pos guide)) (point-max)))
   (not (or (eg-entry-looking-at-short-p guide)
            (eg-entry-looking-at-long-p guide)))))

(defun eg-open (file)
  "Open FILE and return the buffer that'll be used to read it."
  (when (file-exists-p file)
    (let ((guide (eg-read-header
                  (with-current-buffer (generate-new-buffer (funcall eg-buffer-name-function file))
                    (buffer-disable-undo)
                    (set-buffer-multibyte nil)
                    (let ((coding-system-for-read 'binary))
                      (insert-file-contents-literally file))
                    (make-eg-guide :file file :buffer (current-buffer))))))
      (when (eg-guide-good-magic-p guide)
        (when (eg-guide-has-menus-p guide)
          (eg-read-menus guide))
        (setf (eg-guide-first-entry-pos guide) (eg-guide-pos guide)))
      guide)))

(defun eg-close (guide)
  "Close GUIDE."
  (kill-buffer (eg-guide-buffer guide)))

(defmacro eg-with-guide (guide file &rest body)
  "Open GUIDE from FILE and then evaluate BODY.

`eg-with-guide' handles opening the Norton Guide file and also
ensures that it is closed again after BODY has been evaluated."
  (declare (indent 2))
  `(let ((,guide (eg-open ,file)))
     (unwind-protect
         (progn
           ,@body)
       (eg-close ,guide))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customizable parts of the Norton Guide reader.

(defgroup eg nil
  "Expert Help: The Emacs Norton Guide viewer"
  :group 'docs)

(defface eg-viewer-text-link-face
  '((t :inherit widget-button))
  "Face for text links in short entries."
  :group 'eg)

(defface eg-viewer-nav-button-face
  '((((type x w32 ns)
      (class color))
     :box (:line-width 2 :style released-button)
     :background "lightgrey" :foreground "black"))
  "Face for top navigation buttons."
  :group 'eg)

(defface eg-viewer-see-also-face
  '((t :inherit widget-button
       :underline t
       :weight bold))
  "Face for see-also links."
  :group 'eg)

(defface eg-viewer-bold-text-face
  '((t :weight bold))
  "Face of bold text."
  :group 'eg)

(defface eg-viewer-underline-text-face
  '((t :underline t))
  "Face of underlined text."
  :group 'eg)

(defface eg-viewer-reverse-text-face
  '((t :slant italic))
  "Face of reversed text."
  :group 'eg)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Guide viewer "internals".

(defvar-local eg--current-guide nil
  "The current guide being viewed in an EG buffer.")

(defvar-local eg--current-entry nil
  "The entry currently being viewed in an EG buffer.")

(defvar-local eg--currently-displaying nil
  "Informs the display code what it is we're displaying.")

(defvar-local eg--viewing-source nil
  "T if we're viewing the source of entries, NIL if not.")

(defvar eg--undosify-map nil
  "Hash table of text translations.")

(unless eg--undosify-map
  (setq eg--undosify-map (make-hash-table))
  (mapc (lambda (mapping)
          (puthash (car mapping) (cdr mapping) eg--undosify-map))
        '((0   . " ")
          (1   . "\u263A")
          (2   . "\u263B")
          (3   . "\u2665")
          (4   . "\u2666")
          (5   . "\u2663")
          (6   . "\u2660")
          (7   . "\u2022")
          (8   . "\u25DB")
          (9   . "\u25CB")
          (10  . "\u25D9")
          (11  . "\u2642")
          (12  . "\u2640")
          (13  . "\u266A")
          (14  . "\u266B")
          (15  . "\u263C")
          (16  . "\u25BA")
          (17  . "\u25C4")
          (18  . "\u2195")
          (19  . "\u203C")
          (20  . "\u00B6")
          (21  . "\u00A7")
          (22  . "\u25AC")
          (23  . "\u21A8")
          (24  . "\u2191")
          (25  . "\u2193")
          (26  . "\u2192")
          (27  . "\u2190")
          (28  . "\u221F")
          (29  . "\u2194")
          (30  . "\u25B2")
          (31  . "\u25BC")
          (127 . "\u2302")
          (128 . "\u00C7")
          (129 . "\u00FC")
          (130 . "\u00E9")
          (131 . "\u00E2")
          (132 . "\u00E4")
          (133 . "\u00E0")
          (134 . "\u00E5")
          (135 . "\u00E7")
          (136 . "\u00EA")
          (137 . "\u00EB")
          (138 . "\u00E8")
          (139 . "\u00EF")
          (140 . "\u00EE")
          (141 . "\u00EC")
          (142 . "\u00C4")
          (143 . "\u00C5")
          (144 . "\u00C9")
          (145 . "\u00E6")
          (146 . "\u00C6")
          (147 . "\u00F4")
          (148 . "\u00F6")
          (149 . "\u00F2")
          (150 . "\u00FB")
          (151 . "\u00F9")
          (152 . "\u00FF")
          (153 . "\u00D6")
          (154 . "\u00DC")
          (155 . "\u00A2")
          (156 . "\u00A3")
          (157 . "\u00A5")
          (158 . "\u20A7")
          (159 . "\u0192")
          (160 . "\u00E1")
          (161 . "\u00ED")
          (162 . "\u00F3")
          (163 . "\u00FA")
          (164 . "\u00F1")
          (165 . "\u00D1")
          (166 . "\u00AA")
          (167 . "\u00BA")
          (168 . "\u00BF")
          (169 . "\u2319")
          (170 . "\u00AC")
          (171 . "\u00BD")
          (172 . "\u00BC")
          (173 . "\u00A1")
          (174 . "\u00AB")
          (175 . "\u00BB")
          (176 . "\u2591")
          (177 . "\u2592")
          (178 . "\u2593")
          (179 . "\u2502")
          (180 . "\u2524")
          (181 . "\u2561")
          (182 . "\u2562")
          (183 . "\u2556")
          (184 . "\u2555")
          (185 . "\u2563")
          (186 . "\u2551")
          (187 . "\u2557")
          (188 . "\u255D")
          (189 . "\u255C")
          (190 . "\u255B")
          (191 . "\u2510")
          (192 . "\u2514")
          (193 . "\u2534")
          (194 . "\u252C")
          (195 . "\u251C")
          (196 . "\u2500")
          (197 . "\u253C")
          (198 . "\u255E")
          (199 . "\u255F")
          (200 . "\u255A")
          (201 . "\u2554")
          (202 . "\u2596")
          (203 . "\u2566")
          (204 . "\u2560")
          (205 . "\u2550")
          (206 . "\u256C")
          (207 . "\u2567")
          (208 . "\u2568")
          (209 . "\u2564")
          (210 . "\u2565")
          (211 . "\u2559")
          (212 . "\u2558")
          (213 . "\u2552")
          (214 . "\u2553")
          (215 . "\u256B")
          (216 . "\u256A")
          (217 . "\u251B")
          (218 . "\u250C")
          (219 . "\u2588")
          (220 . "\u2584")
          (221 . "\u258C")
          (222 . "\u2590")
          (223 . "\u2580")
          (224 . "\u03B1")
          (225 . "\u00DF")
          (226 . "\u0393")
          (227 . "\u03C0")
          (228 . "\u03A3")
          (229 . "\u03C3")
          (230 . "\u00B5")
          (231 . "\u03C4")
          (232 . "\u03A6")
          (233 . "\u039B")
          (234 . "\u03A9")
          (235 . "\u03b4")
          (236 . "\u221E")
          (237 . "\u03C6")
          (238 . "\u03B5")
          (239 . "\u2229")
          (240 . "\u2261")
          (241 . "\u00B1")
          (242 . "\u2265")
          (243 . "\u2264")
          (244 . "\u2320")
          (245 . "\u2321")
          (246 . "\u00F7")
          (248 . "\u00B0")
          (249 . "\u2219")
          (250 . "\u00B7")
          (251 . "\u221A")
          (252 . "\u207F")
          (253 . "\u00B2")
          (254 . "\u25A0")
          (255 . "\u00A0"))))

(defun eg--undosify-char (c)
  "Try and turn character C into something that will look pretty."
  (gethash c eg--undosify-map (string c)))

(defun eg--undosify-string (s)
  "Try and turn S into something that will look pretty."
  (apply #'concat
         (cl-loop for c across s collect (gethash c eg--undosify-map (string c)))))

(defun eg--entry-menu-path (entry)
  "Describe the menu path for ENTRY."
  (if (eg-entry-has-parent-menu-p entry)
      (concat
       (eg-menu-title
        (nth (eg-entry-parent-menu entry)
             (eg-guide-menus eg--current-guide)))
       " >> "
       (nth (eg-entry-parent-prompt entry)
            (eg-menu-prompts
             (nth (eg-entry-parent-menu entry)
                  (eg-guide-menus eg--current-guide)))))
    ""))

(defun eg--header-line ()
  "Return the header line format for an `eg-mode' buffer."
  '(:eval
    (concat
     " EG | "
     (file-name-nondirectory (eg-guide-file eg--current-guide))
     " | "
     (eg--undosify-string (eg-guide-title eg--current-guide))
     " | "
     (cl-case eg--currently-displaying
       (:eg-entry
        (if eg--current-entry
            (concat
             (eg-entry-type-description eg--current-entry)
             (if eg--viewing-source " (Source)" "")
             " | "
             (eg--entry-menu-path eg--current-entry))))
       (:eg-menu
        "Menu")
       (:eg-credits
        "Credits")))))

(defun eg--insert-nav (button test pos help)
  "Insert a navigation button.

BUTTON is the text. TEST is the function used to test if we
should make the button a live link. POS is the function we should
call to find the position to jump to. HELP is the help text to
show for the link."
  (when eg--current-entry
    (if (funcall test eg--current-entry)
        (insert-text-button button
                            'action (lambda (_)
                                      (eg--view-entry
                                       (funcall pos eg--current-entry)))
                            'face 'eg-viewer-nav-button-face
                            'help-echo help
                            'follow-link t)
      (insert button))))

(defun eg--add-top-nav ()
  "Add navigation links to the top of the buffer."
  (save-excursion
    (setf (point) (point-min))
    (insert-text-button "[ Menu ]"
                        'action (lambda (_) (eg-view-menu))
                        'face 'eg-viewer-nav-button-face
                        'help-echo "View the menu"
                        'follow-link t)
    (insert " ")
    (insert-text-button "[ Credits ]"
                        'action (lambda (_) (eg-view-credits))
                        'face 'eg-viewer-nav-button-face
                        'help-echo "View the guide credits"
                        'follow-link t)
    (when eg--current-entry
      (insert " ")
      (eg--insert-nav "[<< Prev]" #'eg-entry-has-previous-p #'eg-entry-previous "Go to the previous entry")
      (insert " ")
      (eg--insert-nav "[^^ Up ^^]" #'eg-entry-has-parent-p #'eg-entry-parent "Go to the parent entry")
      (insert " ")
      (eg--insert-nav "[Next >>]" #'eg-entry-has-next-p #'eg-entry-next "Go to the next entry"))
    (insert "\n\n")))

(defun eg--insert-see-alsos (entry)
  "Insert any see-also links for ENTRY."
  (when (eg-entry-has-see-also entry)
    (save-excursion
      (setf (point) (point-max))
      (insert (make-string fill-column ?-) "\n")
      (insert "See also: ")
      (cl-loop for see in (eg-see-also-prompts (eg-entry-see-also entry))
               and see-link in (eg-see-also-offsets (eg-entry-see-also entry))
               and more on (eg-see-also-offsets (eg-entry-see-also entry))
               do
               (when (> (+ (current-column) (length see)) fill-column)
                 (insert "\n"))
               (insert-button see
                              'action `(lambda (_)
                                         (eg--view-entry ,see-link))
                              'face 'eg-viewer-see-also-face
                              'help-echo (format "See also \"%s\"" see)
                              'follow-link t)
               (insert (if (cdr more) "," "") " ")))))

(defun eg--add-bottom-nav ()
  "Add navigation links to the bottom of the buffer."
  (when eg--current-entry
    (save-excursion
      (setf (point) (point-max))
      (when (eg-entry-long-p eg--current-entry)
        (eg--insert-see-alsos eg--current-entry)))))

(defun eg--view-entry (&optional offset)
  "View the entry at OFFSET."
  (when offset
    (eg-goto eg--current-guide offset))
  (setq eg--current-entry        (eg-load-entry eg--current-guide)
        eg--currently-displaying :eg-entry)
  (let ((buffer-read-only nil))
    (setf (buffer-string) "")
    (eg--insert-entry-text)
    (eg--linkify-entry-text)
    (unless eg--viewing-source
      (eg--decorate-buffer))
    (eg--add-top-nav)
    (eg--add-bottom-nav)))

(defun eg--decorate-until (token face)
  "Decorate the current line until next TOKEN or end of line.

Use FACE to decorate what's found.

This function has the destructive side-effect of removing the next instance of TOKEN."
  (let ((start (point)))
    (save-excursion
      (save-restriction
        (narrow-to-region start (line-end-position))
        (let ((end (or (search-forward-regexp (format "\\(\\^[%s%sNn]\\)" (upcase token) (downcase token)) nil t)
                       (point-max))))
          (setf (buffer-substring start end)
                (propertize (buffer-substring start end) 'font-lock-face face))
          (when (and (match-string 1) (string= (downcase (match-string 1)) (concat "^" (downcase token))))
            (replace-match "")))))))

(defun eg--decorate-buffer ()
  "Parse tokens, etc, to make the buffer more readable.

At the moment this code handles the easier options but, for now,
doesn't attempt to handle the ^A (colour attribute) token. This
might change in the future."
  (save-excursion
    (setf (point) (point-min))
    (while (search-forward "^" nil t)
      (let ((token (downcase (buffer-substring-no-properties (point) (1+ (point))))))
        (delete-char -1)
        (cond ((string= token "^"))      ; ^ character (we ignore it)
              ((string= token "a")      ; Colour attribute.
               (delete-char 3))
              ((string= token "b")      ; Bold.
               (delete-char 1)
               (eg--decorate-until "b" 'eg-viewer-bold-text-face))
              ((string= token "c")      ; Character.
               (let ((char (buffer-substring-no-properties (1+ (point)) (+ (point) 3))))
                 (delete-char 3)
                 (insert (eg--undosify-char (string-to-number char 16)))))
              ((string= token "n")      ; Normal.
               (delete-char 1))
              ((string= token "r")      ; Reverse.
               (delete-char 1)
               (eg--decorate-until "r" 'eg-viewer-reverse-text-face))
              ((string= token "u")      ; Underline.
               (delete-char 1)
               (eg--decorate-until "u" 'eg-viewer-underline-text-face)))))))

(defun eg--insert-entry-text ()
  "Insert the text of the current entry."
  (save-excursion
    (cl-loop for line in (eg-entry-lines eg--current-entry)
             do (insert (eg--undosify-string line) "\n"))))

(defun eg--linkify-entry-text ()
  "Add links to the current buffer text."
  (when (eg-entry-short-p eg--current-entry)
    (save-excursion
      (cl-loop for link in (eg-entry-offsets eg--current-entry)
               do (when (eg-valid-pointer-p link)
                    (make-text-button
                     (point-at-bol)
                     (point-at-eol)
                     'action `(lambda (_) (eg--view-entry ,link))
                     'face 'eg-viewer-text-link-face
                     'help-echo "View this entry"
                     'follow-link t))
               (forward-line)))))

(defmacro eg--with-valid-buffer (&rest body)
  "Evaluate BODY after checking the current buffer is a guide."
  `(if eg--current-guide
       (progn
         ,@body)
     (error "The current buffer doesn't appear to be an EG buffer")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Norton guide viewing mode and commands.

(defvar eg-mode-map nil
  "Local keymap for Expert Guide.")

(unless eg-mode-map
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map t)
    (define-key map (kbd "TAB") #'eg-jump-next-link)
    (define-key map [backtab]   #'eg-jump-prev-link)
    (define-key map ">"         #'eg-goto-next-entry-maybe)
    (define-key map "l"         #'eg-goto-next-entry-maybe)
    (define-key map "d"         #'eg-goto-next-entry-maybe)
    (define-key map "<"         #'eg-goto-prev-entry-maybe)
    (define-key map "h"         #'eg-goto-prev-entry-maybe)
    (define-key map "a"         #'eg-goto-prev-entry-maybe)
    (define-key map "^"         #'eg-goto-parent-entry-maybe)
    (define-key map "k"         #'eg-goto-parent-entry-maybe)
    (define-key map "w"         #'eg-goto-parent-entry-maybe)
    (define-key map "f"         #'eg-goto-first-entry)
    (define-key map "s"         #'eg-toggle-view-source)
    (define-key map "m"         #'eg-view-menu)
    (define-key map "c"         #'eg-view-credits)
    (define-key map "q"         #'eg-quit)
    (define-key map "?"         #'describe-mode)
    (setq eg-mode-map map)))

(easy-menu-define
  eg-mode-menu eg-mode-map "Expert Guide menu"
  '("EG"
    ["Credits" eg-view-credits]
    ["Menu"    eg-view-menu]
    "--"
    ["Previous entry" eg-goto-prev-entry-maybe   (and eg--current-entry (eg-entry-has-previous-p eg--current-entry))]
    ["Parent entry"   eg-goto-parent-entry-maybe (and eg--current-entry (eg-entry-has-parent-p eg--current-entry))]
    ["Next entry"     eg-goto-next-entry-maybe   (and eg--current-entry (eg-entry-has-next-p eg--current-entry))]
    "--"
    ("See also" :active nil)
    "--"
    ["Quit" eg-quit]))

(defun eg--refresh-guide-menu ()
  "Refresh the guide menu in the EG menu."
  (when eg--current-guide
    (easy-menu-add-item
     eg-mode-menu
     nil
     (easy-menu-create-menu
      "Menu"
      (cl-loop for menu in (eg-guide-menus eg--current-guide)
               collect
               (cons
                (eg-menu-title menu)
                (cl-loop for prompt in (eg-menu-prompts menu)
                         and link   in (eg-menu-offsets menu)
                         collect
                         (vector prompt
                                 `(lambda ()
                                    (interactive)
                                    (eg--view-entry ,link))))))))))

(defun eg--refresh-see-also-menu ()
  "Refresh the see-also item in the EG menu."
  (when (and eg--current-guide eg--current-entry)
    (easy-menu-add-item
     eg-mode-menu
     nil
     (easy-menu-create-menu
      "See also"
      (if (and (eq eg--currently-displaying :eg-entry) eg--current-entry (eg-entry-has-see-also eg--current-entry))
          (cl-loop for see in (eg-see-also-prompts (eg-entry-see-also eg--current-entry))
                   and see-link in (eg-see-also-offsets (eg-entry-see-also eg--current-entry))
                   collect
                   (vector see
                           `(lambda ()
                              (interactive)
                              (eg--view-entry ,see-link))))
        (list ["Nothing" :active nil]))))))

(add-hook 'menu-bar-update-hook #'eg--refresh-guide-menu)
(add-hook 'menu-bar-update-hook #'eg--refresh-see-also-menu)

(put 'eg-mode 'mode-class 'special)

(defun eg-mode ()
  "Major mode for viewing Norton Guide database files.

The key bindings for `eg-mode' are:

\\{eg-mode-map}"
  (kill-all-local-variables)
  (use-local-map eg-mode-map)
  (setq major-mode         'eg-mode
        mode-name          "Expert Guide"
        buffer-read-only   t
        truncate-lines     t
        header-line-format (eg--header-line))
  (buffer-disable-undo))

(defun eg-jump-next-link ()
  "Jump to the next link in the buffer."
  (interactive)
  (eg--with-valid-buffer
   (unless (next-button (point))
     (setf (point) (point-min)))
   (forward-button 1)))

(defun eg-jump-prev-link ()
  "Jump to the previous link in the buffer."
  (interactive)
  (eg--with-valid-buffer
   (unless (previous-button (point))
     (setf (point) (point-max)))
   (backward-button 1)))

(defun eg-goto-parent-entry-maybe ()
  "Load and view the parent entry, if there is one."
  (interactive)
  (eg--with-valid-buffer
   (when (and eg--current-entry (eg-entry-has-parent-p eg--current-entry))
     (eg--view-entry (eg-entry-parent eg--current-entry)))))

(defun eg-goto-next-entry-maybe ()
  "Load and view the next entry, if there is one."
  (interactive)
  (eg--with-valid-buffer
   (when (and eg--current-entry (eg-entry-has-next-p eg--current-entry))
     (eg--view-entry (eg-entry-next eg--current-entry)))))

(defun eg-goto-prev-entry-maybe ()
  "Load and view the previous entry, if there is one."
  (interactive)
  (eg--with-valid-buffer
   (when (and eg--current-entry (eg-entry-has-previous-p eg--current-entry))
     (eg--view-entry (eg-entry-previous eg--current-entry)))))

(defun eg-goto-first-entry ()
  "Jump to and view the first entry."
  (interactive)
  (eg--with-valid-buffer
   (eg--view-entry (eg-goto-first eg--current-guide))))

(defun eg-view-menu ()
  "View the current guide's menu."
  (interactive)
  (eg--with-valid-buffer
   (let ((buffer-read-only nil))
     (setf (buffer-string) "")
     (setq eg--current-entry        nil
           eg--currently-displaying :eg-menu)
     (save-excursion
       (cl-loop for menu in (eg-guide-menus eg--current-guide)
                do
                (insert (eg-menu-title menu) "\n")
                (cl-loop for prompt in (eg-menu-prompts menu)
                         and link in (eg-menu-offsets menu)
                         do (insert "\t")
                         (insert-text-button
                          prompt
                          'action `(lambda (_)
                                     (eg--view-entry ,link))
                          'face 'eg-viewer-text-link-face
                          'help-echo (format "View the \"%s\" entry" prompt)
                          'follow-link t)
                         (insert "\n"))))
          (eg--add-top-nav))))

(defun eg-view-credits ()
  "View the credits for the current guide."
  (interactive)
  (eg--with-valid-buffer
   (let ((buffer-read-only nil))
     (setf (buffer-string) "")
     (setq eg--current-entry        nil
           eg--currently-displaying :eg-credits)
     (save-excursion
       (cl-loop for line in (eg-guide-credits eg--current-guide)
                do (insert (eg--undosify-string line) "\n")))
          (eg--add-top-nav))))

(defun eg-toggle-view-source ()
  "Toggle viewing of guide source."
  (interactive)
  (setq eg--viewing-source (not eg--viewing-source))
  (eg--view-entry))

(defun eg-quit ()
  "Quit the EG buffer."
  (interactive)
  (eg--with-valid-buffer
   (eg-close eg--current-guide)
   (kill-buffer)))

;;;###autoload
(defun eg (file)
  "View FILE as a Norton Guide database."
  (interactive "fGuide: ")
  (let ((guide (eg-open file)))
    (if (eg-guide-good-magic-p guide)
        (let ((buffer (get-buffer-create (format "EG: %s" file))))
          (switch-to-buffer buffer)
          (with-current-buffer buffer
            (eg-mode)
            (setq eg--current-guide        guide
                  eg--current-entry        nil
                  eg--currently-displaying nil
                  eg--viewing-source       nil)
            (eg--view-entry)))
      (eg-close guide)
      (error "%s isn't a valid Norton Guide file" file))))

(provide 'eg)

;;; eg.el ends here
