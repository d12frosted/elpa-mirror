;;; syntactic-close.el --- Insert closing delimiter -*- lexical-binding: t; -*-

;; Author: Emacs User Group Berlin <emacs-berlin@emacs-berlin.org>
;; Maintainer: Emacs User Group Berlin <emacs-berlin@emacs-berlin.org>

;; Version: 0.1
;; Package-Version: 20230423.707
;; Package-Commit: c184ff7a3cbcd28439aba7c3531ffebf0cd30b3a

;; URL: https://github.com/emacs-berlin/syntactic-close

;; Package-Requires: ((emacs "24") (cl-lib "0.5"))
;; Keywords: languages, convenience

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

;; M-x syntactic-close RET: close any syntactic element.

;; ['a','b' ==> ['a','b']

;; A first draft was published at emacs-devel list:
;; http://lists.gnu.org/archive/html/emacs-devel/2013-09/msg00512.html

;;; Code:

(require 'cl-lib)
(require 'thingatpt)
(eval-when-compile
 (require 'nxml-mode)
 (require 'sgml-mode)
 (require 'comint))

(defvar  syntactic-close-install-directory default-directory
  "Detect current .cask stuff.")

(defvar syntactic-close-debug-p nil
  "Avoid error")
;; (setq syntactic-close-debug-p t)

(and syntactic-close-debug-p (message "syntactic-close.el: default-directory: %s" default-directory))

(defgroup syntactic-close nil
  "Insert closing delimiter whichever needed. "
  :group 'languages
  :tag "syntactic-close"
  :prefix "syntactic-close-")

(defvar syntactic-close-empty-line-p-chars "^[ \t\r]*$")
(defcustom syntactic-close-empty-line-p-chars "^[ \t\r]*$"
  "Syntactic-close-empty-line-p-chars."
  :type 'regexp
  :group 'sytactic-close)

(defvar syntactic-close-unary-delimiter-chars (list ?` ?\" ?' ?+ ?: ?$ ?#)
  "Permitted unary delimiters." )
(make-variable-buffer-local 'syntactic-close-unary-delimiter-chars)

(defcustom syntactic-close-empty-line-p-chars "^[ \t\r]*$"
  "Syntactic-close-empty-line-p-chars."
  :type 'regexp
  :group 'sytactic-close)

(defcustom syntactic-close-known-string-inpolation-opener  (list ?{ ?\( ?\[)
  "Syntactic-close-known-string-inpolation-opener."
  :type '(repeat character)
  :group 'sytactic-close)

(defcustom syntactic-close-paired-openers (list ?< ?\( ?\[ ?{ ?\〈 ?\⦑ ?\⦓ ?\【 ?\⦗ ?\⸤ ?\「 ?\《 ?\⦕ ?\⸨ ?\⧚ ?\｛ ?\（ ?\［ ?\｟ ?\｢ ?\❰ ?\❮ ?\“ ?\‘ ?\❲ ?\⟨ ?\⟪ ?\⟮ ?\⟦ ?\⟬ ?\❴ ?\❪ ?\❨ ?\❬ ?\᚛ ?\〈 ?\⧼ ?\⟅ ?\⸦ ?\﹛ ?\﹙ ?\﹝ ?\⁅ ?\⦏ ?\⦍ ?\⦋ ?\₍ ?\⁽ ?\༼ ?\༺ ?\⸢ ?\〔 ?\『 ?\⦃ ?\〖 ?\⦅ ?\〚 ?\〘 ?\⧘ ?\⦉ ?\⦇)
  "Specify the delimiter char."
  :type '(repeat character)
  :group 'sytactic-close)

;; (setq syntactic-close-paired-openers

;;    (list ?‘ ?< ?\( ?\[ ?{ ?\〈 ?\⦑ ?\⦓ ?\【 ?\⦗ ?\⸤ ?\「 ?\《 ?\⦕ ?\⸨ ?\⧚ ?\｛ ?\（ ?\［ ?\｟ ?\｢ ?\❰ ?\❮ ?\“ ?\‘ ?\❲ ?\⟨ ?\⟪ ?\⟮ ?\⟦ ?\⟬ ?\❴ ?\❪ ?\❨ ?\❬ ?\᚛ ?\〈 ?\⧼ ?\⟅ ?\⸦ ?\﹛ ?\﹙ ?\﹝ ?\⁅ ?\⦏ ?\⦍ ?\⦋ ?\₍ ?\⁽ ?\༼ ?\༺ ?\⸢ ?\〔 ?\『 ?\⦃ ?\〖 ?\⦅ ?\〚 ?\〘 ?\⧘ ?\⦉ ?\⦇))

(defcustom syntactic-close-paired-closers (list ?’ ?> ?\) ?\] ?} ?\〉 ?\⦒ ?\⦔ ?\】 ?\⦘ ?\⸥ ?\」 ?\》 ?\⦖ ?\⸩ ?\⧛ ?\｝ ?\） ?\］ ?\｠ ?\｣ ?\❱ ?\❯ ?\” ?\’ ?\❳ ?\⟩ ?\⟫ ?\⟯ ?\⟧ ?\⟭ ?\❵ ?\❫ ?\❩ ?\❭ ?\᚜ ?\〉 ?\⧽ ?\⟆ ?\⸧ ?\﹜ ?\﹚ ?\﹞ ?\⁆ ?\⦎ ?\⦐ ?\⦌ ?\₎ ?\⁾ ?\༽ ?\༻ ?\⸣ ?\〕 ?\』 ?\⦄ ?\〗 ?\⦆ ?\〛 ?\〙 ?\⧙ ?\⦊ ?\⦈)
  "Specify the delimiter char."
  :type '(repeat character)
  :group 'sytactic-close)

;; (setq syntactic-close-paired-closers
;;       (list ?’ ?> ?\) ?\] ?} ?\〉 ?\⦒ ?\⦔ ?\】 ?\⦘ ?\⸥ ?\」 ?\》 ?\⦖ ?\⸩ ?\⧛ ?\｝ ?\） ?\］ ?\｠ ?\｣ ?\❱ ?\❯ ?\” ?\’ ?\❳ ?\⟩ ?\⟫ ?\⟯ ?\⟧ ?\⟭ ?\❵ ?\❫ ?\❩ ?\❭ ?\᚜ ?\〉 ?\⧽ ?\⟆ ?\⸧ ?\﹜ ?\﹚ ?\﹞ ?\⁆ ?\⦎ ?\⦐ ?\⦌ ?\₎ ?\⁾ ?\༽ ?\༻ ?\⸣ ?\〕 ?\』 ?\⦄ ?\〗 ?\⦆ ?\〛 ?\〙 ?\⧙ ?\⦊ ?\⦈))

(defcustom syntactic-close--escape-char 92
  "Customize the escape char if needed."
  :type 'char
  :group 'sytactic-close)

(defun syntactic-close--escaped-p (&optional pos)
  "Return t if char at POS is preceded by an odd number of backslashes. "
  (save-excursion
    (when pos (goto-char pos))
    (< 0 (% (abs (skip-chars-backward "\\\\")) 2))))

(defun syntactic-close--escapes-maybe (limit)
  "Handle escaped parens.

Consider strings like
Argument LIMIT lower border."
  (save-excursion
    (when (eq (char-before) syntactic-close--escape-char)
      (buffer-substring-no-properties (point) (progn (skip-chars-backward (char-to-string syntactic-close--escape-char) limit)(1- (point)))))))

(defun syntactic-close--padding-maybe (&optional pos)
  "Report padding to handle.

Optional argument POS position to start from."
  (save-excursion
    (when pos (goto-char pos))
    (when (member (char-after) (list 32 9))
      (buffer-substring-no-properties (point) (progn (skip-chars-forward " \t")(point))))))

(defun syntactic-close--multichar-intern (char limit)
    (abs (skip-chars-backward (char-to-string char) limit)))

(defun syntactic-close--multichar-closer (char limit &optional offset)
  "Opener and closer might be composed by more than one character.

construct and return the closing string
Argument CHAR the character to contruct the string.
Argument LIMIT the lower border.
Optional argument OFFSET already know offset."
  (if offset
      (make-string (+ offset (syntactic-close--multichar-intern char limit)) (syntactic-close--return-complement-char-maybe char))
    (make-string (syntactic-close--multichar-intern char limit) (syntactic-close--return-complement-char-maybe char))))

(defun syntactic-close-pure-syntax-intern (pps)
  "Fetch from start of list to close.

Argument PPS is result of ‘parse-partial-sexp’"
  (save-excursion
    (let (closer padding)
      (cond
       ((and (nth 3 pps) (nth 1 pps) (< (nth 1 pps) (nth 8 pps)))
	(goto-char (nth 8 pps))
	(when syntactic-close-honor-padding-p (setq padding (syntactic-close--padding-maybe (1+ (point)))))
	(setq closer (char-to-string (syntactic-close--return-complement-char-maybe (char-after))))
	(when syntactic-close-honor-padding-p (setq padding (syntactic-close--padding-maybe (1+ (point))))))
       ((nth 3 pps)
	(goto-char (nth 8 pps))
	(backward-prefix-chars)
	(setq closer (buffer-substring-no-properties (point) (progn (skip-chars-forward (char-to-string (nth 3 pps)))(point))))
	(when syntactic-close-honor-padding-p (setq padding (syntactic-close--padding-maybe (1+ (point))))))
       ((nth 1 pps)
	(goto-char (nth 1 pps))
	(setq closer (char-to-string (syntactic-close--return-complement-char-maybe (char-after))))
	(when syntactic-close-honor-padding-p (setq padding (syntactic-close--padding-maybe (1+ (point)))))))
      (concat padding closer))))

(defun syntactic-close-pure-syntax (pps)
  "Insert closer found from beginning of list.

Argument PPS is result of a call to function ‘parse-partial-sexp’"
  (syntactic-close-pure-syntax-intern pps))

(defun syntactic-close-travel-comment-maybe (pps limit)
  "Leave commented section backward.

Argument PPS is result of a call to function ‘parse-partial-sexp’.
Argument LIMIT the lower bound."
  (let ((pps pps))
    (while (nth 4 pps)
      (goto-char (nth 8 pps))
      (skip-chars-backward " \t\r\n\f")
      (setq pps (parse-partial-sexp limit (point))))
    pps))

(defun syntactic-close-empty-line-p (&optional iact)
  "Return t if cursor is at an empty line, nil otherwise.
Optional argument IACT signaling interactive use."
  (interactive "p")
  (save-excursion
    (beginning-of-line)
    (when iact
      (message "%s" (looking-at syntactic-close-empty-line-p-chars)))
    (looking-at syntactic-close-empty-line-p-chars)))

(unless (functionp 'empty-line-p)
  (defalias 'empty-line-p 'syntactic-close-empty-line-p))

;; (defvar haskell-interactive-mode-prompt-start (ignore-errors (require 'haskell-interactive-mode) haskell-interactive-mode-prompt-start)
;;   "Defined in haskell-interactive-mode.el, silence warnings.")

 (defvar syntactic-close-tag nil
  "Functions closing mode-specific might go here.")

(defcustom syntactic-close-electric-delete-whitespace-p nil
  "When t delete whitespace before point when closing.

Default is nil"

  :type 'boolean
  :group 'syntactic-close)

(defcustom syntactic-close-honor-padding-p t
  "Insert whitespace following opener before closer.

Default is t"
  :type 'boolean
  :tag "syntactic-close-honor-padding-p"
  :group 'syntactic-close)
(make-variable-buffer-local 'syntactic-close-honor-padding-p)

(defcustom syntactic-close--semicolon-separator-modes
  (list
   'inferior-sml-mode
   'js-mode
   'js2-mode
   'perl-mode
   'php-mode
   'sml-mode
   'web-mode
   )
  "List of modes which commands must be closed by a separator,
but have no specific treatment at the moment."

  :type 'list
  :tag "syntactic-close--semicolon-separator-modes"
  :group 'syntactic-close)

(defcustom syntactic-close--ml-modes
  (list
   'html-mode
   'mhtml-mode
   'sgml-mode
   'xml-mode
   'xxml-mode
   )
  "List of modes using markup language."
  :type 'list
  :tag "syntactic-close--ml-modes"
  :group 'syntactic-close)

(defvar syntactic-close-modes (list
			       'agda2-mode
			       'emacs-lisp-mode
			       'html-mode
			       'java-mode
			       'js-mode
			       'mhtml-mode
			       'nxml-mode
			       'org-mode
			       'php-mode
			       'python-mode
			       'ruby-mode
                               'scala-mode
                               'shell-mode
			       'sgml-mode
			       'web-mode
			       'xml-mode
			       'xxml-mode)
  "Programming modes dealt with explicitly in some way.")

(defvar syntactic-close-indent-modes (list
				      'ruby-mode)
  "Mode where ‘indent-according-to-mode’ shall be after closer is inserted. ")

(defvar syntactic-close-emacs-lisp-block-re
  (concat
   "[ \t]*\\_<"
   "(if\\|(cond\\|when\\|unless"
   "\\_>[ \t]*"))

(defvar syntactic-close-import-re "^[ \t]*import[ \t]+.+"
  "")

(defvar syntactic-close-for-re "^[ \t]*for([^)]+"
  "")

(defvar syntactic-close-verbose-p nil)

(defvar syntactic-close-assignment-re   "^[^:]*[^ =\t:]+[ \t]+=[ \t]+[^=]+" "")

(setq syntactic-close-assignment-re     "^[^:]*[^ =\t:]+[ \t]+=[ \t]+[^=]+")

(defvar syntactic-close-funcdef-re   "^[ \t]*def[ \t]+[[:alnum:]_]+([^()]+)" "")

(setq syntactic-close-funcdef-re     "^[ \t]*def[ \t]+[[:alnum:]_]+([^()]+)")

(unless (boundp 'py-block-re)
  (defvar py-block-re "[ \t]*\\_<\\(class\\|def\\|async def\\|async for\\|for\\|if\\|try\\|while\\|with\\|async with\\)\\_>[:( \n\t]*"
  "Matches the beginning of a compound statement. "))

(defvar syntactic-close-known-comint-modes (list 'shell-mode 'inferior-sml-mode 'inferior-asml-mode 'Comint-SML 'haskell-interactive-mode 'inferior-haskell-mode)
  "`parse-partial-sexp' must scan only from last prompt.")
(setq syntactic-close-known-comint-modes (list 'shell-mode 'inferior-sml-mode 'inferior-asml-mode 'Comint-SML 'haskell-interactive-mode 'inferior-haskell-mode))

(defun syntactic-close-toggle-verbosity ()
  "If `syntactic-close-verbose-p' is nil, switch it on.

Otherwise switch it off."
  (interactive)
  (setq syntactic-close-verbose-p (not syntactic-close-verbose-p))
  (when (called-interactively-p 'any) (message "syntactic-close-verbose-p: %s" syntactic-close-verbose-p)))

(defun syntactic-close--return-complement-char-maybe (erg)
  "For example return \"}\" for \"{\" but keep \"\\\"\".
Argument ERG character to complement."
  (pcase erg
    (?` ?')
    (?< ?>)
    (?> ?<)
    (?\( ?\))
    (?\) ?\()
    (?\] ?\[)
    (?\[ ?\])
    (?} ?{)
    (?{ ?})
    (?\〈 ?\〉)
    (?\⦑ ?\⦒)
    (?\⦓ ?\⦔)
    (?\【 ?\】)
    (?\⦗ ?\⦘)
    (?\⸤ ?\⸥)
    (?\「 ?\」)
    (?\《 ?\》)
    (?\⦕ ?\⦖)
    (?\⸨ ?\⸩)
    (?\⧚ ?\⧛)
    (?\｛ ?\｝)
    (?\（ ?\）)
    (?\［ ?\］)
    (?\｟ ?\｠)
    (?\｢ ?\｣)
    (?\❰ ?\❱)
    (?\❮ ?\❯)
    (?\“ ?\”)
    (?\‘ ?\’)
    (?\❲ ?\❳)
    (?\⟨ ?\⟩)
    (?\⟪ ?\⟫)
    (?\⟮ ?\⟯)
    (?\⟦ ?\⟧)
    (?\⟬ ?\⟭)
    (?\❴ ?\❵)
    (?\❪ ?\❫)
    (?\❨ ?\❩)
    (?\❬ ?\❭)
    (?\᚛ ?\᚜)
    (?\〈 ?\〉)
    (?\⧼ ?\⧽)
    (?\⟅ ?\⟆)
    (?\⸦ ?\⸧)
    (?\﹛ ?\﹜)
    (?\﹙ ?\﹚)
    (?\﹝ ?\﹞)
    (?\⁅ ?\⁆)
    (?\⦏ ?\⦎)
    (?\⦍ ?\⦐)
    (?\⦋ ?\⦌)
    (?\₍ ?\₎)
    (?\⁽ ?\⁾)
    (?\༼ ?\༽)
    (?\༺ ?\༻)
    (?\⸢ ?\⸣)
    (?\〔 ?\〕)
    (?\『 ?\』)
    (?\⦃ ?\⦄)
    (?\〖 ?\〗)
    (?\⦅ ?\⦆)
    (?\〚 ?\〛)
    (?\〘 ?\〙)
    (?\⧘ ?\⧙)
    (?\⦉ ?\⦊)
    (?\⦇ ?\⦈)
    (_ erg)))

(defun syntactic-close--string-delim-intern (pps)
  "Return the delimiting string.

Argument PPS delivering result of ‘parse-partial-sexp’."
  (goto-char (nth 8 pps))
  (buffer-substring-no-properties (point) (progn  (skip-chars-forward (char-to-string (char-after))) (point))))

(defun syntactic-close-in-string-maybe (&optional pps)
  "If inside a double- triple- or singlequoted string.

Return delimiting chars
Optional argument PPS should deliver the result of ‘parse-partial-sexp’."
  (interactive)
  (save-excursion
    (let* ((pps (or pps (parse-partial-sexp (point-min) (point))))
	   (erg (when (nth 3 pps)
		  (syntactic-close--string-delim-intern pps))))
      (unless erg
	(when (looking-at "\"")
	  (forward-char 1)
	  (setq pps (parse-partial-sexp (line-beginning-position) (point)))
	  (when (nth 3 pps)
	    (setq erg (syntactic-close--string-delim-intern pps)))))
      (when (and syntactic-close-verbose-p (called-interactively-p 'any)) (message "%s" erg))
      erg)))

(defun syntactic-close-fix-whitespace-maybe (orig)
  "Remove whitespace before point if called.

Argument ORIG start position.
Optional argument PADDING ."
  (save-excursion
    (goto-char orig)
    (when (and (not (looking-back "^[ \t]+" nil))
	       (< 0 (abs (skip-chars-backward " \t"))))
      (delete-region (point) orig))))

(defun syntactic-close-insert-with-padding-maybe (strg &optional nbefore nafter)
  "Takes a string. Insert a space before and after maybe.
Argument STRG the string to be padded maybe.
Optional argument NBEFORE read not-before string.
Optional argument NAFTER read not after string."
  (let (erg)
  (skip-chars-backward " \t\r\n\f")
      (cond ((looking-back "([ \t]*" (line-beginning-position))
	     (delete-region (match-beginning 0) (match-end 0))
	     (setq erg (concat strg " ")))
	    ((looking-at "[ \t]*)")
	     (delete-region (match-beginning 0) (1- (match-end 0)))
	     (setq erg (concat " " strg)))
	    (t (unless nbefore (setq erg " "))
	       (setq erg (concat erg strg))
	       (unless
		   (or
		    (eq 5 (car (syntax-after (point))))
		    ;; (eq (char-after) ?\))
		    nafter) (setq erg (concat erg " ")))))
	    erg))

(defun syntactic-close--comments-intern (orig start end)
  "Close comments.

ORIG the position where ‘syntactic-close’ was called
START the comment start
END the comment end"
  (if (looking-at start)
      (progn (goto-char orig)
	     (fixup-whitespace)
	     (syntactic-close-insert-with-padding-maybe end nil t))
    (goto-char orig)
    (newline-and-indent)))

(defun syntactic-close--insert-comment-end-maybe (pps)
  "Insert comment end.

Argument PPS should provide result of ‘parse-partial-sexp’."
  (let ((orig (point)))
    (cond
     ((eq major-mode 'haskell-mode)
      (goto-char (nth 8 pps))
      (if (looking-at "{-# ")
	  (syntactic-close--comments-intern orig "{-#" "#-}")
	(syntactic-close--comments-intern orig "{-" "-}"))
      t)
     ((or (eq major-mode 'c++-mode) (eq major-mode 'c-mode))
      (goto-char (nth 8 pps))
      (syntactic-close--comments-intern orig "/*" "*/")
      t)
     (t (if (string= "" comment-end)
	    (if (eq system-type 'windows-nt)
		 "\r\n"
	      "\n")
	  comment-end)
	comment-end))
    ))

(defun syntactic-close--point-min ()
  "Determine the lower position in buffer to narrow."
  (cond ((and (member major-mode (list 'haskell-interactive-mode 'inferior-haskell-mode)))
	 (ignore-errors haskell-interactive-mode-prompt-start))
	((save-excursion
	   (and (member major-mode syntactic-close-known-comint-modes) comint-prompt-regexp
		(message "%s" (current-buffer))
		(re-search-backward comint-prompt-regexp nil t 1)
		(looking-at comint-prompt-regexp)
		(message "%s" (match-end 0))))
	 (match-end 0))
	(t (point-min))))

(defun syntactic-close-fetch-delimiter (pps)
  "In some cases in (nth 3 PPS only return t."
  (save-excursion
    (goto-char (nth 8 pps))
    (char-after)))

(defun syntactic-close-ml ()
  "Close in Standard ML."
  (interactive "*")
  (cond ((derived-mode-p 'sgml-mode)
	 (setq syntactic-close-tag 'sgml-close-tag)
	 (funcall syntactic-close-tag)
	 (font-lock-fontify-region (point-min)(point-max))
	 t)))

(defun syntactic-close--generic (&optional orig stack pps skip_list)
  "Detect delimiters inside string or comment maybe.

Optional argument UNARY-DELIMITER-CHARS like quoting chara1cter,
a list.
Optional argument DELIMITERS-STRG composed of unary and paired delimiters,
a list.
Optional argument ORIG position.
Optional argument STACK used by recursive call maybe.
Optional argument LIMIT bound."
  (let* ((orig (or orig (point)))
	 (limit (or (ignore-errors (nth 8 pps)) (point-min)))
	 (unary-delimiter-chars syntactic-close-unary-delimiter-chars)
	 (paired-delimiters-strg (concat (cl-map 'string 'identity syntactic-close-paired-openers) (cl-map 'string 'identity syntactic-close-paired-closers)))
	 (stack stack)
	 closer done escapes padding erg)
    (save-restriction
      (narrow-to-region limit orig)
      (while (and (not (bobp)) (not closer)(not done) (<= limit (1- (point))))
	(cond
	 ((and skip_list (nth 1 (parse-partial-sexp (point-min) (point))))
	  (goto-char (nth 1 (parse-partial-sexp (point-min) (point)))))
	 ((member (char-before)
		  ;; (list ?\) ?\] ?})
		  syntactic-close-paired-closers)
	  (push (char-before) stack)
	  (unless (bobp) (forward-char -1)))
	 (;; (list ?\( ?\" ?{ ?\[)
	  (member (char-before)
		  syntactic-close-paired-openers)
	  (if (eq (car stack) (syntactic-close--return-complement-char-maybe (char-before)))
	      (progn
		(pop stack)
		(unless (bobp)
		  (forward-char -1)))
	    (setq done t)
	    (when syntactic-close-honor-padding-p (save-excursion (setq padding (syntactic-close--padding-maybe))))
	    ;; maybe more then one char
	    (setq closer (syntactic-close--multichar-closer (char-before) limit))
	    (unless (bobp)
	      (setq escapes (syntactic-close--escapes-maybe limit)))))
	 ((and (member (char-before)
		       ;; (list ?` ?\" ?')
		       unary-delimiter-chars)
	       ;; syntactic-close--tqs-test-hglm99.el
	       ;; (search-forward "'''
	       (eq 3 (- limit (- limit (count-matches (char-to-string (char-before)) limit
						      ;; (point)
						      orig)))))
	  (if (nth 3 pps)
	      (progn
		(goto-char (nth 8 pps))

		(setq closer (buffer-substring-no-properties (point) (progn (skip-chars-forward (char-to-string (char-after))) (point)))))
	    (setq closer (make-string 3 (char-before)))
	    ))
	 ((and (member (char-before)
		       ;; (list ?` ?\" ?')
		       unary-delimiter-chars)
	       ;; $asdf$
	       (eq 0 (mod (count-matches (char-to-string (char-before)) limit orig) 2)))
	  (setq erg (char-to-string (char-before)))
	  (while (search-backward erg limit t)))
	  ;; (setq closer (buffer-substring (save-excursion (skip-chars-backward (char-to-string (char-before)))(point)) (point)))
	  ;; (when syntactic-close-honor-padding-p (save-excursion (setq padding (syntactic-close--padding-maybe))))
	  ;; (setq escapes (syntactic-close--escapes-maybe limit)))
	 ((and (member (char-before)
		       ;; (list ?` ?\" ?')
		       unary-delimiter-chars)
	       ;; $asdf$
	       (not (eq 0 (mod (count-matches (char-to-string (char-before)) limit orig) 2))))
	  (setq closer (buffer-substring (save-excursion (skip-chars-backward (char-to-string (char-before)))(point)) (point)))
	  (when syntactic-close-honor-padding-p (save-excursion (setq padding (syntactic-close--padding-maybe))))
	  (setq escapes (syntactic-close--escapes-maybe limit)))
	 ((or (< 0 (abs (skip-chars-backward (concat "^" (cl-map 'string 'identity unary-delimiter-chars) paired-delimiters-strg) limit)))
	      (setq done t)))
	 ((and (member (char-before)
		       ;; (list ?` ?\" ?')
		       unary-delimiter-chars)
	       ;; $asdf$
	       ;; (eq 0 (mod (count-matches (char-to-string (char-before)) limit
	       ;; 				 ;; (point)
	       ;; 				 orig) 2))
	       )
	  ;; (setq erg (char-before))
	  ;; syntactic-close--multibrace-unary-fundamental-test-WlZ71s
	  ;; {{{[[[[+++asdf+++
	  (setq closer (buffer-substring-no-properties (point) (progn
								 (skip-chars-backward (concat "^" (cl-map 'string 'identity (remove (char-before) unary-delimiter-chars)) paired-delimiters-strg) limit) (point)))))

	 ))
      (cond (closer
	     (when (characterp closer) (setq closer (char-to-string closer)))
	     (setq closer (concat padding escapes closer))))
      (goto-char orig)
      closer)))

(defun syntactic-close-python-listclose (orig closer force pps)
  "If inside list, assume another item first.

Argument ORIG the start position.
Argument CLOSER the char which closes the list.
Argument FORCE to be done.
Argument PPS should provide result of ‘parse-partial-sexp’."
  (cond ((member (char-before) (list ?' ?\"))
	 (if force
	     (progn
	       (insert closer)
	       ;; only closing `"' or `'' was inserted here
	       (when (setq closer (syntactic-close--generic orig nil pps))
		 (insert closer))
	       t)
	   (if (nth 3 pps)
	       (insert (char-before))
	     (insert ","))
	   t))
	(t (syntactic-close-fix-whitespace-maybe orig)
	   (insert closer)
	   t)))

;; Emacs-lisp
(defun syntactic-close--org-mode-close ()
  "Org mode specific closes."
  (unless (empty-line-p)
    (end-of-line)
    (newline))
  ;; +BEGIN_QUOTE
  (when (save-excursion (and (re-search-backward "^#\\+\\([A-Z]+\\)_\\([A-Z]+\\)" nil t 1)(string= "BEGIN" (match-string-no-properties 1))))
    (insert (concat "#+END_" (match-string-no-properties 2)))))

(defun syntactic-close-emacs-lisp-close (pps &optional org)
  "Close in Emacs Lisp.

Argument CLOSER the char to close.
Argument PPS should provide result of ‘parse-partial-sexp’.
Optional argument ORG read ‘org-mode’."
  (let ((syntactic-close-unary-delimiter-chars (list ?` ?\" ?+)))
    ;; (unary-delimiters-strg (cl-map 'string 'identity unary-delimiter-chars))
    ;; (delimiters (concat syntactic-close-paired-openers-strg syntactic-close-paired-closers-strg unary-delimiters-strg))
    (cond
     (org (syntactic-close--org-mode-close))
     ((and (not (nth 8 pps))(nth 1 pps))
      (syntactic-close-pure-syntax pps))
     ((syntactic-close--generic nil nil pps)))))

(defun syntactic-close--paren-conditions (bracecounter bracketcounter parencounter)
  (cond
   ((eq (char-before) ?{)
    (setq bracecounter (1+ bracecounter)))
   ((eq (char-before) ?\[)
    (setq bracketcounter (1+ bracketcounter)))
   ((eq (char-before) 40)
    (setq parencounter (1+ parencounter)))
   ((eq (char-before) ?})
    (setq bracecounter (1- bracecounter)))
   ((eq (char-before) ?\])
    (setq bracketcounter (1- bracketcounter)))
   ((eq (char-before) 41)
    (setq parencounter (1- parencounter)))))

(defun syntactic-close--paren-inside-string (pos)
  "Return the brace(s) if existing inside a string at point."
  (let (
        (bracecounter 0)
        (bracketcounter 0)
        (parencounter 0))
    (while (and (or
                 (prog1
                     (and
                      (syntactic-close--paren-conditions bracecounter bracecounter parencounter)
                      (forward-char -1)))
                 (< 0 (abs (skip-chars-backward "^{}()[]'\"" (1+ pos))))))
      (syntactic-close--paren-conditions bracecounter bracecounter parencounter)
       (unless (or (< bracecounter 0) (< bracketcounter 0) (< parencounter 0))
         (forward-char -1)))
    (cond
     ((< 0 bracecounter)
      "}")
     ((< 0 bracketcounter)
      "]")
     ((< 0 parencounter)
      ")"))))

(defun syntactic-close--check-bracecounter (bracecounter doublequotecounter singlequotecounter)
  (when (and (< 0 bracecounter) (eq (char-after) ?{))
    (cond
     ((and (< 0 (% doublequotecounter 2)))
      "\"")
     ((< 0 (% singlequotecounter 2))
      "'")
     (t
      (char-to-string (syntactic-close--return-complement-char-maybe (char-after)))))))

(defun syntactic-close--check-bracketcounter (bracketcounter doublequotecounter singlequotecounter)
  (when (and (< 0 bracketcounter) (eq (char-after) ?\[))
    (cond
     ((and (< 0 (% doublequotecounter 2)))
      "\"")
     ((< 0 (% singlequotecounter 2))
      "'")
     (t
      (char-to-string (syntactic-close--return-complement-char-maybe (char-after)))))))

(defun syntactic-close--check-parencounter (parencounter doublequotecounter singlequotecounter)
  (when (and (< 0 parencounter) (eq (char-after) ?\())
    (cond
     ((and (< 0 (% doublequotecounter 2)))
      "\"")
     ((< 0 (% singlequotecounter 2))
      "'")
     (t
      (char-to-string (syntactic-close--return-complement-char-maybe (char-after)))))))

(defun syntactic-close--check-doublequotecounter (doublequotecounter bracecounter)
  (cond ((and (< 0 (% doublequotecounter 2)) (eq (char-after) ?\"))
         (if (<  bracecounter 0)
             "}"
           (char-to-string (syntactic-close--return-complement-char-maybe (char-after)))))))

(defun syntactic-close--check-singlequotecounter (singlequotecounter bracecounter)
  (cond ((and (< 0 (% singlequotecounter 2)) (eq (char-after) ?'))
         (if (<  bracecounter 0)
             "}"
           (char-to-string (syntactic-close--return-complement-char-maybe (char-after)))))))

(defun syntactic-close--discard-closed-braced ()
  (interactive)
  (save-excursion
    (let ((bracecounter 0))
      (while
          (and
           (not (< 0 bracecounter))
           (re-search-backward "[{}]" (line-beginning-position) t))
        (unless (syntactic-close--escaped-p)
          (cond
           ((eq (char-after) ?{)
            (setq bracecounter (1+ bracecounter)))
           ((eq (char-after) ?})
            (setq bracecounter (1- bracecounter)))
           ))
        (and (eq 0 bracecounter) (kill-sexp))))))

;; ((pps (parse-partial-sexp (point-min) (point))))
;; f\"{f\"{f\"{f\"{f\"{f\"{1+1
;; (nth 1 pps) tells all, (nth 8 pps) is zero
;; f\"{f\"{f\"{f\"{f\"{f\"{1+1}
;; (nth 1 pps) and (nth 8 pps) is zero, but ‘\\"’ required
;; f\"{f\"{f\"{f\"{f\"{f\"{f\"{1+1
;; (nth 1 pps) zero, < (nth 8 pps) {
;; f'Useless use of lambdas: { (lambda x: x*2
;; (nth 1 pps) zero, < (nth 8 pps) (, < (nth 8 pps) {
(defun syntactic-close--python-f-string (strg &optional bracecounter bracketcounter parencounter doublequotecounter singlequotecounter erg)
  (with-temp-buffer
    (switch-to-buffer (current-buffer))
    (insert strg)
    (let ((bracecounter (or bracecounter 0))
          (bracketcounter (or bracketcounter 0))
          (parencounter (or parencounter 0))
          (doublequotecounter (or doublequotecounter 0))
          (singlequotecounter (or singlequotecounter 0))
          (erg (or erg nil))
          padding)
      (syntactic-close--discard-closed-braced)
      (while (syntactic-close--escaped-p)
        (forward-char -1))
      (when
          (or
           (prog1 (< 0 (abs (skip-chars-backward "^[](){}\"'")))
             ;; (re-search-backward "[\\\\[(){\"'}\]]" nil t 3)

             (while (syntactic-close--escaped-p)
               (forward-char -1)))
           (prog1 (member (char-before) (list 40 41 91 93 ?{ ?} ?\" ?'))
             (while (syntactic-close--escaped-p)
               (forward-char -1))))
        (cond
         ((eq (char-before) ?{)
          (setq bracecounter (1+ bracecounter))
          (forward-char -1))
         ((eq (char-before) ?\[)
          (setq bracketcounter (1+ bracketcounter))
          (forward-char -1))
         ((eq (char-before) 40)
          (setq parencounter (1+ parencounter))
          (forward-char -1))
         ((eq (char-before) ?})
          (setq bracecounter (1- bracecounter))
          (forward-char -1))
         ((eq (char-before) ?\])
          (setq bracketcounter (1- bracketcounter))
          (forward-char -1))
         ((eq (char-before) 41)
          (setq parencounter (1- parencounter))
          (forward-char -1))
         ((eq (char-before) ?\")
          (setq doublequotecounter (1+ doublequotecounter))
          (forward-char -1))
         ((eq (char-before) ?')
          (setq singlequotecounter (1+ singlequotecounter))
          (forward-char -1)))
        (when (or (and (member (char-after) (list 40 91 ?{))
                       (not (syntactic-close--escaped-p)))
                  (bobp))
          (when (looking-at ".\\([ \t]+\\)")
            (setq padding (match-string-no-properties 1)))
          (setq erg (or (syntactic-close--check-bracecounter bracecounter doublequotecounter singlequotecounter)
                        (syntactic-close--check-bracketcounter bracketcounter doublequotecounter singlequotecounter)
                        (syntactic-close--check-parencounter parencounter doublequotecounter singlequotecounter)
                        (syntactic-close--check-doublequotecounter doublequotecounter bracecounter)
                        (syntactic-close--check-singlequotecounter singlequotecounter bracecounter)
                        (cond
                         ((and (looking-back "[fF]r?" (line-beginning-position)) (eq (char-after) ?\")(< 0 (% doublequotecounter 2)))
                          (char-to-string (syntactic-close--return-complement-char-maybe (char-after))))
                         ((and (looking-back "[fF]r?" (line-beginning-position)) (eq (char-after) ?')(< 0 (% singlequotecounter 2)))
                          (char-to-string (syntactic-close--return-complement-char-maybe (char-after))))))))
        (if erg
            (if padding
                (setq erg (concat padding erg))
              erg)
          (syntactic-close--python-f-string (buffer-substring-no-properties (line-beginning-position) (point)) bracecounter bracketcounter parencounter doublequotecounter singlequotecounter erg))))))

(defun syntactic-close-python-close (pps)
  "Might deliver equivalent to `py-dedent'.

Argument B-OF-ST read beginning-of-statement.
Argument B-OF-BL read beginning-of-block.
Optional argument PADDING to be done.
Optional argument PPS is result of a call to function ‘parse-partial-sexp’"
  (let* ((orig (point))
         (f-pos (progn (while (re-search-backward "\\(.*\\)[fF]r?\\(['\"]\\{1,3\\}\\).*" (line-beginning-position) t)) (match-beginning 2))))
    (cond
     (f-pos
      (syntactic-close--python-f-string (buffer-substring-no-properties f-pos orig)))
     ((and (nth 8 pps) (nth 3 pps))
      (or (save-excursion (syntactic-close--paren-inside-string (nth 8 pps)))
	  ;; (syntactic-close-generic-forms pps)
	  (save-excursion (goto-char (nth 8 pps)) (looking-at "[\"']\\{1,3\\}") (match-string-no-properties 0))))
     ((nth 1 pps)
      (syntactic-close-pure-syntax pps))
     ;; ((looking-back "^[ 	]+if[ 	]+.*" (line-beginning-position))
     ;; py-block-or-clause-re
     ((looking-back "[ 	]*\\_<\\(async \\(?:class\\|def\\|for\\|with\\)\\|c\\(?:ase\\|lass\\)\\|def\\|e\\(?:l\\(?:if\\|se\\)\\|xcept\\)\\|f\\(?:inally\\|or\\)\\|if\\|match\\|try\\|w\\(?:hile\\|ith\\)\\)\\_>[( 	]*.*" (line-beginning-position))
      ":")
     (t (syntactic-close--generic (point) nil
				  (if (functionp 'py--beginning-of-statement-position)
				      (py--beginning-of-statement-position)
				    (save-excursion (python-nav-beginning-of-statement)))
				  t)))))

;; Haskell
(defun syntactic-close-haskell-close (&optional pps)
  "Optional argument PPS is result of a call to function ‘parse-partial-sexp’"
  (interactive "*")
  (let* ((pps (or pps (parse-partial-sexp (point-min) (point)))))
    (cond
     ((nth 8 pps)
      (syntactic-close-generic-forms pps))
     ((nth 1 pps)
      (syntactic-close-pure-syntax pps))
     (t (syntactic-close--generic nil nil pps)))))

;; Ruby
(defun syntactic-close--ruby ()
  (unless (or (looking-back ";[ \t]*" nil))
    (if (and (bolp) (eolp))
        "end"
      "\nend")))

(defun syntactic-close-ruby-close (pps)
  "Ruby specific close.

Argument PPS is result of a call to function ‘parse-partial-sexp’"
  (cond ((looking-back "#{[_[:alpha:]][_[:alnum:]]*" (line-beginning-position))
         "}")
        ((ignore-errors (and (< (nth 1 pps) (nth 8 pps))(syntactic-close--string-before-list-maybe pps))))
	((and (or (nth 1 pps) (nth 3 pps)) (syntactic-close-pure-syntax-intern pps)))
	(t (syntactic-close--ruby))))

(defun syntactic-close-java-another-filter-clause (pps)
  ""
  (let ((pps pps))
    (cond ((save-excursion
             ;; (goto-char (nth 1 pps))
             (while (nth 1 (setq pps (parse-partial-sexp (point-min) (point))))
               (goto-char (nth 1 pps)))
             (progn (ignore-errors (forward-sexp)) (and (not (nth 1 (parse-partial-sexp (point-min) (point))))(eq (char-after) ?{)))))
          ((looking-back syntactic-close-assignment-re (line-beginning-position))))))

(defun syntactic-close-java (&optional pps)
  "Optional argument PPS is result of a call to function ‘parse-partial-sexp’"
  (interactive "*")
  (let* ((orig (point))
         (pps (or pps (parse-partial-sexp (point-min) (point)))))
    (cond
     ((nth 8 pps)
      (syntactic-close-generic-forms pps))
     ((nth 1 pps)
      (cond ((and (looking-back syntactic-close-for-re (line-beginning-position)) (not (eq (char-before) ?\;)) (not (string-match "\\+\\+" (buffer-substring-no-properties (line-beginning-position) (point)))))
             "; ")
            (t (save-excursion (goto-char (nth 1 pps))
                               (if (eq (char-after) 40)
                                   ")"
                                 (goto-char orig)
                                 (cond ((looking-back "^[ \t]*" (line-beginning-position))
                                        "}")
                                       (t (unless (eq (char-before) ?\;) ";"))))))))
     ;; ((syntactic-close-java-another-filter-clause pps)
     ;;  (if (not (eq (char-before) ?\;))

     ;;      ";")
     ;;  (syntactic-close-pure-syntax pps))
     ;; (t (syntactic-close-pure-syntax pps)))))
     ((looking-back syntactic-close-assignment-re (line-beginning-position))
      (unless (eq (char-before) ?\;) ";"))
     ((and (looking-back syntactic-close-funcdef-re (line-beginning-position))
           (eq (char-before) 41))
      ":")
     ((looking-back "^[ \t]*" (line-beginning-position))
      "}")
     (t
      ";"
      ;; (syntactic-close--generic nil nil pps)
      ))))

(defun syntactic-close-scala-another-filter-clause (pps)
  "Semicolon only required with inside parentized

If you prefer, you can use curly braces instead of parentheses to
surround the generators and filters. One advantage to using curly
braces is that you can leave off some of the semicolons that are
needed when you use parentheses.

Source: Odersky, Spoon, Venners: Programming in Scala"
  (let ((indent (current-indentation))
        done)
    (cond ((looking-back "^[ \t]+if[ \t].*" (line-beginning-position))
           (unless (save-excursion (goto-char (nth 1 pps)) (eq (char-after) ?{))

             (back-to-indentation)
             (while (and (forward-line 1)
                         (progn (back-to-indentation) (eq (current-column) indent)))
               (when (looking-at "if[ \t]") (setq done t)))))
          ((looking-back syntactic-close-assignment-re (line-beginning-position))
           (setq done t)))
    done))

(defun syntactic-close-scala-close (&optional pps)
  "Optional argument PPS is result of a call to function ‘parse-partial-sexp’"
  (interactive "*")
  (let* ((pps (or pps (parse-partial-sexp (point-min) (point)))))
    (cond
     ((nth 8 pps)
      (syntactic-close-generic-forms pps))
     ((nth 1 pps)
      (if (save-excursion (syntactic-close-scala-another-filter-clause pps))
          (if (and (not (eq (char-before) ?\;))
                   (or
                    (eq (char-before) 41)
                    (looking-back syntactic-close-assignment-re (line-beginning-position))))
              ";"
            (syntactic-close-pure-syntax pps))
        (syntactic-close-pure-syntax pps)))
     ((looking-back syntactic-close-assignment-re (line-beginning-position))
      (unless (eq (char-before) ?\;) ";"))
     ((and (looking-back syntactic-close-funcdef-re (line-beginning-position))
           (eq (char-before) 41))
      ":")

     (t (syntactic-close--generic nil nil pps)))))

(defun syntactic-close-shell-close (&optional pps)
  "Optional argument PPS is result of a call to function ‘parse-partial-sexp’"
  (interactive "*")
  (let* ((pps (or pps (parse-partial-sexp (point-min) (point)))))
    (cond
     ((nth 8 pps)
      (syntactic-close-generic-forms pps))
     ((nth 1 pps)
      (syntactic-close-pure-syntax pps))
     (t (syntactic-close--generic nil nil pps))
     )))

(defun syntactic-close--semicolon-modes (pps)
  "Close specific modes.

Argument PPS, the result of ‘parse-partial-sexp’."
  (let ((closer
	 (cond ((nth 3 pps)
		(save-excursion (goto-char (nth 8 pps))
				(char-to-string (char-after))))
	       ((save-excursion
		  (and (nth 1 pps) (syntactic-close-pure-syntax-intern pps))))
               ((looking-back syntactic-close-import-re (line-beginning-position))
                ";")
	       (t (syntactic-close--generic nil nil pps)))))
    (cond
     ((and closer (string-match "}" closer))
      (if (save-excursion (skip-chars-backward " \t\r\n\f") (member (char-before) (list ?\; ?})))
	  closer
	";"))
     ((ignore-errors (and (< (nth 1 pps) (nth 8 pps))
			  (setq closer (syntactic-close--string-before-list-maybe pps)))))
     ((nth 3 pps)
      closer)
     ((and closer (string-match ")" closer))
      closer)
     ((save-excursion (beginning-of-line) (looking-at syntactic-close-assignment-re))
      (setq closer ";"))
     (t closer))))

(defun syntactic-close--specific-modes (pps)
  "Argument PPS result of ‘parse-partial-sexp’."
  (pcase major-mode
    (`agda2-mode
     (syntactic-close-haskell-close pps))
    (`emacs-lisp-mode
     (syntactic-close-emacs-lisp-close pps))
    (`html-mode
     (syntactic-close-ml))
    (`java-mode
     (syntactic-close-java))
    (`mhtml-mode
     (syntactic-close-ml))
    (`nxml-mode
     (syntactic-close--finish-element))
    (`org-mode
     (syntactic-close-emacs-lisp-close pps t))
    (`python-mode
     (syntactic-close-python-close pps))
    (`ruby-mode
     (syntactic-close-ruby-close pps))
    (`scala-mode
     (syntactic-close-scala-close pps))
    (`shell-mode
     (syntactic-close-shell-close pps))
    (`sgml-mode
     (syntactic-close-ml))
    (`xml-mode
     (syntactic-close-ml))
    (`xxml-mode
     (syntactic-close-ml))))

(defun syntactic-close--modes (pps)
  "Argument PPS, the result of ‘parse-partial-sexp’."
  (save-excursion
    (cond ((member major-mode syntactic-close--semicolon-separator-modes)
           (syntactic-close--semicolon-modes pps))
          ;; (pcase major-mode
          ;;   (`java-mode (syntactic-close--semicolon-modes pps))
          ;;   (`js-mode (syntactic-close--semicolon-modes pps))
          ;;   (`php-mode (syntactic-close--semicolon-modes pps))
          ;;   (`python-mode (syntactic-close-python-close pps))
          ;;   (`web-mode (syntactic-close--semicolon-modes pps))
          ;;   (_
          (t
           ;; (if
	   ;;       (ignore-errors (and (nth 3 pps) (< (nth 1 pps) (nth 8 pps))))
	   ;;       (syntactic-close--string-before-list-maybe pps)
	   (syntactic-close--specific-modes pps)))))

(defun syntactic-close--finish-element ()
  "Finish the current element by inserting an end-tag."
  (interactive "*")
  (let ((orig (point)))
    (nxml-finish-element-1 nil)
    (< orig (point))))

(defun syntactic-close-generic-forms (pps)
  "Argument PPS, the result of ‘parse-partial-sexp’."
  (cond
   ((syntactic-close--generic nil nil pps))
   ((nth 4 pps)
    ;; in comment
    (syntactic-close--insert-comment-end-maybe pps))))

(defun syntactic-close--string-before-list-maybe (pps)
  "String inside a list needs to be closed first maybe.

Expects start of string behind start of list
Argument PPS result of ‘parse-partial-sexp’."
  ;; maybe close generic first
  (cond
	((syntactic-close-pure-syntax-intern pps))
        ((syntactic-close--generic (point) nil pps))
        ))

(defun syntactic-close-intern (orig iact pps)
  "A first dispatch.

Argument ORIG the position command was called from.
Argument BEG the lesser border.
Argument IACT signals an interactive call.
Optional argument PPS, the result of ‘parse-partial-sexp’."
  (let (closer)
    (when syntactic-close-electric-delete-whitespace-p
      (delete-region orig (progn (skip-chars-backward " \t" (line-beginning-position))(point))))
    ;; (save-excursion
    (setq closer
	  (if
	      (member major-mode syntactic-close-modes)
	      (syntactic-close--modes pps)
	    (syntactic-close--generic orig nil pps)))
    ;; insert might be hardcoded like in ‘nxml-finish-element-1’
    (when (and closer (stringp closer))
      ;; (goto-char orig)
      (insert closer)
      ;; ruby end
      (when (member major-mode syntactic-close-indent-modes)
	(save-excursion (indent-according-to-mode))))
    (or (< orig (point)) (and iact (message "%s" "nil") nil))))

;;;###autoload
(defun syntactic-close (&optional arg beg pps iact)
  "Insert closing delimiter.

With \\[universal-argument]: close everything at point.
For example
\"\\(^ *\\|^Some: *\\|\\( FOO\\|'s\\|Bar\\|BAZ\\|Outer\\(?: \\(?:\\(?:sim\\|zh

should end up as
\"\\(^ *\\|^Some: *\\|\\( FOO\\|'s\\|Bar\\|BAZ\\|Outer\\(?: \\(?:\\(?:sim\\|zh\\)\\)\\)\"

Optional argument ARG signals interactive use.
Optional argument BEG sets the lesser border.
Argument PPS, the result of ‘parse-partial-sexp’."
  (interactive "p*")
  (let* ((orig (copy-marker (point)))
	 (beg (or beg (syntactic-close--point-min)))
	 (pps (or pps (parse-partial-sexp beg (point))))
	 (iact (or iact arg))
	 (arg (or arg 1)))
    (pcase (prefix-numeric-value arg)
      (4 (while (syntactic-close-intern (setq orig (copy-marker (point))) iact pps))
	 (< orig (point)))
      (_ (syntactic-close-intern orig iact pps)
         (< orig (point))))))

(provide 'syntactic-close)
;;; syntactic-close.el ends here
