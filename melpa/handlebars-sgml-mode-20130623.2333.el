;;; handlebars-sgml-mode.el --- Add Handlebars contextual indenting support to sgml-mode
;;
;; Copyright (C) 1992, 1995-1996, 1998, 2001-2012
;;   Free Software Foundation, Inc.
;;
;; Author: Geoff Jacobsen <geoffjacobsen@gmail.com>
;; URL: http://github.com/jacott/handlebars-sgml-mode
;; Package-Version: 20130623.2333
;; Package-Commit: 005282c33dfb6dbd2cfd46a4147d261504e8323c
;; Version: 0.1.1


;; This code is a modification of the sgml-mode package.
;;  Original code belongs to the Free Software Foundation
;;  (see sgml-mode.el in GNU Emacs)

;; This file is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty
;; of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;; See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public
;; License along with GNU Emacs; if not, write to the Free
;; Software Foundation, 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;
;; Installation:
;;
;; (require 'handlebars-sgml-mode)

;; ;; decide how to use handlebars-html-mode
;; ;; (handlebars-use-mode 'global) ;; always use handlebars-minor-mode
;; (handlebars-use-mode 'off)       ;; Never use handlebars-mode (the default)
;; ;; (handlebars-use-mode 'minor)  ;; Only use if in 'handlebars-sgml-minor-mode




(eval-when-compile
  (require 'cl))

(require 'sgml-mode) ; Force load here so we can override them

(defconst orig-sgml-close-tag (symbol-function 'sgml-close-tag))
(defconst orig-sgml-lexical-context (symbol-function 'sgml-lexical-context))
(defconst orig-sgml-beginning-of-tag (symbol-function 'sgml-beginning-of-tag))
(defconst orig-sgml-parse-tag-backward (symbol-function 'sgml-parse-tag-backward))
(defconst orig-sgml-calculate-indent (symbol-function 'sgml-calculate-indent))
(defconst orig-sgml-get-context (symbol-function 'sgml-get-context))

(defconst handlebars-sgml-syntax-propertize-function
  (syntax-propertize-rules
   ;; handlebars comments
   ("{\\({\\)\\(!\\)\\(.*\\)\\(}\\)}" (1 "<1") (2 "<2") (3 "w") (4 ">"))
   ;; handlebars special # / >
   ("\\({{\\)\\([#/>]\\).*\\(}}\\)" (1 "(}") (2 ".") (3 "){"))

  ;; Use the `b' style of comments to avoid interference with the -- ... --
  ;; comments recognized when `sgml-specials' includes ?-.
  ;; FIXME: beware of <!--> blabla <!--> !!
   ("\\(<\\)!--" (1 "< b"))
    ("--[ \t\n]*\\(>\\)" (1 "> b"))
    ;; Double quotes outside of tags should not introduce strings.
    ;; Be careful to call `syntax-ppss' on a position before the one we're
    ;; going to change, so as not to need to flush the data we just computed.
    ("\"" (0 (if (prog1 (zerop (car (syntax-ppss (match-beginning 0))))
                   (goto-char (match-end 0)))
                 "."))))
  "Syntactic keywords for `sgml-mode'.")

(define-minor-mode handlebars-sgml-minor-mode
  "Handlebars sgml minor mode")

(defun handlebars-use-mode (mode)
  "Switch mode to determine how to override sgml-mode.
'global to always use handlebars.
'off    to never use handlebars [the default].
'minor  to use handlebars only in `handlebars-sgml-minor-mode'.
"
  (cond
   ((eq mode 'global)
    (add-hook 'html-mode-hook 'handlebars-set-syntax-propertize-function)
    (remove-hook 'handlebars-sgml-minor-mode-hook 'handlebars-set-syntax-propertize-function)
    (fset 'sgml-get-context (symbol-function 'handlebars-sgml-get-context))
    (fset 'sgml-calculate-indent (symbol-function 'handlebars-sgml-calculate-indent))
    (fset 'sgml-parse-tag-backward (symbol-function 'handlebars-sgml-parse-tag-backward))
    (fset 'sgml-beginning-of-tag (symbol-function 'handlebars-sgml-beginning-of-tag))
    (fset 'sgml-lexical-context (symbol-function 'handlebars-sgml-lexical-context))
    (fset 'sgml-close-tag (symbol-function 'handlebars-sgml-close-tag)))
   ((eq mode 'minor)
    (remove-hook 'html-mode-hook 'handlebars-set-syntax-propertize-function)
    (add-hook 'handlebars-sgml-minor-mode-hook 'handlebars-set-syntax-propertize-function)
    (fset 'sgml-get-context (symbol-function 'handlebars-ctx-sgml-get-context))
    (fset 'sgml-calculate-indent (symbol-function 'handlebars-ctx-sgml-calculate-indent))
    (fset 'sgml-parse-tag-backward (symbol-function 'handlebars-ctx-sgml-parse-tag-backward))
    (fset 'sgml-beginning-of-tag (symbol-function 'handlebars-ctx-sgml-beginning-of-tag))
    (fset 'sgml-lexical-context (symbol-function 'handlebars-ctx-sgml-lexical-context))
    (fset 'sgml-close-tag (symbol-function 'handlebars-ctx-sgml-close-tag)))
   (t
    (remove-hook 'html-mode-hook 'handlebars-set-syntax-propertize-function)
    (remove-hook 'handlebars-sgml-minor-mode-hook 'handlebars-set-syntax-propertize-function)
    (fset 'sgml-get-context orig-sgml-get-context)
    (fset 'sgml-calculate-indent orig-sgml-calculate-indent)
    (fset 'sgml-parse-tag-backward orig-sgml-parse-tag-backward)
    (fset 'sgml-beginning-of-tag orig-sgml-beginning-of-tag)
    (fset 'sgml-lexical-context orig-sgml-lexical-context)
    (fset 'sgml-close-tag orig-sgml-close-tag)))
  mode)

(defun handlebars-set-syntax-propertize-function ()
  (set (make-local-variable 'syntax-propertize-function)
       handlebars-sgml-syntax-propertize-function))

(defun handlebars-ctx-sgml-get-context (&optional until)
  (if handlebars-sgml-minor-mode
      (handlebars-sgml-get-context until)
    (funcall orig-sgml-get-context until)))

(defun handlebars-sgml-get-context (&optional until)
  "Determine the context of the current position.
By default, parse until we find a start-tag as the first thing on a line.
If UNTIL is `empty', return even if the context is empty (i.e.
we just skipped over some element and got to a beginning of line).

The context is a list of tag-info structures.  The last one is the tag
immediately enclosing the current position.

Point is assumed to be outside of any tag.  If we discover that it's
not the case, the first tag returned is the one inside which we are.

This version has handlebars support.
"
  (let ((here (point))
	(stack nil)
	(ignore nil)
	(context nil)
	tag-info)
    ;; CONTEXT keeps track of the tag-stack
    ;; STACK keeps track of the end tags we've seen (and thus the start-tags
    ;;   we'll have to ignore) when skipping over matching open..close pairs.
    ;; IGNORE is a list of tags that can be ignored because they have been
    ;;   closed implicitly.
    (skip-chars-backward " \t\n")      ; Make sure we're not at indentation.
    (while
	(and (not (eq until 'now))
	     (or stack
		 (not (if until (eq until 'empty) context))
		 (not (sgml-at-indentation-p))
		 (and context
		      (/= (point) (sgml-tag-start (car context)))
		      (sgml-unclosed-tag-p (sgml-tag-name (car context)))))
	     (setq tag-info (ignore-errors (handlebars-sgml-parse-tag-backward))))

      ;; This tag may enclose things we thought were tags.  If so,
      ;; discard them.
      (while (and context
                  (> (sgml-tag-end tag-info)
                     (sgml-tag-end (car context))))
        (setq context (cdr context)))

      (cond
       ((> (sgml-tag-end tag-info) here)
	;; Oops!!  Looks like we were not outside of any tag, after all.
	(push tag-info context)
	(setq until 'now))

       ;; start-tag
       ((memq (sgml-tag-type tag-info) '(open handlebars-open))
	(cond
	 ((null stack)
	  (if (assoc-string (sgml-tag-name tag-info) ignore t)
	      ;; There was an implicit end-tag.
	      nil
	    (push tag-info context)
	    ;; We're changing context so the tags implicitly closed inside
	    ;; the previous context aren't implicitly closed here any more.
	    ;; [ Well, actually it depends, but we don't have the info about
	    ;; when it doesn't and when it does.   --Stef ]
	    (setq ignore nil)))
         ((and (eq (car stack) 'handlebars-close) (eq (sgml-tag-type tag-info) 'handlebars-open))
          (setq stack (cdr stack)))
	 ((eq t (and (stringp (car stack)) (compare-strings (sgml-tag-name tag-info) nil nil
				 (car stack) nil nil t)))
	  (setq stack (cdr stack)))
	 (t
	  ;; The open and close tags don't match.
	  (if (not sgml-xml-mode)
	      (unless (sgml-unclosed-tag-p (sgml-tag-name tag-info))
		(message "Unclosed tag <%s>" (sgml-tag-name tag-info))
		(let ((tmp stack))
		  ;; We could just assume that the tag is simply not closed
		  ;; but it's a bad assumption when tags *are* closed but
		  ;; not properly nested.
		  (while (and (cdr tmp)
			      (not (eq t (compare-strings
					  (sgml-tag-name tag-info) nil nil
					  (cadr tmp) nil nil t))))
		    (setq tmp (cdr tmp)))
		  (if (cdr tmp) (setcdr tmp (cddr tmp)))))
	    (message "Unmatched tags <%s> and </%s>"
		     (sgml-tag-name tag-info) (pop stack)))))

	(if (and (null stack) (sgml-unclosed-tag-p (sgml-tag-name tag-info)))
	    ;; This is a top-level open of an implicitly closed tag, so any
	    ;; occurrence of such an open tag at the same level can be ignored
	    ;; because it's been implicitly closed.
	    (push (sgml-tag-name tag-info) ignore)))

       ;; end-tag
       ((eq (sgml-tag-type tag-info) 'handlebars-close)
        (push 'handlebars-close stack))
       ((eq (sgml-tag-type tag-info) 'close)
	(if (sgml-empty-tag-p (sgml-tag-name tag-info))
	    (message "Spurious </%s>: empty tag" (sgml-tag-name tag-info))
	  (push (sgml-tag-name tag-info) stack)))
       ))

    ;; return context
    context))

(defun handlebars-calc-indent (lcon)
  ;; TODO multiline {{}} - do we need it?
  nil)

(defun handlebars-ctx-sgml-calculate-indent (&optional lcon)
  (if handlebars-sgml-minor-mode
      (handlebars-sgml-calculate-indent lcon)
    (funcall orig-sgml-calculate-indent lcon)))

(defun handlebars-sgml-calculate-indent (&optional lcon)
  "Calculate the column to which this line should be indented.
LCON is the lexical context, if any."
  (unless lcon (setq lcon (sgml-lexical-context)))

  ;; Indent comment-start markers inside <!-- just like comment-end markers.
  (if (and (eq (car lcon) 'tag)
	   (looking-at "--")
	   (save-excursion (goto-char (cdr lcon)) (looking-at "<!--")))
      (setq lcon (cons 'comment (+ (cdr lcon) 2))))

  (case (car lcon)

    (string
     ;; Go back to previous non-empty line.
     (while (and (> (point) (cdr lcon))
		 (zerop (forward-line -1))
		 (looking-at "[ \t]*$")))
     (if (> (point) (cdr lcon))
	 ;; Previous line is inside the string.
	 (current-indentation)
       (goto-char (cdr lcon))
       (1+ (current-column))))

    (comment
     (let ((mark (looking-at "--")))
       ;; Go back to previous non-empty line.
       (while (and (> (point) (cdr lcon))
		   (zerop (forward-line -1))
		   (or (looking-at "[ \t]*$")
		       (if mark (not (looking-at "[ \t]*--"))))))
       (if (> (point) (cdr lcon))
	   ;; Previous line is inside the comment.
	   (skip-chars-forward " \t")
	 (goto-char (cdr lcon))
	 ;; Skip `<!' to get to the `--' with which we want to align.
	 (search-forward "--")
	 (goto-char (match-beginning 0)))
       (when (and (not mark) (looking-at "--"))
	 (forward-char 2) (skip-chars-forward " \t"))
       (current-column)))

    ;; We don't know how to indent it.  Let's be honest about it.
    (cdata nil)
    ;; We don't know how to indent it.  Let's be honest about it.
    (pi nil)

    (handlebars (handlebars-calc-indent lcon))

    (tag
     (goto-char (1+ (cdr lcon)))
     (skip-chars-forward "^ \t\n")	;Skip tag name.
     (skip-chars-forward " \t")
     (if (not (eolp))
	 (current-column)
       ;; This is the first attribute: indent.
       (goto-char (1+ (cdr lcon)))
       (+ (current-column) sgml-basic-offset)))

    (text
     (while (looking-at "</\\|{{/")
       (forward-sexp 1)
       (skip-chars-forward " \t"))
     (let* ((here (point))
	    (unclosed (and ;; (not sgml-xml-mode)
		       (looking-at sgml-tag-name-re)
		       (assoc-string (match-string 1)
				     sgml-unclosed-tags 'ignore-case)
		       (match-string 1)))
	    (context
	     ;; If possible, align on the previous non-empty text line.
	     ;; Otherwise, do a more serious parsing to find the
	     ;; tag(s) relative to which we should be indenting.
	     (if (and (not unclosed) (skip-chars-backward " \t")
		      (< (skip-chars-backward " \t\n") 0)
		      (back-to-indentation)
		      (> (point) (cdr lcon)))
		 nil
	       (goto-char here)
	       (nreverse (handlebars-sgml-get-context (if unclosed nil 'empty)))))
	    (there (point)))
       ;; Ignore previous unclosed start-tag in context.
       (while (and context unclosed (not (eq (sgml-tag-type (car context)) 'handlebars-open))
		   (eq t (compare-strings
			  (sgml-tag-name (car context)) nil nil
			  unclosed nil nil t)))
	 (setq context (cdr context)))
       ;; Indent to reflect nesting.
       (cond
	;; If we were not in a text context after all, let's try again.
	((and context (> (sgml-tag-end (car context)) here))
	 (goto-char here)
	 (handlebars-sgml-calculate-indent
	  (cons (if (memq (sgml-tag-type (car context)) '(comment cdata))
		    (sgml-tag-type (car context)) 'tag)
		(sgml-tag-start (car context)))))
	;; Align on the first element after the nearest open-tag, if any.
	((and context
	      (goto-char (sgml-tag-end (car context)))
	      (skip-chars-forward " \t\n")
	      (< (point) here) (sgml-at-indentation-p))
	 (current-column))
        ((progn (goto-char here) (looking-at "{{ *else *}}"))
         (goto-char there)
         (+ (current-column)
	    (* sgml-basic-offset (1- (length context)))))
	(t
	 (goto-char there)
	 (+ (current-column)
	    (* sgml-basic-offset (length context)))))))

    (otherwise
     (error "Unrecognized context %s" (car lcon)))

    ))


(defun forward-handlebars-sexp (in-or-out)
  (if (eq 'in in-or-out) (goto-char (- (point) 2)))
  (with-syntax-table text-mode-syntax-table
    (forward-sexp 1)
    (point)))


(defun backward-handlebars-sexp (in-or-out)
  (if (eq 'in in-or-out) (goto-char (+ 2 (point))))
  (with-syntax-table text-mode-syntax-table
    (forward-sexp -1)
    (point)))

(defun handlebars-ctx-sgml-parse-tag-backward (&optional limit)
  (if handlebars-sgml-minor-mode
      (handlebars-sgml-parse-tag-backward limit)
    (funcall orig-sgml-parse-tag-backward limit)))

(defun handlebars-sgml-parse-tag-backward (&optional limit)
  "Parse an SGML tag backward, and return information about the tag.
Assume that parsing starts from within a textual context.
Leave point at the beginning of the tag."
  (catch 'found
    (let ((looking t)
          tag-type tag-start tag-end name)
      (while looking
        (or (re-search-backward "[<>]\\|{{{?\\|}}}?" limit 'move) (error "No tag found"))
        (if (looking-at "}}")
            (progn
              (setq looking (point))
              (backward-handlebars-sexp 'in)
              (if (looking-at "{{[/#]")
                  (progn
                    (goto-char looking)
                    (setq looking nil))))
          (setq looking nil)))
      (when (eq (char-after) ?<)
	;; Oops!! Looks like we were not in a textual context after all!.
	;; Let's try to recover.
        ;; Remember the tag-start so we don't need to look for it later.
	;; This is not just an optimization but also makes sure we don't get
	;; stuck in infloops in cases where "looking back for <" would not go
	;; back far enough.
        (setq tag-start (point))
	(with-syntax-table sgml-tag-syntax-table
	  (let ((pos (point)))
	    (condition-case nil
                ;; FIXME: This does not correctly skip over PI an CDATA tags.
		(forward-sexp)
	      (scan-error
	       ;; This < seems to be just a spurious one, let's ignore it.
	       (goto-char pos)
	       (throw 'found (handlebars-sgml-parse-tag-backward limit))))
	    ;; Check it is really a tag, without any extra < or > inside.
	    (unless (sgml-tag-text-p pos (point))
	      (goto-char pos)
	      (throw 'found (handlebars-sgml-parse-tag-backward limit)))
	    (forward-char -1))))
      (setq tag-end (1+ (point)))
      (cond
       ((sgml-looking-back-at "--")	; comment
	(setq tag-type 'comment
	      tag-start (or tag-start (search-backward "<!--" nil t))))
       ((sgml-looking-back-at "]]")	; cdata
	(setq tag-type 'cdata
	      tag-start (or tag-start
                            (re-search-backward "<!\\[[A-Z]+\\[" nil t))))
       ((sgml-looking-back-at "?")      ; XML processing-instruction
        (setq tag-type 'pi
              ;; IIUC: SGML processing instructions take the form <?foo ...>
              ;; i.e. a "normal" tag, handled below.  In XML this is changed
              ;; to <?foo ... ?> where "..." can contain < and > and even <?
              ;; but not ?>.  This means that when parsing backward, there's
              ;; no easy way to make sure that we find the real beginning of
              ;; the PI.
	      tag-start (or tag-start (search-backward "<?" nil t))))

       ((looking-at "}}")
        (setq tag-type 'handlebars
              tag-start (or tag-start (backward-handlebars-sexp 'in)))
        (goto-char (+ 2 tag-start))
        (cond
         ((looking-at "#")
          (setq tag-type 'handlebars-open)
          (goto-char (1+ (point))))

         ((looking-at "/")
          (setq tag-type 'handlebars-close)
          (goto-char (1+ (point))))
         (t
          (setq tag-type 'handlebars-else)))
        (setq name (sgml-parse-tag-name))
        )

       (t
        (unless tag-start
          (setq tag-start
                (with-syntax-table sgml-tag-syntax-table
                  (goto-char tag-end)
                  (condition-case nil
                      (backward-sexp)
                    (scan-error
                     ;; This > isn't really the end of a tag. Skip it.
                     (goto-char (1- tag-end))
                     (throw 'found (handlebars-sgml-parse-tag-backward limit))))
                  (point))))
	(goto-char (1+ tag-start))
	(case (char-after)
	  (?! (setq tag-type 'decl))    ; declaration
	  (?? (setq tag-type 'pi))      ; processing-instruction
	  (?% (setq tag-type 'jsp))	; JSP tags
	  (?/				; close-tag
	   (forward-char 1)
	   (setq tag-type 'close
		 name (sgml-parse-tag-name)))
	  (t				; open or empty tag
	   (setq tag-type 'open
		 name (sgml-parse-tag-name))
	   (if (or (eq ?/ (char-before (- tag-end 1)))
		   (sgml-empty-tag-p name))
	       (setq tag-type 'empty))))))
      (goto-char tag-start)
      (sgml-make-tag tag-type tag-start tag-end name))))

(defun handlebars-ctx-sgml-beginning-of-tag (&optional top-level)
  (if handlebars-sgml-minor-mode
      (handlebars-sgml-beginning-of-tag top-level)
    (funcall orig-sgml-beginning-of-tag top-level)))

(defun handlebars-sgml-beginning-of-tag (&optional top-level)
  "Skip to beginning of tag and return its name.
If this can't be done, return nil."
  (let ((context (sgml-lexical-context)))
    (if (eq (car context) 'tag)
	(progn
	  (goto-char (cdr context))
	  (when (looking-at sgml-tag-name-re)
	    (match-string-no-properties 1)))
      (if top-level nil
	(when (not (eq (car context) 'text))
	  (goto-char (cdr context))
	  (handlebars-sgml-beginning-of-tag t))))))

(defun handlebars-ctx-sgml-lexical-context (&optional limit)
  (if handlebars-sgml-minor-mode
      (handlebars-sgml-lexical-context limit)
    (funcall orig-sgml-lexical-context limit)))

(defun handlebars-sgml-lexical-context (&optional limit)
  "Return the lexical context at point as (TYPE . START).
START is the location of the start of the lexical element.
TYPE is one of `string', `comment', `tag', `cdata', `pi', or `text'.

Optional argument LIMIT is the position to start parsing from.
If nil, start from a preceding tag at indentation."
  (save-excursion
    (let ((pos (point))
	  text-start state)
      (if limit
          (goto-char limit)
        ;; Skip tags backwards until we find one at indentation
        (while (and (ignore-errors (handlebars-sgml-parse-tag-backward))
                    (not (sgml-at-indentation-p)))))
      (with-syntax-table sgml-tag-syntax-table
	(while (< (point) pos)
	  ;; When entering this loop we're inside text.
	  (setq text-start (point))
	  (skip-chars-forward "^<{" pos) ; GKJ (skip-chars-forward "^<" pos)
          (setq state
                (cond
                 ((= (point) pos)
                  ;; We got to the end without seeing a tag.
                  nil)
                 ((looking-at "<!\\[[A-Z]+\\[")
                  ;; We've found a CDATA section or similar.
                  (let ((cdata-start (point)))
                    (unless (search-forward "]]>" pos 'move)
                      (list 0 nil nil 'cdata nil nil nil nil cdata-start))))
		 ((looking-at comment-start-skip)
		  ;; parse-partial-sexp doesn't handle <!-- comments -->,
		  ;; or only if ?- is in sgml-specials, so match explicitly
		  (let ((start (point)))
		    (unless (re-search-forward comment-end-skip pos 'move)
		      (list 0 nil nil nil t nil nil nil start))))
                 ((and sgml-xml-mode (looking-at "<\\?"))
                  ;; Processing Instructions.
                  ;; In SGML, it's basically a normal tag of the form
                  ;; <?NAME ...> but in XML, it takes the form <? ... ?>.
                  (let ((pi-start (point)))
                    (unless (search-forward "?>" pos 'move)
                      (list 0 nil nil 'pi nil nil nil nil pi-start))))
                 ;; handlebars partial
                 ((looking-at "{{#")
                  ;; handlebars block
                  (forward-handlebars-sexp 'out)
                  'handlebars)
                 ((looking-at "{{")
                  ;; handlebars
                  (forward-handlebars-sexp 'out)
                  nil)
                 ((looking-at "<")  ; GKJ (t
                  ;; We've reached a tag.  Parse it.
                  ;; FIXME: Handle net-enabling start-tags
                  (parse-partial-sexp (point) pos 0))
                 (t
                  (forward-char 1))
                 ))))
      (cond
       ((eq 'handlebars state) (cons 'handlebars text-start))
       ((memq (nth 3 state) '(cdata pi)) (cons (nth 3 state) (nth 8 state)))
       ((nth 3 state) (cons 'string (nth 8 state)))
       ((nth 4 state) (cons 'comment (nth 8 state)))
       ((and state (> (nth 0 state) 0)) (cons 'tag (nth 1 state)))
       (t (cons 'text text-start))))))

(defun handlebars-ctx-sgml-close-tag ()
  (if handlebars-sgml-minor-mode
      (handlebars-sgml-close-tag)
    (funcall orig-sgml-close-tag)))

(defun handlebars-sgml-close-tag ()
  "Close current element.
Depending on context, inserts a matching close-tag, or closes
the current start-tag or the current comment or the current cdata, ..."
  (interactive)
  (case (car (handlebars-sgml-lexical-context))
    (comment 	(insert " -->"))
    (cdata 	(insert "]]>"))
    (pi 	(insert " ?>"))
    (jsp 	(insert " %>"))
    (tag 	(insert " />"))
    (text
     (let ((context (save-excursion (handlebars-sgml-get-context))))
       (when context (setq context (car (last context)))
             (if (eq (sgml-tag-type context) (quote handlebars-open))
                 (insert "{{/" (sgml-tag-name context) "}}")
               (insert "</" (sgml-tag-name context) ">"))
             (indent-according-to-mode))))
    (otherwise
     (error "Nothing to close"))))

(provide 'handlebars-sgml-mode)

;;; handlebars-sgml-mode.el ends here
