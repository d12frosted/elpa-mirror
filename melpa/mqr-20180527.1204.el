;;; mqr.el --- Multi-dimensional query and replace  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Tino Calancha

;; Filename: mqr.el
;; Description: Multi-dimensional query and replace

;; Author: Tino Calancha <tino.calancha@gmail.com>
;; Maintainer: Tino Calancha <tino.calancha@gmail.com>
;; URL: https://github.com/calancha/multi-replace
;; Package-Version: 20180527.1204
;; Package-Commit: 4ade19d4620b8b61340290bf63fa56d5e493859f
;; Keywords: convenience, extensions, lisp
;; Created: Sat May 12 22:09:30 JST 2018
;; Version: 0.2.3
;; Package-Requires: ((emacs "24.4"))
;; Last-Updated: Sun May 27 20:56:23 JST 2018
;;

;;; Commentary:
;; This lib defines the commands `mqr-replace',
;; `mqr-replace-regexp', `mqr-query-replace' and
;; `mqr-query-replace-regexp' to match and replace several regexps
;; in the region.
;;
;; Interactively, prompt the user for the regexps and their replacements.
;; If the region is active, then the commands act on the active region.
;; Otherwise, they act on the entire buffer.
;;
;; To use this library, save this file in a directory included in
;; your `load-path'.  Then, add the following line into your .emacs:
;;
;; (require 'mqr)
;;
;; You might want to bind `mqr-query-replace', `mqr-query-replace-regexp'
;; to some easy to remember keys.  If you have the Hyper key, then the
;; following combos are analogs to those for the Vanila Emacs commands:
;;
;; (define-key global-map (kbd "H-%") 'mqr-query-replace)
;; (define-key global-map (kbd "C-H-%") 'mqr-query-replace-regexp)
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file is NOT part of GNU Emacs.
;;
;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:


(defvar mqr-alist nil
  "List of conses (REGEXP . REPLACEMENT).")

;; We define `mqr-query-replace-help' and `mqr-query-replace-map'
;; to support `mqr-query-replace' undo feature in Emacs version < 26.
(defconst mqr-query-replace-help
  "Type Space or `y' to replace one match, Delete or `n' to skip to next,
RET or `q' to exit, Period to replace one match and exit,
Comma to replace but not move point immediately,
C-r to enter recursive edit (\\[exit-recursive-edit] to get out again),
C-w to delete match and recursive edit,
C-l to clear the screen, redisplay, and offer same replacement again,
! to replace all remaining matches in this buffer with no more questions,
^ to move point back to previous match,
u to undo previous replacement,
U to undo all replacements,
E to edit the replacement string.
In multi-buffer replacements type `Y' to replace all remaining
matches in all remaining buffers with no more questions,
`N' to skip to the next buffer without replacing remaining matches
in the current buffer."
  "Help message while in `mqr-query-replace'.")

(defvar mqr-query-replace-map
  (let ((map (make-sparse-keymap)))
    (define-key map " " 'act)
    (define-key map "\d" 'skip)
    (define-key map [delete] 'skip)
    (define-key map [backspace] 'skip)
    (define-key map "y" 'act)
    (define-key map "n" 'skip)
    (define-key map "Y" 'act)
    (define-key map "N" 'skip)
    (define-key map "e" 'edit-replacement)
    (define-key map "E" 'edit-replacement)
    (define-key map "," 'act-and-show)
    (define-key map "q" 'exit)
    (define-key map "\r" 'exit)
    (define-key map [return] 'exit)
    (define-key map "." 'act-and-exit)
    (define-key map "\C-r" 'edit)
    (define-key map "\C-w" 'delete-and-edit)
    (define-key map "\C-l" 'recenter)
    (define-key map "!" 'automatic)
    (define-key map "^" 'backup)
    (define-key map "u" 'undo)
    (define-key map "U" 'undo-all)
    (define-key map "\C-h" 'help)
    (define-key map [f1] 'help)
    (define-key map [help] 'help)
    (define-key map "?" 'help)
    (define-key map "\C-g" 'quit)
    (define-key map "\C-]" 'quit)
    (define-key map "\C-v" 'scroll-up)
    (define-key map "\M-v" 'scroll-down)
    (define-key map [next] 'scroll-up)
    (define-key map [prior] 'scroll-down)
    (define-key map [?\C-\M-v] 'scroll-other-window)
    (define-key map [M-next] 'scroll-other-window)
    (define-key map [?\C-\M-\S-v] 'scroll-other-window-down)
    (define-key map [M-prior] 'scroll-other-window-down)
    ;; Binding ESC would prohibit the M-v binding.  Instead, callers
    ;; should check for ESC specially.
    ;; (define-key map "\e" 'exit-prefix)
    (define-key map [escape] 'exit-prefix)
    map)
  "Keymap of responses to questions posed by commands like `query-replace'.
The \"bindings\" in this map are not commands; they are answers.
The valid answers include `act', `skip', `act-and-show',
`act-and-exit', `exit', `exit-prefix', `recenter', `scroll-up',
`scroll-down', `scroll-other-window', `scroll-other-window-down',
`edit', `edit-replacement', `delete-and-edit', `automatic',
`backup', `undo', `undo-all', `quit', and `help'.")

(defun mqr-alist (regexp-list replacements)
  "Make an alist with the elements of REGEXP-LIST and REPLACEMENTS.
Each element is a cons (REGEXP . REPLACEMENT)."
  (let (res)
    (dotimes (i (length regexp-list))
      (push (cons (nth i regexp-list) (nth i replacements)) res))
    (nreverse res)))

(defvar mqr--regexp-replace nil "Non-nil if the user inputs regexps.")

(defun mqr--replacement (matched-str)
  "Return the replacement for MATCHED-STR."
  (save-match-data
    (let* ((match-data nil)
           (to-string
            (assoc-default
             matched-str mqr-alist
             (lambda (reg _str)
               (save-match-data
                 (goto-char (match-beginning 0))
                 (if (looking-at (if mqr--regexp-replace reg (regexp-quote reg)))
                     (setq match-data (match-data))))))))
      (if (and to-string mqr--regexp-replace)
          (let ((replacement (query-replace-compile-replacement to-string 'regexp)))
            (set-match-data match-data)
            (unless (stringp replacement) ; Must be a Lisp expression starting with '\,'
              (setq replacement (funcall (car replacement) (cdr replacement) 0)))
            (match-substitute-replacement replacement))
        to-string))))

(defun mqr--query-replace-interactive-spec (prompt)
  "Helper function to get command arguments.
Ask user input with PROMPT."
  (let* ((common (mqr--replace-interactive-spec prompt)))
    (list (car common)
          nil
          (cadr common)
          (cadr (cdr common))
          (and current-prefix-arg (eq current-prefix-arg '-))
          (with-no-warnings
            (and (use-region-p)
                 (> emacs-major-version 24)
                 (region-noncontiguous-p))))))


;;; Same as `replace--push-stack' in Emacs version >=26
(defmacro mqr-replace--push-stack (replaced search-str next-replace stack)
  "Helper macro to update the local var STACK.
REPLACED, SEARCH-STR and NEXT-REPLACE has same meaning as in
`mqr-perform-replace'"
  (declare (indent 0) (debug (form form form gv-place)))
  `(push (list (point) ,replaced
	           (if ,replaced
		           (list
		            (match-beginning 0) (match-end 0) (current-buffer))
	             (match-data t))
	           ,search-str ,next-replace)
         ,stack))

(defun mqr-replace-match-maybe-edit (newtext fixedcase literal noedit match-data
                                 &optional backward)
  "Make a replacement with `replace-match', editing `\\?'.
Like `replace-match-maybe-edit' with Bug#31492 fixed.
NEWTEXT, FIXEDCASE, LITERAL, NOEDIT, MATCH-data, and BACKWARD
have same meaning as in `replace-match-maybe-edit'."
  (unless (or literal noedit)
    (setq noedit t)
    (while (string-match "\\(\\`\\|[^\\]\\)\\(\\\\\\\\\\)*\\(\\\\\\?\\)"
			 newtext)
      (setq newtext
	    (read-string "Edit replacement string: "
                         (prog1
                             (cons
                              (replace-match "" t t newtext 3)
                              (1+ (match-beginning 3)))
                           (setq match-data
                                 (replace-match-data
                                  nil match-data match-data))))
	    noedit nil)))
  (set-match-data match-data)
  (replace-match newtext fixedcase literal)
  ;; `query-replace' undo feature needs the beginning of the match position,
  ;; but `replace-match' may change it, for instance, with a regexp like "^".
  ;; Ensure that this function preserves the match data (Bug#31492).
  (set-match-data match-data)
  ;; `replace-match' leaves point at the end of the replacement text,
  ;; so move point to the beginning when replacing backward.
  (when backward (goto-char (nth 0 match-data)))
  noedit)

;;; Modify `perform-replace' to handle multiple regexp input.
(defun mqr-perform-replace (from-string replacements
		                                 query-flag regexp-flag delimited-flag
			                             &optional _repeat-count map start end backward region-noncontiguous-p)
  "Modified version of `perform-replace' to handle multi replacements.
Arguments FROM-STRING, QUERY-FLAG, REGEXP-FLAG, DELIMITED-FLAG, MAP, START, END,
BACKWARD and REGION-NONCONTIGUOUS-P have same meaning as in `perform-replace'.
Arg _REPEAT-COUNT is unused.
Arg REPLACEMENTS is ignored: its overwriten inside the function body."
  (or map (setq map mqr-query-replace-map))
  (and query-flag minibuffer-auto-raise
       (raise-frame (window-frame (minibuffer-window))))
  (let* ((case-fold-search
	      (if (and case-fold-search search-upper-case)
              (isearch-no-upper-case-p from-string regexp-flag)
	        case-fold-search))
         (nocasify (not (and case-replace case-fold-search)))
         (literal (or (not regexp-flag) (eq regexp-flag 'literal)))
         (search-string from-string)
         (real-match-data nil)       ; The match data for the current match.
         (next-replacement nil)
         ;; This is non-nil if we know there is nothing for the user
         ;; to edit in the replacement.
         (noedit nil)
         (keep-going t)
         (stack nil)
         (search-string-replaced nil)    ; last string matching `from-string'
         (next-replacement-replaced nil) ; replacement string
                                        ; (substituted regexp)
         (last-was-undo)
         (last-was-act-and-show)
         (update-stack t)
         (replace-count 0)
         (skip-read-only-count 0)
         (skip-filtered-count 0)
         (skip-invisible-count 0)
         (nonempty-match nil)
	     (multi-buffer nil)
	     (recenter-last-op nil)	; Start cycling order with initial position.

         ;; If non-nil, it is marker saying where in the buffer to stop.
         (limit nil)
         ;; Use local binding in add-function below.
         (isearch-filter-predicate isearch-filter-predicate)
         (region-bounds nil)

         ;; Data for the next match.  If a cons, it has the same format as
         ;; (match-data); otherwise it is t if a match is possible at point.
         (match-again t)

         (message
          (if query-flag
              (apply 'propertize
                     (concat "Query replacing "
                             (if backward "backward " "")
                             (if delimited-flag
                                 (or (and (symbolp delimited-flag)
                                          (get delimited-flag
                                               'isearch-message-prefix))
                                     "word ") "")
                             (if regexp-flag "regexp " "")
                             "%s with %s: "
                             (substitute-command-keys
                              "(\\<mqr-query-replace-map>\\[help] for help) "))
                     minibuffer-prompt-properties))))

    ;; Unless a single contiguous chunk is selected, operate on multiple chunks.
    (when region-noncontiguous-p
      (setq region-bounds
            (mapcar (lambda (position)
                      (cons (copy-marker (car position))
                            (copy-marker (cdr position))))
                    (funcall region-extract-function 'bounds)))
      (add-function :after-while isearch-filter-predicate
                    (lambda (start end)
                      (delq nil (mapcar
                                 (lambda (bounds)
                                   (and
                                    (>= start (car bounds))
                                    (<= start (cdr bounds))
                                    (>= end   (car bounds))
                                    (<= end   (cdr bounds))))
                                 region-bounds)))))

    ;; If region is active, in Transient Mark mode, operate on region.
    (if backward
	    (when end
	      (setq limit (copy-marker (min start end)))
	      (goto-char (max start end))
	      (deactivate-mark))
      (when start
	    (setq limit (copy-marker (max start end)))
	    (goto-char (min start end))
	    (deactivate-mark)))

    ;; If last typed key in previous call of multi-buffer perform-replace
    ;; was `automatic-all', don't ask more questions in next files
    (when (eq (lookup-key map (vector last-input-event)) 'automatic-all)
      (setq query-flag nil multi-buffer t))

    (when real-match-data
      (setq next-replacement
            (mqr--replacement
             (buffer-substring-no-properties (match-beginning 0) (match-end 0)))))
    (when query-replace-lazy-highlight
      (setq isearch-lazy-highlight-last-string nil))

    (push-mark)
    (undo-boundary)
    (unwind-protect
	    ;; Loop finding occurrences that perhaps should be replaced.
	    (while (and keep-going
		            (if backward
			            (not (or (bobp) (and limit (<= (point) limit))))
		              (not (or (eobp) (and limit (>= (point) limit)))))
		            ;; Use the next match if it is already known;
		            ;; otherwise, search for a match after moving forward
		            ;; one char if progress is required.
		            (setq real-match-data
			              (cond ((consp match-again)
				                 (goto-char (if backward
						                        (nth 0 match-again)
					                          (nth 1 match-again)))
				                 (replace-match-data
				                  t real-match-data match-again))
				                ;; MATCH-AGAIN non-nil means accept an
				                ;; adjacent match.
				                (match-again
				                 (and
				                  (replace-search search-string limit
						                          regexp-flag delimited-flag
						                          case-fold-search backward)
				                  ;; For speed, use only integers and
				                  ;; reuse the list used last time.
				                  (replace-match-data t real-match-data)))
				                ((and (if backward
					                      (> (1- (point)) (point-min))
					                    (< (1+ (point)) (point-max)))
				                      (or (null limit)
					                      (if backward
					                          (> (1- (point)) limit)
					                        (< (1+ (point)) limit))))
				                 ;; If not accepting adjacent matches,
				                 ;; move one char to the right before
				                 ;; searching again.  Undo the motion
				                 ;; if the search fails.
				                 (let ((opoint (point)))
				                   (forward-char (if backward -1 1))
				                   (if (replace-search search-string limit
						                               regexp-flag delimited-flag
						                               case-fold-search backward)
				                       (replace-match-data
					                    t real-match-data)
				                     (goto-char opoint)
				                     nil))))))

	      ;; Record whether the match is nonempty, to avoid an infinite loop
	      ;; repeatedly matching the same empty string.
	      (setq nonempty-match
		        (/= (nth 0 real-match-data) (nth 1 real-match-data)))

	      ;; If the match is empty, record that the next one can't be
	      ;; adjacent.

	      ;; Otherwise, if matching a regular expression, do the next
	      ;; match now, since the replacement for this match may
	      ;; affect whether the next match is adjacent to this one.
	      ;; If that match is empty, don't use it.
	      (setq match-again
		        (and nonempty-match
		             (or (not regexp-flag)
			             (and (if backward
				                  (looking-back search-string nil)
				                (looking-at search-string))
			                  (let ((match (match-data)))
				                (and (/= (nth 0 match) (nth 1 match))
				                     match))))))

	      (cond
	       ;; Optionally ignore matches that have a read-only property.
	       ((not (or (not query-replace-skip-read-only)
		             (not (text-property-not-all
			               (nth 0 real-match-data) (nth 1 real-match-data)
			               'read-only nil))))
	        (setq skip-read-only-count (1+ skip-read-only-count)))
	       ;; Optionally filter out matches.
	       ((not (funcall isearch-filter-predicate
                          (nth 0 real-match-data) (nth 1 real-match-data)))
	        (setq skip-filtered-count (1+ skip-filtered-count)))
	       ;; Optionally ignore invisible matches.
	       ((not (or (eq search-invisible t)
		             ;; Don't open overlays for automatic replacements.
		             (and (not query-flag) search-invisible)
		             ;; Open hidden overlays for interactive replacements.
		             (not (isearch-range-invisible
			               (nth 0 real-match-data) (nth 1 real-match-data)))))
	        (setq skip-invisible-count (1+ skip-invisible-count)))
	       (t
	        ;; Calculate the replacement string, if necessary.
	        (when replacements
	          (set-match-data real-match-data)
              (setq next-replacement
                    (mqr--replacement
                     (buffer-substring-no-properties (match-beginning 0) (match-end 0)))))
	        (if (not query-flag)
		        (progn
		          (unless (or literal noedit)
		            (replace-highlight
		             (nth 0 real-match-data) (nth 1 real-match-data)
		             start end search-string
		             regexp-flag delimited-flag case-fold-search backward))
		          (setq noedit
			            (mqr-replace-match-maybe-edit
			             next-replacement nocasify literal
			             noedit real-match-data backward)
			            replace-count (1+ replace-count)))
	          (undo-boundary)
	          (let (done replaced key def)
		        ;; Loop reading commands until one of them sets done,
		        ;; which means it has finished handling this
		        ;; occurrence.  Any command that sets `done' should
		        ;; leave behind proper match data for the stack.
		        ;; Commands not setting `done' need to adjust
		        ;; `real-match-data'.
		        (while (not done)
		          (set-match-data real-match-data)
                  (run-hooks 'replace-update-post-hook) ; Before `replace-highlight'.
                  (replace-highlight
		           (match-beginning 0) (match-end 0)
		           start end search-string
		           regexp-flag delimited-flag case-fold-search backward)
                  (setq next-replacement
                        (mqr--replacement
                         (buffer-substring-no-properties (match-beginning 0) (match-end 0))))
                  ;; Obtain the matched groups: needed only when
                  ;; regexp-flag non nil.
                  (when (and last-was-undo regexp-flag)
                    (setq last-was-undo nil
                          real-match-data
                          (save-excursion
                            (goto-char (match-beginning 0))
                            (looking-at search-string)
                            (match-data t real-match-data))))
                  ;; Matched string and next-replacement-replaced
                  ;; stored in stack.
                  (setq search-string-replaced (buffer-substring-no-properties
                                                (match-beginning 0)
                                                (match-end 0))
                        next-replacement-replaced
                        (query-replace-descr
                         (save-match-data
                           (set-match-data real-match-data)
                           (match-substitute-replacement
                            next-replacement nocasify literal))))
		          ;; Bind message-log-max so we don't fill up the
		          ;; message log with a bunch of identical messages.
		          (let ((message-log-max nil)
			            (replacement-presentation
			             (if query-replace-show-replacement
			                 (save-match-data
			                   (set-match-data real-match-data)
			                   (match-substitute-replacement next-replacement
							                                 nocasify literal))
			               next-replacement)))
		            (let ((target (buffer-substring-no-properties (match-beginning 0) (match-end 0))))
                      (message message
                               (query-replace-descr target)
                               (query-replace-descr replacement-presentation))))
		          (setq key (read-event))
		          ;; Necessary in case something happens during
		          ;; read-event that clobbers the match data.
		          (set-match-data real-match-data)
		          (setq key (vector key))
		          (setq def (lookup-key map key))
		          ;; Restore the match data while we process the command.
		          (cond ((eq def 'help)
			             (with-output-to-temp-buffer "*Help*"
			               (princ
			                (concat "Query replacing "
				                    (if backward "backward " "")
				                    (if delimited-flag
					                    (or (and (symbolp delimited-flag)
						                         (get delimited-flag
                                                      'isearch-message-prefix))
					                        "word ") "")
				                    (if regexp-flag "regexp " "")
				                    from-string " with "
				                    next-replacement ".\n\n"
				                    (substitute-command-keys
				                     mqr-query-replace-help)))
			               (with-current-buffer standard-output
			                 (help-mode))))
			            ((eq def 'exit)
			             (setq keep-going nil)
			             (setq done t))
			            ((eq def 'exit-current)
			             (setq multi-buffer t keep-going nil done t))
			            ((eq def 'backup)
			             (if stack
			                 (let ((elt (pop stack)))
			                   (goto-char (nth 0 elt))
			                   (setq replaced (nth 1 elt)
				                     real-match-data
				                     (replace-match-data
				                      t real-match-data
				                      (nth 2 elt))))
			               (message "No previous match")
			               (ding 'no-terminate)
			               (sit-for 1)))
			            ((or (eq def 'undo) (eq def 'undo-all))
			             (if (null stack)
                             (progn
                               (message "Nothing to undo")
                               (ding 'no-terminate)
                               (sit-for 1))
			               (let ((stack-idx         0)
                                 (stack-len         (length stack))
                                 (num-replacements  0)
                                 (nocasify t) ; Undo must preserve case (Bug#31073).
                                 search-string
                                 next-replacement)
                             (while (and (< stack-idx stack-len)
                                         stack
                                         (or (null replaced) last-was-act-and-show))
                               (let* ((elt (nth stack-idx stack)))
                                 (setq
                                  stack-idx (1+ stack-idx)
                                  replaced (nth 1 elt)
                                  ;; Bind swapped values
                                  ;; (search-string <--> replacement)
                                  search-string (nth (if replaced 4 3) elt)
                                  next-replacement (nth (if replaced 3 4) elt)
                                  search-string-replaced search-string
                                  next-replacement-replaced next-replacement
                                  last-was-act-and-show nil)

                                 (when (and (= stack-idx stack-len)
                                            (and (null replaced) (not last-was-act-and-show))
                                            (zerop num-replacements))
                                   (message "Nothing to undo")
                                   (ding 'no-terminate)
                                   (sit-for 1))

                                 (when replaced
                                   (setq stack (nthcdr stack-idx stack))
                                   (goto-char (nth 0 elt))
                                   (set-match-data (nth 2 elt))
                                   (setq real-match-data
                                         (save-excursion
                                           (goto-char (match-beginning 0))
                                           (looking-at search-string)
                                           (match-data t (nth 2 elt)))
                                         noedit
                                         (mqr-replace-match-maybe-edit
                                          next-replacement nocasify literal
                                          noedit real-match-data backward)
                                         replace-count (1- replace-count)
                                         real-match-data
                                         (save-excursion
                                           (goto-char (match-beginning 0))
                                           (looking-at next-replacement)
                                           (match-data t (nth 2 elt))))
                                   ;; Set replaced nil to keep in loop
                                   (when (eq def 'undo-all)
                                     (setq replaced nil
                                           stack-len (- stack-len stack-idx)
                                           stack-idx 0
                                           num-replacements
                                           (1+ num-replacements))))))
                             (when (and (eq def 'undo-all)
                                        (null (zerop num-replacements)))
                               (message "Undid %d %s" num-replacements
                                        (if (= num-replacements 1)
                                            "replacement"
                                          "replacements"))
                               (ding 'no-terminate)
                               (sit-for 1)))
			               (setq replaced nil last-was-undo t last-was-act-and-show nil)))
			            ((eq def 'act)
			             (or replaced
			                 (setq noedit
				                   (mqr-replace-match-maybe-edit
				                    next-replacement nocasify literal
				                    noedit real-match-data backward)
				                   replace-count (1+ replace-count)))
			             (setq done t replaced t update-stack (not last-was-act-and-show)))
			            ((eq def 'act-and-exit)
			             (or replaced
			                 (setq noedit
				                   (mqr-replace-match-maybe-edit
				                    next-replacement nocasify literal
				                    noedit real-match-data backward)
				                   replace-count (1+ replace-count)))
			             (setq keep-going nil)
			             (setq done t replaced t))
			            ((eq def 'act-and-show)
			             (unless replaced
			               (setq noedit
				                 (mqr-replace-match-maybe-edit
				                  next-replacement nocasify literal
				                  noedit real-match-data backward)
				                 replace-count (1+ replace-count)
				                 real-match-data (replace-match-data
						                          t real-match-data)
				                 replaced t last-was-act-and-show t)
                           (mqr-replace--push-stack
                             replaced
                             search-string-replaced
                             next-replacement-replaced stack)))
			            ((or (eq def 'automatic) (eq def 'automatic-all))
			             (or replaced
			                 (setq noedit
				                   (mqr-replace-match-maybe-edit
				                    next-replacement nocasify literal
				                    noedit real-match-data backward)
				                   replace-count (1+ replace-count)))
			             (setq done t query-flag nil replaced t)
			             (if (eq def 'automatic-all) (setq multi-buffer t)))
			            ((eq def 'skip)
			             (setq done t update-stack (not last-was-act-and-show)))
			            ((eq def 'recenter)
			             ;; `this-command' has the value `query-replace',
			             ;; so we need to bind it to `recenter-top-bottom'
			             ;; to allow it to detect a sequence of `C-l'.
			             (let ((this-command 'recenter-top-bottom)
			                   (last-command 'recenter-top-bottom))
			               (recenter-top-bottom)))
			            ((eq def 'edit)
			             (let ((opos (point-marker)))
			               (setq real-match-data (replace-match-data
						                          nil real-match-data
						                          real-match-data))
			               (goto-char (match-beginning 0))
			               (save-excursion
			                 (save-window-excursion
			                   (recursive-edit)))
			               (goto-char opos)
			               (set-marker opos nil))
			             ;; Before we make the replacement,
			             ;; decide whether the search string
			             ;; can match again just after this match.
			             (if (and regexp-flag nonempty-match)
			                 (setq match-again (and (looking-at search-string)
						                            (match-data)))))
			            ;; Edit replacement.
			            ((eq def 'edit-replacement)
			             (setq real-match-data (replace-match-data
						                        nil real-match-data
						                        real-match-data)
			                   next-replacement
			                   (read-string "Edit replacement string: "
                                            next-replacement)
			                   noedit nil)
			             (if replaced
			                 (set-match-data real-match-data)
			               (setq noedit
				                 (mqr-replace-match-maybe-edit
				                  next-replacement nocasify literal noedit
				                  real-match-data backward)
				                 replaced t)
				           (setq next-replacement-replaced next-replacement))
			             (setq done t))

			            ((eq def 'delete-and-edit)
			             (replace-match "" t t)
			             (setq real-match-data (replace-match-data
						                        nil real-match-data))
			             (replace-dehighlight)
			             (save-excursion (recursive-edit))
			             (setq replaced t))
			            ;; Note: we do not need to treat `exit-prefix'
			            ;; specially here, since we reread
			            ;; any unrecognized character.
			            (t
			             (setq this-command 'mode-exited)
			             (setq keep-going nil)
			             (setq unread-command-events
			                   (append (listify-key-sequence key)
				                       unread-command-events))
			             (setq done t)))
		          (when query-replace-lazy-highlight
		            ;; Force lazy rehighlighting only after replacements.
		            (if (not (memq def '(skip backup)))
			            (setq isearch-lazy-highlight-last-string nil)))
		          (unless (eq def 'recenter)
		            ;; Reset recenter cycling order to initial position.
		            (setq recenter-last-op nil)))
		        ;; Record previous position for ^ when we move on.
		        ;; Change markers to numbers in the match data
		        ;; since lots of markers slow down editing.
                (when update-stack
                  (mqr-replace--push-stack
                    replaced
                    search-string-replaced
                    next-replacement-replaced stack))
                (setq next-replacement-replaced nil
                      search-string-replaced    nil
                      last-was-act-and-show     nil))))))
      (replace-dehighlight))
    (or unread-command-events
	    (message "Replaced %d occurrence%s%s"
		         replace-count
		         (if (= replace-count 1) "" "s")
		         (if (> (+ skip-read-only-count
			               skip-filtered-count
			               skip-invisible-count) 0)
		             (format " (skipped %s)"
			                 (mapconcat
			                  'identity
			                  (delq nil (list
					                     (if (> skip-read-only-count 0)
					                         (format "%s read-only"
						                             skip-read-only-count))
					                     (if (> skip-invisible-count 0)
					                         (format "%s invisible"
						                             skip-invisible-count))
					                     (if (> skip-filtered-count 0)
					                         (format "%s filtered out"
						                             skip-filtered-count))))
			                  ", "))
		           "")))
    (or (and keep-going stack) multi-buffer)))

(defun mqr--replace-interactive-spec (prompt)
  "Helper function to get command arguments.
Ask user input with PROMPT."
  (let ((alist '())
        (start (if (use-region-p) (region-beginning) (point-min)))
        (end (if (use-region-p) (region-end) (point-max)))
        (first-prompt t)
        regexp replace)
    (while (not (equal regexp ""))
      (let (query-replace-defaults)
        (setq regexp
              (query-replace-read-from
               (format
                "%s%s" prompt (if first-prompt
                                  ""
                                " [RET to start replacements]"))
               nil))
        (if first-prompt (setq first-prompt nil))
        (setq query-replace-defaults nil)
        (unless (equal regexp "")
          (setq replace (query-replace-read-to regexp prompt nil))
          (setq query-replace-defaults nil)
          (push (cons regexp replace) alist))))
    (list (nreverse alist) start end)))


;;; Multi replace (regexp)
(defun mqr--replace (alist &optional start end regexp-flag)
  "Helper function for `mqr-replace' and `mqr-replace-regexp'.
Argument ALIST is a list of conses (REGEXP-OR-STRING . TO).
START and END define the region where the commands act.
If REGEXP-FLAG is non-nil then call `mqr-replace-regexp'.  Otherwise,
call `mqr-replace'."
  (unless start (setq start (point-min)))
  (unless end (setq end (point-max)))
  (let ((regexp
         (if regexp-flag (mapconcat #'identity (mapcar #'car alist) "\\|")
           (regexp-opt (mapcar #'car alist))))
        (mqr-alist alist))
    (mqr-perform-replace regexp '("") nil t nil nil nil start end)))

;;;###autoload
(defun mqr-replace (alist &optional start end)
  "Match and replace several strings.
ALIST is a list of conses (STRING . TO).
START and END define the region where look for matches.  If the
region is active, then they default to `region-beginning'
and `region-end'.  Otherwise, apply the command in the entire buffer.

Interactively, prompt user for the conses (STRING . TO) until
the user inputs '' for STRING."
  (interactive (mqr--replace-interactive-spec "Multi replace"))
  (mqr--replace alist start end))

;;;###autoload
(defun mqr-replace-regexp (alist &optional start end)
  "Match and replace several regexps.
ALIST is a list of conses (REGEXP . TO).
Match regexps in the order they appear in ALIST.

START and END define the region where look for matches.  If the
region is active, then they default to `region-beginning'
and `region-end'.  Otherwise, apply the command in the entire buffer.

Interactively, prompt user for the conses (REGEXP . TO) until
the user inputs '' for REGEXP."
  (interactive (mqr--replace-interactive-spec "Multi replace regexp"))
  (let ((mqr--regexp-replace t))
    (mqr--replace alist start end 'regexp-flag)))



;;; Multi query replace (regexp)
;;;###autoload
(defun mqr-query-replace (alist &optional delimited start end backward region-noncontiguous-p)
  "Multi-dimensional version of `query-replace'.
ALIST is a list of conses (STRING . REPLACEMENT).

Optional arguments DELIMITED, START, END, BACKWARD and REGION-NONCONTIGUOUS-P
have same meaning as in `query-replace'.

Interactively, prompt for the conses (STRING . REPLACEMENT) until the user
inputs RET for STRING."
  (interactive (mqr--query-replace-interactive-spec "Multi query replace"))
  (let ((from-string (regexp-opt (mapcar #'car alist)))
        (mqr-alist alist))
    (mqr-perform-replace from-string '("") t t delimited nil nil start end backward region-noncontiguous-p)))

;;;###autoload
(defun mqr-query-replace-regexp (alist &optional delimited start end backward region-noncontiguous-p)
  "Multi-dimensional version of `replace-regexp'.
ALIST is a list of conses (REGEXP . REPLACEMENT).
Match regexps in the order they appear in ALIST.

Optional arguments DELIMITED, START, END, BACKWARD and REGION-NONCONTIGUOUS-P
have same meaning as in `query-replace'.

Interactively, prompt for the conses (REGEXP . REPLACEMENT) until the user
inputs RET for REGEXP."
  (interactive (mqr--query-replace-interactive-spec "Multi query replace regexp"))
  (let ((from-string (mapconcat #'identity (mapcar #'car alist) "\\|"))
        (mqr-alist alist)
        (mqr--regexp-replace t))
    (mqr-perform-replace from-string '("") t t delimited nil nil start end backward region-noncontiguous-p)))


(provide 'mqr)
;;; mqr.el ends here
