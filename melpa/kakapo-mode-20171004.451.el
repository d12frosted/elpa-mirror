;;; kakapo-mode.el --- TABS (hard or soft) for indentation (leading whitespace), and SPACES for alignment.


;; Copyright (C) 2014-2016 Linus Arver

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Version: 1.3
;; Package-Version: 20171004.451
;; Package-Commit: 292e07203c676361a1d918deb5acf2123cd70eaf
;; Keywords: indentation
;; URL: https://github.com/listx/kakapo-mode
;; Package-Requires: ((cl-lib "0.5"))

;;; Commentary:

;; Have you ever fought long battles with the major modes out there (especially
;; programming-language modes) that force its indentation style on you? Worse,
;; have you discovered that some of these modes indent your code with a MIXTURE
;; of TABS *AND* SPACES?
;;
;; Kakapo-mode is about giving back the control of the TAB character back to you,
;; the user, with some conditions:
;;
;;  * The concepts of "indentation" and "leading whitespace" are the same.
;;  * Indentation is taken care of with TAB characters (which are hard TABS by
;;    default) but which can be adjusted to be expanded into SPACES.
;;  * If you press a TAB character *after* some text, we insert SPACES up to the
;;    next tab-stop column; this is a simpler version of "Smart Tabs"
;;    (http://www.emacswiki.org/emacs/SmartTabs).
;;  * If at any point we detect a mixture of tabs and spaces in the indentation,
;;    we display a warning message when modifying the buffer.
;;
;; `kakapo-mode' is very similar to "Smart Tabs", but with a key difference: the
;; latter requires you to write helper functions for it to work properly;
;; instead, kakapo-mode relies on the human user for aesthetics.
;;
;; Central to `kakapo-mode' is the idea of the kakapo tab, or "KTAB". The KTAB is
;; either a hard TAB character or a `tab-width' number of SPACE characters,
;; depending on whether `indent-tabs-mode' is set to true. `kakapo-mode' inserts
;; a KTAB when we are indenting (leading whitespace), or the right number of
;; SPACE characters when we are aligning something inside or at the end of a
;; line.

;;; Installation:

;; Move this file to somewhere in the `load-path'.
;; Then add the following lines to ~/.emacs:
;;
;;  (require 'kakapo-mode)
;;  (add-hook 'text-mode-hook 'kakapo-mode)
;;  (add-hook 'prog-mode-hook 'kakapo-mode)
;;
;; . You can of course change, e.g., `prog-mode-hook' to be some other more
;; specific hook.
;;
;; When `kakapo-mode' is enabled, the TAB key will invoke `kakapo-tab' (inserting
;; KTABS or spaces as necessary) instead of being interpreted as usual by whatever
;; mode is active.
;;
;; You should probably use the following keymappings to play well with Evil mode
;; and any other mode that insists on using mixed TAB/SPACE characters for
;; indentation (leading whitespace). Granted, these helper functions do not
;; respect semantic indentation (as kakapo-mode doesn't care about the *number*
;; of KTABS in the indentation as long as they are all KTABS) --- this kind of
;; simplicity is exactly what kakapo-mode is all about!
;;
;;  (define-key evil-normal-state-map "o" (lambda () (interactive) (kakapo-open nil)))
;;  (define-key evil-normal-state-map "O" (lambda () (interactive) (kakapo-open t)))
;;  (define-key evil-insert-state-map (kbd "RET") 'kakapo-ret-and-indent)
;;  (define-key evil-insert-state-map (kbd "DEL") 'kakapo-backspace)
;;  (define-key evil-insert-state-map (kbd "<S-backspace>") 'kakapo-upline)
;;
;; You can do
;;
;;  (setq kakapo-strict t)
;;
;; if you want to make `kakapo-mode' refuse to modify the buffer if it detects
;; indentation errors (errors are always displayed in the echo area).

;;; Code:

(eval-when-compile (require 'cl-lib))

(defgroup kakapo nil "kakapo configuration"
	:group 'extensions)

; Internal variable used for development/testing purposes.
(defcustom kakapo-debug nil
	"Display debug messages instead of indenting; useful only for
	development."
	:group 'kakapo)

(defcustom kakapo-strict nil
	"If true, then make backspace/enter do nothing on a line with invalid
indentation."
)

(defcustom kakapo-open-blank-line-search-indentation '(nil t)
	"This determines how opening above or below the current line behaves when the
current line is blank. There are two booleans --- one for opening a line above,
and another for opening a line below. If a boolean is set to true, then when we
open a new line in that direction, and when the current line in blank, we search
for the nearest non-blank line's indentation level, and use it.

By default, we only search in the downward direction --- '(nil t).
Vim's behavior is to always use no indentation at all --- '(nil nil).
To always search for the indentation level, use true for both --- '(t t).
"
)

(defun kakapo-hard-tab ()
	"Whether to use hard TAB characters for indentation. If nil, use `tabwidth'
	number of spaces."
	(interactive)
	(bound-and-true-p indent-tabs-mode)
)

; Either print debug message, or execute `func'.
(defmacro kakapo-indent-debug (str func)
	`(progn
		(when kakapo-debug (message ,str))
		,func
	)
)

; Even if we fail the given `condition', still execute `func' if `kakapo-strict'
; is not set to true.
(defmacro kakapo-if (condition func str)
	`(if ,condition
		,func
		(if kakapo-strict
			(error ,str)
			(progn
				,func
				(message ,str)
			)
		)
	)
)

(defun kakapo-err-msg (func-name str)
	(concat
		"<<< "
		func-name
		": "
		str
		" >>>"
	)
)

(defun kakapo-lw ()
	"Retrieve the leading whitespace of the current line."
	(interactive)
	(let*
		(; bindings
			(point-column-0 (line-beginning-position))
			(point-column-till-text
				(save-excursion
					(back-to-indentation)
					(point)
				)
			)
		)
		(buffer-substring-no-properties
			point-column-0 point-column-till-text)
	)
)

(defun kakapo-lc ()
	"Retrieve the current line's contents."
	(interactive)
	(buffer-substring-no-properties
		(line-beginning-position) (line-end-position))
)

(defun kakapo-lw-search (above)
	"Search either above or below the current line for leading whitespace."
	(let*
		(; bindings
			(point-end nil)
			(lw-initial (kakapo-lw))
			(lw "")
			(lc "")
			(loop-continue t)
			(lw-frontier
				(save-excursion
					; `point-end' ensures that we always terminte the `while'
					; loop. If we're searching up, we use `point-min', because
					; that is the ultimate `line-beginning-position' (which is
					; where `forward-line' goes to) when we move up one line
					; repeatedly to the start of the buffer. If we move down to
					; the end of the buffer, we use `point-max', and not the
					; last line's first column, because Emacs defines
					; `point-max' as the point that would be reached if we call
					; `forward-line' past the end of the buffer. In short, the
					; `point-end' variable always guarantees that we exit the
					; `while' loop if all the lines searched either above or
					; below are all blank lines.

					; The `loop-continue' variable is there to short-circuit the
					; loop if the line we're on is not a blank line.
					(setq point-end (if above (point-min) (point-max)))
					(while (and loop-continue (not (eq (point) point-end)))
						(forward-line (if above -1 1))
						(beginning-of-line)
						(setq lw (kakapo-lw))
						(setq lc (kakapo-lc))
						; Only continue the search if the current line is a blank line.
						(if (not (string= "" lc))
							(setq loop-continue nil)
						)
					)
					lw
				)
			)
		)
		(if (string< lw-initial lw-frontier)
			lw-frontier
			lw-initial
		)
	)
)

(defun kakapo-all-ktab (str)
	"Return t if the given string is composed entirely of one
type of `ktab' (either all TABS, or the correct number of
spaces (e.g., if 2-space tabs, make sure we have an even number
of spaces)."
	(interactive)
	(let
		(; bindings
			(regex (if (kakapo-hard-tab)
				"^[\t]+$"
				"^[ ]+$"
				)
			)
		)
		(if (string= "" str)
			t
			(and
				(string-match regex str)
				(if (kakapo-hard-tab)
					t
					(= (% (length str) tab-width) 0)
				)
			)
		)
	)

)

(defun kakapo-tab ()
	"If point is at the beginning of a line, or if all characters
preceding it on the current line are tab characters, insert a
literal tab character. Otherwise, insert space characters based
on tab-width, to simulate a real tab character; this is just like
'expandtab' in Vim"
	(interactive)
	(let*
		(; bindings
			(p (point))
			(point-column-0 (line-beginning-position))
			(line-contents
				(buffer-substring-no-properties
					point-column-0 (line-end-position)))
			(up-to-point
				(buffer-substring-no-properties
					point-column-0 p))
			(columns-tab-width
				(-
					(* tab-width (+ 1 (/ (current-column) tab-width)))
					(current-column)))
			(columns-til-next-tab-stop
				(if (eq 0 columns-tab-width
					)
					tab-width
					columns-tab-width
				))
			; `ktab' is either a hard TAB or soft tab (spaces).
			(ktab (if (kakapo-hard-tab)
				?\t
				(make-string tab-width ?\s)
				)
			)
			(func-name "kakapo-tab")
		)
		(cond
			; If the line is blank, insert a TAB.
			((eq (line-beginning-position) (line-end-position))
				(kakapo-indent-debug
					"BLANK"
					(insert ktab)
				)
			)
			; If line is all-whitespace, insert a TAB, unless we detect mixed
			; tabs/spaces.
			((string-match "^[ \t]+$" line-contents)
				(kakapo-if
					(kakapo-all-ktab line-contents)
					(kakapo-indent-debug
						"TABS LINE"
						(insert ktab)
					)
					(kakapo-err-msg
						func-name
						"INVALID INDENTATION DETECTED ON WHITESPACE-ONLY LINE"
					)
				)
			)

			; Since the all-whitespace above failed, this line has some text on
			; it; we consider the case where it already has leading whitespace.
			((string-match "^[ \t]+" line-contents)
				; Is the leading whitespace all TABS?
				(kakapo-if
					(kakapo-all-ktab (kakapo-lw))
					; Since the leading whitespace is well-formed, we only need
					; consider where point is. If point is inside the
					; well-formed whitespace, we insert a TAB. Otherwise, we
					; insert saces because we are obviously NOT trying to indent
					; all the text.
					(if (string-match "^[ \t]*$" up-to-point)
						(kakapo-indent-debug
							"LEADING TABS TO POINT"
							(insert ktab)
						)
						(kakapo-indent-debug
							"LEADING TABS: POINT IS ELSEWHERE"
							(cl-loop
								repeat
								columns-til-next-tab-stop
								do (insert " "))
						)
					)
					(kakapo-err-msg
						func-name
						"INVALID INDENTATION DETECTED ON NON-EMPTY LINE"
					)
				)
			)
			; We do *not* have leading whitespace. There are two cases: point is
			; located at the beginning of the line, in which case we insert a
			; TAB; otherwise, we insert spaces.
			(t (if (eq point-column-0 p)
				(kakapo-indent-debug
					"NO LEADING WHITESPACE"
					(insert ktab)
				)
				(kakapo-indent-debug
					"NO LEADING WHITESPACE: POINT IS ELSEWHERE"
					(cl-loop
						repeat
						columns-til-next-tab-stop
						do (insert " ")))
				)
			)
		)
	)
)

(defun kakapo-point-in-lw ()
	"Is point inside the leading whitespace on the current line, if any, and is
it correctly placed in it (i.e., on a column that is modulo 0
w.r.t. tab-width)?"
	(interactive)
	(let
		(
			(point-column-till-text
				(save-excursion
					(back-to-indentation)
					(point)
				)
			)
			(lw (kakapo-lw))
		)
		(and
			(<= (point) point-column-till-text)
			(if (kakapo-hard-tab)
				t
				(= 0 (% (current-column) tab-width))
			)
		)
	)
)

(defun kakapo-backspace ()
	"When we press BACKSPACE and point is at the beginning of the line, we
should delete backwards 1 level of indentation, whether that means deleting 1
TAB character, or `tab-width' number of SPACE characters. If point is not at
leading indentation, we check if the to-be-deleted number of characters are all
whitespace characters; in such a case, it's OK to delete them all, as there is
no fear of deleting multiple significant non-whitespace characters. The
to-be-deleted number of characters is calculated with
distance-to-prev-tab-width; the goal is to get point to end up at a
tab-width-interval even when we're deleting pure whitespace."
	(interactive)
	(let*
		(; bindings
			(tab-width-nonconformance-score
				(% (current-column) tab-width)
			)
			(distance-to-prev-tab-width
				(if (and
						(eq 0 tab-width-nonconformance-score)
						(/= (point) (line-beginning-position))
					)
					(if (kakapo-hard-tab)
						1
						tab-width
					)
					tab-width-nonconformance-score
				)
			)
			(columns-til-prev-tab-stop
				(- (point) distance-to-prev-tab-width)
			)
			(deletion-substr
				(buffer-substring-no-properties
					columns-til-prev-tab-stop
					(point)
				)
			)
			(deletion-substr-all-whitespace
				(string-match "^[ \t]+$" deletion-substr)
			)
			(func-name "kakapo-backspace")
			(delete-amount
				(cond
					; If at beginning of the line, delete 1 char only --- no
					; exceptions!
					((= (point) (line-beginning-position))
						1
					)
					((kakapo-point-in-lw)
						(if (kakapo-hard-tab)
							1
							distance-to-prev-tab-width
						)
					)
					; We're here if point is in a 'messy' place somewhere in the
					; middle of text. Here we take care to see if there is a lot
					; of whitespace that we could delete, and if so,
					; aggressively delete away any space/tab characters. We
					; don't care about hard/soft tabs, because by design Kakapo
					; inserts purely space characters if we press TAB in the
					; middle of some text; the idea is to aggressively delete as
					; many whitespace characters as we can, up to the point of
					; the most evenly-divisible 'tab-width' mark. The fact that
					; `deletion-substr-all-whitespace' checks for both spaces
					; and tabs, and that this allows us to naively delete space
					; and tab characters *without* thinking about how those hard
					; TABs might be displayed on screen, is a conscious design
					; choice. We don't care much about destroying TAB characters
					; if they exist in the middle of a line, because that goes
					; against how Kakapo behaves when indenting in the middle of
					; a line (where it chooses to insert space characters, even
					; if we tell Kakapo to use hard tabs).
					(deletion-substr-all-whitespace
						distance-to-prev-tab-width
					)
					; We cannot aggressively find any immediately preceding
					; contiguous strip of whitespace characters, so we
					; conservatively delete just 1 character, as BACKSPACE was
					; naively intended to do.
					(t 1)
				)
			)
		)
		(kakapo-if
			(kakapo-all-ktab (kakapo-lw))
			(delete-char (- delete-amount))
			(kakapo-err-msg
				func-name
				"INVALID INDENTATION DETECTED"
			)
		)
	)
)

(defun kakapo-mixed-lw-ok (lw)
	"Check if the current line is a validly sanctioned
mixed-tabs/spaces line, where the leading whitespace is composed
of a uniform style, such as in Linux Kernel multiline comment
paragraphs. Also see `kakapo-ret-and-indent'."
	(interactive)
	(if (kakapo-hard-tab)
		; If we are using hard tabs, then it is some multiple of hard tabs, plus
		; one space character.
		(string-match "^[\t]*\s$" lw)
		; If we have soft tabs only, then we are only dealing with spaces. We
		; can be sure that the number of these space characters is some multiple
		; of `tab-width' plus 1, and so just test the modulus. This will break
		; if `tab-width' is defined to be 1, because the modulus will always be
		; 0, but we do not care about that extreme case because no one on planet
		; Earth will ever bother to set `tab-width' to 1.
		(= 1 (% (length lw) tab-width))
	)
)

; Pressing RETURN/ENTER is such a closely-tied operation to inserting tabs and
; indentation, that we define a companion function to go along with
; kakapo-tab.
;
; You can use this function like so:
;
;   (define-key evil-insert-state-map (kbd "RET") 'kakapo-ret-and-indent)
(defun kakapo-ret-and-indent ()
	"Insert a newline at point, and indent relative to the current line."
	(interactive)
	(let*
		(
			(lw (kakapo-lw))
			(lc (kakapo-lc))
			(point-column-till-text
				(save-excursion
					(back-to-indentation)
					(point)
				)
			)
			(lw-below (kakapo-lw-search nil))
			(lw-above (kakapo-lw-search t))
			(invalid-char (if (kakapo-hard-tab) " " "\t"))
			(func-name "kakapo-ret-and-indent")
		)
		(cond
			((string-match invalid-char lw)
				; This is a workaround for C-style multi-line commenting. For
				; example, you might have a string that looks like
				; "<TAB><SPACE>*..." in the middle of a comment paragraph. Here
				; the leading whitespace is a TAB followed by a SPACE. This is a
				; reasonable coding style, and we have to support it as an
				; exception. Still, we enforce a strict rule: TABS, if any, must
				; be followed by SPACES.
				(kakapo-if
					(kakapo-mixed-lw-ok lw)
					(insert "\n")
					(kakapo-err-msg
						func-name
						"INVALID INDENTATION DETECTED ON CURRENT LINE"
					)
				)
			)
			; For an empty line, search downwards for indentation, and use that,
			; if any. If no indentation below at all (all empty lines), then
			; search for indentation above, and use that, if any. Otherwise
			; (e.g., there is 0-indented text above and below), do not use
			; insert any indentation.
			((string= "" lc)
				(cond
					((not (string= "" lw-below))
						(kakapo-if
							(kakapo-all-ktab lw-below)
							(insert (concat "\n" lw-below))
							(kakapo-err-msg
								func-name
								(concat
									"INVALID INDENTATION DETECTED ON "
									"NEAREST LINE BELOW"
								)
							)
						)
					)
					((not (string= "" lw-above))
						(kakapo-if
							(kakapo-all-ktab lw-above)
							(insert (concat "\n" lw-above))
							(kakapo-err-msg
								func-name
								(concat
									"INVALID INDENTATION DETECTED ON "
									"NEAREST LINE ABOVE"
								)
							)
						)
					)
					(t (insert "\n"))
				)
			)
			; This is an all-tabs line --- chances are that the indentation was
			; created by this very same function (unless the file we're editing
			; has lots of meaningless all-tabs lines); assuming this is the
			; case, the indentation needs to be preserved as-is. So, we just add
			; the newline at the very begnning of the line, and then move to the
			; end of the line (leaving the indentation untouched).
			((and (kakapo-all-ktab lw) (string= lw lc))
				(progn
					(beginning-of-line)
					(insert "\n")
					(end-of-line)
				)
			)
			; We are here if there is some text on the line already, in which
			; case we simply preserve whatever indentation we found. We take
			; care to remove any whitespace we may be breaking up.
			(t
				(kakapo-if
					(kakapo-all-ktab lw)
					(progn
						(delete-horizontal-space)
						(insert (concat "\n" lw))
					)
					(kakapo-err-msg
						func-name
						"INVALID INDENTATION DETECTED ON CURRENT LINE"
					)
				)
			)
		)
	)
)

; The `kakapo-open' function is meant to be used in conjunction with evil-mode,
; where the default "o" and "O" keys introduce mixed tab/space indentation.
(defun kakapo-open (above)
	"Insert a newline above if `above' is t, otherwise below the current line. For
inserting below, search below for a level of indentation that could be greater
than the current amount, and use that if possible. For inserting above, use the
current indentation level unless we are on a blank line (in which case, use the
indentation level found above).
"
	(interactive)
	(let*
		(; bindings
			(pos-initial (point))
			(lw-initial (kakapo-lw))
			(lc (kakapo-lc))
			(lw-nearest (kakapo-lw-search above))
			(invalid-char (if (kakapo-hard-tab) " " "\t"))
			(err-msg
				(concat
					"INVALID INDENTATION DETECTED ON "
					(cond
						((string-match invalid-char lw-initial) "CURRENT LINE")
						(above  "NEAREST LINE ABOVE")
						(t      "NEAREST LINE BELOW")
					)
				)
			)
			(func-name "kakapo-open")
		)
		(if (and above (eq (line-beginning-position) (point-min)))
			; If we're on the first line, and we want to open above, add a
			; newline above at the first column, disregarding all issues about
			; indentation.
			(progn
				(beginning-of-line)
				(insert "\n")
				(forward-line -1)
				(evil-append nil)
			)
			(kakapo-if
				(and
					(or
						(not (string-match invalid-char lw-nearest))
						(kakapo-mixed-lw-ok lw-nearest)
					)
					(kakapo-all-ktab lw-nearest)
				)
				(progn
					(when above (forward-line -1))
					(end-of-line)
					(insert (concat "\n"
						(if (string= "" lc)
							; Behavior of opening new lines from an empty line is a special
							; case. See `kakapo-open-blank-line-search-indentation'.
							(if (nth (if above 0 1) kakapo-open-blank-line-search-indentation)
								lw-nearest
								lw-initial)
							; For non-blank lines, only search for indentation if opening
							; below; for opening above, use the current indentation level.
							(if above
								lw-initial
								lw-nearest))))
					(evil-append nil)
				)
				(kakapo-err-msg
					func-name
					err-msg
				)
			)

		)
	)
)

; Delete the current whitespace-only line, and go up one line. If you call
; `kakapo-ret-and-indent' repeatedly, you can call `kakapo-upline' to "undo" the
; last call. This function is not strictly necessary, but there are times when
; one presses the RETURN key one too many times. And, undoing that mistake can
; be cumbersome (pressing BACKSPACE repeatedly, or, in evil mode, pressing ESC
; and then deleting the current line ("dd") and then inserting back again at the
; proper indentation "O") --- hence this function.
;
; Although the example above is the main motivation, `kakapo-upline' will try to
; delete any blank lines above or below the cursor. The former case is the one
; explained above. Removing blank lines below the cursor will only occur if we
; hit a non-blank-line "wall" above us. And then, if we run out here,
; `kakapo-upline' will be a NOP (non-operation --- i.e., do nothing).
(defun kakapo-upline ()
	(interactive)
	(let*
		(; bindings
			(point-column-0 (line-beginning-position))
			(lc-up-to-point
				(buffer-substring-no-properties
					point-column-0 (point)))
			(lc-above
				(save-excursion
					(forward-line -1)
					(kakapo-lc)
				)
			)
			(lc-below
				(save-excursion
					(forward-line 1)
					(kakapo-lc)
				)
			)
		)
		(if (string-match "^[ \t]*$" lc-up-to-point)
			(cond
				((string= "" lc-above)
					(progn
						(forward-line -1)
						(delete-char -1)
						(forward-line 1)
						(if (kakapo-all-ktab (kakapo-lc))
							(back-to-indentation)
						)
					)
				)
				((string= "" lc-below)
					(progn
						(forward-line 1)
						(delete-char -1)
						(back-to-indentation)
					)
				)
				(t (ignore))
			)
			(delete-char -1)
		)
	)
)

;;;###autoload
(define-minor-mode kakapo-mode
	"Stupid TAB character."
	:init-value nil
	:lighter " kkp"
	:global nil
	:keymap (let ((map (make-sparse-keymap)))
			(define-key map (kbd "TAB") 'kakapo-tab)
			map))

(provide 'kakapo-mode)

;;; kakapo-mode.el ends here
