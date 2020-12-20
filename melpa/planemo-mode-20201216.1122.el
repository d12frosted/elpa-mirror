;;; planemo-mode.el --- Minor mode for editing Galaxy XML files -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Mehmet Tekman <mtekman89@gmail.com>

;; Author: Mehmet Tekman
;; URL: https://gitlab.com/mtekman/planemo-mode.el
;; Package-Version: 20201216.1122
;; Package-Commit: 9a981f79a2727f87689ae5a07368c41d35902a67
;; Keywords: outlines
;; Package-Requires: ((emacs "27.1") (dash "2.17.0"))
;; Version: 0.3

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; This mode provides fontification and indentation rules for editing
;; Galaxy XML files.

;;; Code:
(require 'nxml-mode)
(require 'dash)
(require 'subr-x)

(defgroup planemo nil
  "Planemo customisable attributes"
  :group 'productivity)

(defcustom planemo-xml-scope
  '("command" "configfile")
  "XML tag to perform Cheetah indentation logic within."
  :type 'list
  :group 'planemo)

(defcustom planemo-root-align-region t
  "Align all lines relative to root.  When the first line in a
section is aligned it alters the root alignment, and by setting
this value to t it aligns all other lines too."
  :type 'boolean
  :group 'planemo)

(defcustom planemo-python-ops
  '("or" "and" "in" "+" "-" "*" "/" "==" "!=")
  "Python operations used by Cheetah."
  :type 'list
  :group 'planemo)

(defcustom planemo-python-fun
  '("enumerate" "str" "int" "open")
  "Python functions used by Cheetah."
  :type 'list
  :group 'planemo)

(defcustom planemo-bash-comms
  '("cat" "head" "tail" "awk" "cut" "ls" "grep" "echo" "touch")
  "Bash commands commonly found in the XML."
  :type 'list
  :group 'planemo)

(defcustom planemo-bash-ops
  '("&&" ">" "<" ">>" "<<" "|" )
  "Bash operations commonly found in the XML."
  :type 'list
  :group 'planemo)

(defconst planemo--start-tags '("if" "for")
  "Defines the Cheetah tags for beginning nested indentation.")

(defconst planemo--end-tags '("end if" "end for")
  "Defines the Cheetah tags for ending nested indentation.
Must complement the ``planemo--start-tags''")

(defconst planemo--middle-tags '("else" "else if")
  "Defines the Cheetah tags that remain un-indented relative to a
  starting tag within a clause.")

(defconst planemo--other-tags
  '("set" "echo" "def" "include" "extends" "import" "from")
  "Defines Cheetah tags that are nested like regular words
  relative to a starting tag.")

(defconst planemo--all-tags
  (append planemo--start-tags planemo--end-tags
          planemo--middle-tags planemo--other-tags)
  "All possible Cheetah tags.")

(defconst planemo--pair-tags
  (append planemo--start-tags planemo--end-tags)
  "All start and end tags.")

(defconst planemo--most-tags
  (append planemo--start-tags planemo--end-tags
          planemo--middle-tags)
  "Tags with the same alignment.")

(defvar planemo--root-alignment 0
  "This is the smallest possible left align value for the
  section, and can only be altered by
  ``planemo--toggle-root-alignment'' on the first non XML line.")

(define-derived-mode planemo-mode nxml-mode "Pl[XML|Cheetah]"
  "Major mode for editing Galaxy XML files."
  (setq-local nxml-child-indent 4
              indent-line-function 'planemo-indent-line
              indent-region-function 'planemo-indent-region)
  (make-face 'cheetah-variable-face)
  (let ((rx-keywords (eval `(rx (group "#" (or ,@planemo--all-tags) eow))))
        (rx-bashcomms (eval `(rx bow (group (or ,@planemo-bash-comms)) eow)))
        (rx-bashops (eval `(rx space (group (or ,@planemo-bash-ops)) space)))
        (rx-pyops (eval `(rx (or bow space) (group (or ,@planemo-python-ops)) (or eow space))))
        (rx-pyfun (eval `(rx (or bow space) (group (or ,@planemo-python-fun)) (or eow space)))))
    (font-lock-add-keywords
     nil
     `((,(rx (group bol (* space) "##" (* any) eol))
        1 font-lock-comment-face)                   ;; comments
       (,(rx (not "\\") (group "$" (? "{") (1+ (or alpha "." "_")) (? "}")))
        1 font-lock-string-face)                    ;; cheetah vars
       (,rx-keywords 1 font-lock-constant-face)     ;; cheetah keywords
       (,rx-bashcomms 1 font-lock-reference-face)   ;; bash commands
       (,rx-bashops 1 font-lock-variable-name-face) ;; bash operations
       (,rx-pyops 1 font-lock-function-name-face)   ;; python ops
       (,rx-pyfun 1 font-lock-variable-name-face)   ;; python functions
       ))
    (font-lock-mode 1)))

(defun planemo--jump-prevtag ()
  "Obtain the spacing and tag of to the previous tag.  Does not
save the excursion because it may be used in succession to
determine hierarchy."
  (let* ((pointnow (point))
         (bounds
          (list (search-backward-regexp
                 (eval `(rx (group "#" (or ,@planemo--pair-tags) eow)))
                 nil t)
                (match-beginning 0) (match-end 0)))
         (tag (buffer-substring-no-properties (1+ (nth 1 bounds))
                                              (nth 2 bounds))))
    (if (car bounds)
        (list (current-indentation) tag
              (planemo--numlines (nth 1 bounds) pointnow))
      (list nil nil))))

(defun planemo--numlines (first second)
  "Calculate lines between FIRST and SECOND, taking into account
the issue with calculating line numbers when SECOND is right at
the beginning of the line."
  (count-matches "\n" first second))

(defun planemo--get-prevtag ()
  "Get the previous tag without changing position."
  (save-excursion (planemo--jump-prevtag)))

(defun planemo--get-forwtag ()
  "Get the first tag on the current line."
  (save-excursion
    (beginning-of-line)
    (search-forward-regexp
     (eval `(rx bol (* space) (group "#" (or ,@planemo--all-tags) eow)))
     (line-end-position) t)
    (buffer-substring-no-properties
     (match-beginning 1) (match-end 1))))

(defun planemo--get-fwot ()
  "Get the first word or tag on the current line."
  (let* ((fword (save-excursion
                  (beginning-of-line)
                  (string-trim
                   (car
                    (split-string
                     (buffer-substring-no-properties
                      (point) (progn (forward-word) (point)))
                     "\n"))))))
    (if (equal "" fword)
        "     "  ;; return blank tag
      (cond ((equal "##" (substring fword nil 2)) "##")
            ((equal "#" (substring fword nil 1))
             (substring (planemo--get-forwtag) 1))
            (t fword)))))

(defconst planemo--matching-pairs
  '(("end for" . "for")
    ("end if" . "if")
    ("if" . "end if")
    ("for" . "end for"))
  "Complementary Cheetah tags.")

(defun planemo--tags-pairp (tag1 tag2)
  "Is TAG1 complementary to TAG2?"
  (--> (alist-get tag1
                  planemo--matching-pairs
                  nil nil 'string=)
       (string= it tag2)))

(defun planemo--matchtag-back (tag)
  "Find the nearest previous start tag that would complement TAG.
Here we stack tags as we find them and pop them off when
consecutive tags pair up."
  (let* ((wanted-tag (alist-get tag planemo--matching-pairs
                                nil nil 'string=))
         (tag-stack nil)
         (error-message (format "Could not find matching pair for '%s'" tag))
         (result nil))
    (if wanted-tag
        (save-excursion
          (while
              (not (-let* (((align curr-tag nl) (planemo--jump-prevtag))
                           (last-tag (car tag-stack)))
                     (cond ((not curr-tag) ;; no prevtag means exceeded bounds
                            (user-error error-message))
                           ((planemo--tags-pairp curr-tag last-tag) ;;pop it from the stack
                            (prog1 nil (setq tag-stack (cdr tag-stack))))
                           ((string= curr-tag wanted-tag) ;; return our wanted tag
                            (setq result (list align curr-tag nl)))
                           (t ;; otherwise push to stack and keep searching
                            (prog1 nil (setq tag-stack (cons curr-tag tag-stack))))))))
          result)
      (user-error error-message))))

;; BEGIN: Indentation outcomes
(defun planemo--ind-alignwith (prev-align)
  "Align the following line with PREV-ALIGN."
  ;;(message "outcome AlignWith: End word, with matching Start word")
  (indent-line-to prev-align))

(defun planemo--ind-findprevmatch (curr-word)
  "Find a previous starting tag to complement CURR-WORD."
  ;;(message "outcome B: End word. Looking for matching Start word")
  (-let (((align _tag) (planemo--matchtag-back curr-word)))
    (if align
        (indent-line-to align))))

(defun planemo--ind-nestunder (prev-align &optional cycle)
  "Nest the current line under PREV-ALIGN.  If CYCLE is given,
then cycle the indentation between either the root alignment, or
nested below the above line."
  ;;(message "outcome NestUnder: Nest under previous tag")
  (if cycle
      (let* ((indents (list (+ 4 prev-align) planemo--root-alignment))
             (curr-align (current-indentation))
             (curr-index (seq-position indents curr-align))
             (next-index (mod (1+ (or curr-index 0)) 2)) ;; length indents
             (next-align (seq-elt indents next-index)))
        (indent-line-to next-align))
    (indent-line-to (+ prev-align 4))))

(defun planemo--ind-cycle (&rest indentlist)
  "Cycle between all INDENTLIST on the current line."
  (let* ((curr-align (current-indentation))
         (curr-index (seq-position indentlist curr-align))
         (next-index (if curr-index
                         (mod (1+ curr-index) (length indentlist))
                       0))
         (next-align (seq-elt indentlist next-index)))
    (setq planemo--root-alignment next-align)
    (message "Root alignment set to %d" next-align)
    (indent-line-to next-align)))

(defun planemo--ind-nothing ()
  "Do nothing to the current line."
  ;;(message "outcome D: Do nothing")
  )

(defun planemo--ind-prevline ()
  "Indent the current line to the previous line."
  ;;(message "outcome PrevLine: No previous tag. Align to previous line.")
  (indent-line-to (save-excursion
                    ;; first non-blank line
                    (re-search-backward (rx (not space)))
                    (current-indentation))))
;; END: Indentation outcomes

;;;###autoload
(defun planemo-indent-region (start end)
  "Indent the current region flanked by START and END positions."
  (interactive (list (region-beginning) (region-end)))
  (save-excursion
    (goto-char start)
    (while (< (point) end)
      (planemo-indent-line) (forward-line 1))))

;;;###autoload
(defun planemo-indent-line ()
  "Indent the current line."
  (interactive)
  (let ((tagldiff (planemo--within-validxml)))
    (if (not tagldiff)     ;; not within a valid XML region
        (nxml-indent-line) ;; do the default indent
      ;; otherwise perform line logic
      (beginning-of-line)
      (let* ((curr-word (planemo--get-fwot))
             (curr-tagp (member curr-word planemo--all-tags))
             (previous-tag (planemo--get-prevtag))
             (prevtag-align (car previous-tag))
             (prevtag-word (cadr previous-tag))
             (prevtag-ldiff (caddr previous-tag))
             (prevline-word (save-excursion
                              (forward-line -1)
                              (planemo--get-fwot)))
             (prevline-isxml (eq (cdr tagldiff) 1))
             (prevtag-ldiff1-p (or (eq 1 prevtag-ldiff)
                                   (member prevline-word
                                           planemo--most-tags))))
        (cond
         (prevtag-word                     ;; previous tag exists
          (let* ((curr-startp (member curr-word planemo--start-tags))
                 (curr-endp (member curr-word planemo--end-tags))
                 (curr-middp (member curr-word planemo--middle-tags))
                 ;;(curr-othrp (member curr-word planemo--other-tags))
                 (prev-startp (member prevtag-word planemo--start-tags))
                 (prev-endp (member prevtag-word planemo--end-tags))
                 (prev-middp (member prevtag-word planemo--middle-tags))
                 (match-pairp (or (and (string= prevtag-word "if")
                                       (member curr-word '("else" "end if")))
                                  (and (string= prevtag-word "for")
                                       (string= curr-word "end for")))))
            (cond
             ;; current is a #tag
             (curr-tagp
              (cond ((or curr-endp curr-middp) ;; end or middle of a pair?
                     (cond
                      ;; ["for"] and "end for": match alignment
                      (match-pairp (planemo--ind-alignwith prevtag-align))
                      ;; ["if"] and "end for" : user did something wrong, do nothing.
                      (prev-startp (planemo--ind-nothing))
                      ;; [ * ] and "end for" : look for a better previous match.
                      (t (planemo--ind-findprevmatch curr-word))))
                    (curr-startp ;; start of a pair?
                     (cond
                      ;; ["end for"] and "for" : unrelated clause, align to it
                      (prev-endp (planemo--ind-alignwith prevtag-align))
                      ;; ["if"] and "for" : nest current under parent
                      (prev-startp (planemo--ind-nestunder prevtag-align))
                      ;; [ * ] and "for" : align to previous line
                      (t (planemo--ind-prevline))))
                    (curr-middp  ;; current is e.g. "#set"
                     (cond
                      ;; ["if"] and "set" : nest current under parent
                      (prev-startp (planemo--ind-nestunder prevtag-align))
                      ;; ["end"] and "set" : unrelated clause, align to it
                      (prev-endp (planemo--ind-alignwith prevtag-align))
                      ;; * and "set" : align to previous line
                      (t (planemo--ind-prevline))))
                    ;; "#set"
                    (t (planemo--ind-prevline))))
             ;; current is a regular word following a previous tag
             ;; ["tag"] but the last line is not one: align to it.
             ((not prevtag-ldiff1-p) (planemo--ind-prevline))
             ;; ["end for"] followed immediately by "blah" : align to it
             (prev-endp (planemo--ind-alignwith prevtag-align))
             ;; ["if" or "else"] followed immediately by "blah" : nest or 0
             ((or prev-startp prev-middp)
              (planemo--ind-nestunder prevtag-align t))
             ;; no previous tag : align to previous line
             (t (planemo--ind-prevline)))))
         ;; previous line is a valid XML line : toggle root alignment
         (prevline-isxml (planemo--toggle-root-alignment))
         (t (planemo--ind-prevline)))))))

(defun planemo--within-validxml ()
  "Determine if current line is a root alignment line."
  (--> (planemo--get-parentxml)
       (if (member (car it) planemo-xml-scope) it)))

(defun planemo--get-parentxml ()
  "Retrieve the parent XML and the line difference between it and
the current line."
  (save-excursion
    (let* ((nowpos (point))
           (xmlpos (prog2 (nxml-backward-up-element) (point)))
           (lndiff (planemo--numlines nowpos xmlpos))
           (xmltag (buffer-substring-no-properties
                    (1+ xmlpos) (prog2 (forward-word 1) (point)))))
      (cons xmltag lndiff))))

(defun planemo--toggle-root-alignment ()
  "Toggle the first line after an XML tag, and set the
``planemo--root-alignment''."
  (let* ((prev-align (save-excursion (forward-line -1) (current-indentation)))
         (next-align (if (eq 0 planemo--root-alignment) prev-align 0)))
    (setq planemo--root-alignment next-align)
    (message "Root align set to %d" next-align)
    (if planemo-root-align-region
        (let ((bor (line-beginning-position))
              (eor (save-excursion (re-search-forward (rx (or "]]>" "</")))
                                   (line-beginning-position))))
          (indent-rigidly bor eor
                          (- planemo--root-alignment (current-indentation))))
      (indent-line-to next-align))))

(provide 'planemo-mode)
;;; planemo-mode.el ends here
