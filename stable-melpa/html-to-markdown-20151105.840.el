;;; html-to-markdown.el --- HTML to Markdown converter written in Emacs-lisp.

;; Copyright (C) 2013 Artur Malabarba <bruce.connor.am@gmail.com>

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>
;; URL: http://github.com/Bruce-Connor/html-to-markdown
;; Package-Version: 20151105.840
;; Package-Commit: 60c5498c801be186478cf7c05be05b4430c4a144
;; Version: 1.5.1
;; Keywords: tools wp languages
;; Prefix: htm
;; Separator: -
;; Package-Requires: ((cl-lib "0.5"))

;;; Commentary:
;;
;; ### HTML to Markdown converter written in Emacs-lisp. ###
;; 
;; This package defines two main functions: `html-to-markdown' and
;; `html-to-markdown-string'.
;; 
;; The functions are written entirely in Emacs-lisp (which means they'll
;; work on any platform with no external dependencies), and they convert
;; HTML source code into Markdown format. Of course, HTML has many more
;; features than Markdown, so any tags that can't be converted are left
;; as-is (or deleted, if the user so requests).
;; 
;; Instructions
;; ------
;; 
;; To use this package, simply install it from Melpa (M-x
;; `package-install' RET html-to-markdown) and the relevant functions will
;; be autoloaded.
;; 
;; - `html-to-markdown'  
;;   Is meant for interactive use. It takes the current buffer (or
;;   region), converts to Markdown, and displays the result in a separate
;;   window.
;; 
;; - `html-to-markdown-string'  
;;   Is meant for lisp code. It takes a string argument, which is
;;   converted to Markdown, and the result is returned.
;;   
;; Both of these functions take an extra boolean argument
;; `erase-unknown'. If it's non-nil, tags which can't be converted will
;; be erased.

;;; License:
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 

;;; Change Log:
;; 1.5   - 2013/12/12 - No longer auto-fill.
;; 1.5   - 2013/12/12 - Better list handling.
;; 1.4   - 2013/12/07 - Replace ALL entities, but only those that are displayable.
;; 1.3   - 2013/12/06 - htm-entities-alist converts non-ascii chars.
;; 1.2   - 2013/12/06 - convert-this-buffer.
;; 1.1   - 2013/12/05 - Activate markdown-mode when called interactively.
;; 1.0.1 - 2013/12/04 - Reorder vars to avoid compilation warning.
;; 1.0   - 2013/11/30 - First Release.
;;; Code:
(require 'thingatpt)
(require 'cl-lib)

(defconst html-to-markdown-version "1.5.1" "Version of the html-to-markdown.el package.")
(defconst html-to-markdown-version-int 9 "Version of the html-to-markdown.el package, as an integer.")
(defun htm-bug-report ()
  "Opens github issues page in a web browser. Please send any bugs you find.
Please include your emacs and html-to-markdown versions."
  (interactive)
  (message "Your htm-version is: %s, and your emacs version is: %s.\nPlease include this in your report!"
           html-to-markdown-version emacs-version)
  (browse-url "https://github.com/Bruce-Connor/html-to-markdown/issues/new"))

(defgroup html-to-markdown nil
  "Customization group for html-to-markdown."
  :group 'convenience :group 'files :prefix "htm")

(defcustom htm-output-buffer-name "*html-to-markdown output*"
  "Name used for the buffer which holds conversion output."
  :type 'string :group 'html-to-markdown)

(defcustom htm-do-fill-paragraph nil
  "If non-nil, paragraphs will be filled during the conversion.

This sometimes leads to bad results (because the filling is done
while in html-mode). So we disable it by default."
  :type 'boolean :group 'html-to-markdown)
;Old doc (was this wrong or what)
;; This leads to good results (it won't screw up your line breaks or
;; anything), but some markdown interpreters treat filled paragraphs
;; as if they had line breaks. So this may be useful for some
;; people.

(defvar htm--erase-unknown-tags nil "")

(defvar htm--list-depth 0
  "How many spaces should we currently indent list items?")

(defvar htm--ordered-list-counter nil
  "If in ordered-list, this is the current counter. o.w. this is nil.")

(defvar htm--list-step 0 "")

(defun htm--find-close-while-parsing (tag)
  "Search forward for TAG, while parsing other tags found on the way."
  (let ((tag-name (or tag ""))
        (is-searching t))
    (while (and is-searching
                (search-forward-regexp "<[!\\?/a-z]\\|\n" nil t))
      (let ((delimiter (save-match-data (in-string-p))) ;thingatpt.el
            tag-found is-close) 
        ;; If we're inside a string, don't mess with anything, move on...
        (if delimiter
            (search-forward (char-to-string delimiter))
          ;; Check if we matched a tag or a newline.
          (if (looking-back "\n")
              (unless htm--inside-pre
                (delete-char -1)
                (just-one-space 1))
            ;; If it IS a tag, check if it opens or closes.
            (when (looking-back "/") (setq is-close t))
            ;; Move to its beginning
            (skip-chars-backward "[:alpha:]") ;; (forward-char -1)
            (setq tag-found (thing-at-point 'word))
            ;; If we found what we were looking for, that's it.
            (if tag-found
                (if (and is-close (string= tag-found tag-name))
                    (setq is-searching nil)
                  ;; If not, keep parsing.
                  (if (and is-close (fboundp (intern (concat "htm--parse-" tag-found))))
                      (error "Found </%s>, while expected %s."
                             tag-found
                             (if tag (format "</%s>" tag-name) "an openning tag"))
                    (htm--parse-any-tag tag-found)))
              (if (and (looking-at "--")
                       (looking-back "<!"))
                  (htm--parse-any-tag "comment")))))))
    (and is-searching tag (error "File ended before closing </%s>." tag-name))))

(defun htm--parse-any-tag (&optional tag)
  "Parse TAG or tag under point."
  (let* ((tag (or tag (thing-at-point 'word)))
         (func (intern (concat "htm--parse-" tag))))
    (if (fboundp func)
        (funcall func)
      (when htm--erase-unknown-tags
        (htm--delete-tag-at-point)))))

(defun htm--backtick-unless-inside-pre ()
  "Insert \"`\", unless `htm--inside-pre` is non-nil."
  (unless htm--inside-pre (insert "`")))

(defun htm--define-simple-replacer (cons)
  "Define a function which replaces (car CONS) with (cdr CONS)."
  (let* ((tag (car cons))
         (mds (cdr cons))
         (var-name (intern (concat "htm--inside-" tag)))
         (mdl (car-safe mds))
         (mdr (or (car-safe (cdr-safe mds)) mdl))) ;; mds = markdown-syntax
    (eval
     `(progn
        (defvar ,var-name nil
          ,(format "Variable let-bound to t while we're inside a %s tag." tag))
        (defun ,(intern (concat "htm--parse-" tag)) ()
          ,(format "Convert <%s> and </%s> tags into %s." tag tag mds)
          (htm--delete-tag-at-point)
          ,(if (and (symbolp mdl) (fboundp mdl))
               `(funcall ',mdl)
             `(insert ,mdl))
          (let ((,var-name t))
            (htm--find-close-while-parsing ,tag))
          (htm--delete-tag-at-point)
          (let (point)
            (save-excursion
              (skip-chars-backward "\n ")
              ,(if (and (symbolp mdr) (fboundp mdr))
                   `(funcall ',mdr)
                 `(insert ,mdr))
              (setq point (point)))
            (if (> point (point)) (goto-char point))))))))

(defconst htm--simple-replacers-alist
  '(("i"       "_")
    ("em"      "_")
    ("b"       "**")
    ("strong"  "**")
    ("strike"  "~~")
    ("pre"     "\n```\n")
    ("h1"      "\n" "\n---\n")
    ("h2"      "\n" "\n===\n")
    ("h3"      "\n### " " ###\n")
    ("h4"      "\n#### " " ####\n")
    ("h5"      "\n##### " " #####\n")
    ("h6"      "\n###### " " ######\n")
    ("h7"      "\n####### " " #######\n")
    ("h8"      "\n######## " " ########\n")
    ("h9"      "\n######### " " #########\n")
    ("code"   htm--backtick-unless-inside-pre))
  "List of (TAG . MARKDOWN-SYNTAX) used to define htm--parse- functions.

This defines a function htm--parse-TAG and a variable htm--inside-TAG.

MARKDOWN-SYNTAX is either,
    (SYNTAX)
 or 
    (LEFT-SYNTAX RIGHT-SYNTAX)
where the syntaxes can be strings or symbols. If they're symbols
they are called as functions.")

(mapc 'htm--define-simple-replacer htm--simple-replacers-alist)

(defmacro htm--define-list-replacer (tag mds ordered)
  (let ((step (length mds)))
    `(defun ,(intern (concat "htm--parse-" tag)) ()
       ,(format "Convert <li> inside a <%s> into %s." tag mds)
       (htm--delete-tag-at-point)
       (let ((fill-prefix fill-prefix))
         (if (= htm--list-step 0)
             (insert "\n\n\n")
           (setq fill-prefix (concat (or fill-prefix "")
                                     (make-string htm--list-step 32))))
         (cl-incf htm--list-depth htm--list-step)
         (let ((htm--ordered-list-counter ,ordered)
               (htm--list-step (+ ,step htm--list-step)))
           (htm--find-close-while-parsing ,tag))
         (cl-decf htm--list-depth htm--list-step))
       (htm--delete-tag-at-point)
       (htm--ensure-blank-line))))
(htm--define-list-replacer "ul" "-" nil)
(htm--define-list-replacer "ol" "1." 0)

(defun htm--ensure-blank-line ()
  (if (not (looking-back "^ *"))
      (insert "\n\n")
    (unless (looking-back "\n *\n *")
      (insert "\n"))
    (when (looking-back "^ +")
      (replace-match "" :fixedcase))))

(defun htm--get-tag-property (prop)
  "Rerturn the property PROP of the that under point.

Doesn't move point, and assumes that point is on the tag name."
  (let ((rp (regexp-quote prop))
        (r
         (save-excursion
           (search-backward "<")
           (forward-sexp 1)
           (1- (point)))))
    (save-excursion
      (while (and (not (looking-at rp))
                  (< (point) r))
        (forward-sexp 1)
        (skip-chars-forward "\n 	"))
      (if (not (looking-at rp))
          ""
        (forward-sexp 1)
        (setq r (point))
        (forward-sexp 1)
        (buffer-substring-no-properties r (point))))))

(defun htm--parse-img ()
  "Convert <a href=\"foo\">text</a> into [text](foo)."
  (let ((src (htm--get-tag-property "src"))
        (alt (htm--get-tag-property "alt")))
    (htm--delete-tag-at-point)
    (insert (format "![%s](%s)" src alt))))

(defun htm--parse-a ()
  "Convert <img> into ![text](foo)."
  (let ((href (htm--get-tag-property "href")))
    (htm--delete-tag-at-point)
    (insert "[")
    (htm--find-close-while-parsing "a")
    (htm--delete-tag-at-point)
    (insert (format "](%s)" href))))

(defun htm--parse-hr ()
  "Convert <hr> into ---."
  (htm--delete-tag-at-point)
  (insert "\n---\n\n"))

(defun htm--parse-comment ()
  "Skip over comments."
  (search-backward "<!")
  (let ((l (point)))
    (search-forward "-->")
    (delete-region l (point))))

(defun htm--parse-li ()
  "Convert <li> into 1. or -."
  (htm--delete-tag-at-point)
  (htm--ensure-blank-line)
  (htm--add-padding)
  (let ((indent (make-string htm--list-depth 32))
        (fill-prefix (concat (or fill-prefix "") " "
                             ;; (make-string (+ 1 htm--list-depth htm--list-step) ?\s)
                             )))
    (if (null htm--ordered-list-counter)
        (insert "- ")
      (cl-incf htm--ordered-list-counter)
      (insert (format "%s. " htm--ordered-list-counter)))
    (htm--find-close-while-parsing "li"))
  (htm--delete-tag-at-point)
  (when htm-do-fill-paragraph
    (save-excursion (skip-chars-backward "\n ") (fill-paragraph))))

(defun htm--parse-p ()
  "Convert <p> into blank lines.

Assumes that you won't have plain text and <p>'d text in the same
line. If you do, this will end up merging them together."
  (htm--delete-tag-at-point)
  (when (looking-back "^\\s-*")
    (unless (looking-back "\n\\s-*\n\\s-*")
      (insert "\n"))
    ;; (htm--ensure-blank-line)
    (while (looking-back " ") (delete-char -1))
    (htm--add-padding)
    ;; (when htm--inside-pre
    ;;   (insert "    "))
    )
  (htm--find-close-while-parsing "p")
  (htm--delete-tag-at-point)
  (when htm-do-fill-paragraph
    (save-excursion (skip-chars-backward "\n ") (fill-paragraph)))
  (htm--ensure-blank-line))

(defun htm--parse-blockquote ()
  "Convert <blockquote> into \"> \"."
  (htm--delete-tag-at-point)
  (insert "\n\n")
  (let ((fill-prefix (concat (or fill-prefix "") "> ")))
    (htm--add-padding)
    (htm--find-close-while-parsing "blockquote")
    (htm--delete-tag-at-point)
    (when htm-do-fill-paragraph
      (save-excursion (skip-chars-backward "\n ") (fill-paragraph))))
  (insert "\n"))

(defun htm--parse-br ()
  "Convert <br> into \"  \\n\".

We need to keep the <br> that don't come directly after text,
otherwise markdown will just swallow the extra blank lines and
the formatting will be lost."
  (if (looking-back "</")
      ;; On a close tag, do nothing.
      (htm--delete-tag-at-point)
    (if (looking-back "^ *<")
        (progn (forward-char -1)
               (forward-sexp 1))
      (htm--delete-tag-at-point)
      (when htm-do-fill-paragraph
        (fill-paragraph))
      (insert "  "))
    (insert "\n\n")
    (while (looking-at "[ \n]")
      (delete-char 1))
    (htm--add-padding)))

(defun htm--add-padding ()
  ;; (when (> htm--list-step 0)
  ;;   (insert (make-string (+ 1 htm--list-step htm--list-depth) ?\s)))
  (when (stringp fill-prefix) (insert fill-prefix)))

(defun htm--delete-tag-at-point ()
  (save-match-data
    (search-backward "<")
    (let ((opoint (point)))
      (forward-sexp 1)
      (delete-region opoint (point)))))

(defcustom htm-entities-alist
  '( ;; ("#62" . ">") ("gt"  . ">") ;; The > is a little dangerous.
    ;; ("lt"     . "<") ("#60"    . "<") ;; The < too.
    ("#160"   . " ") ("#161"   . "¡") ("#162"   . "¢") ("#163"   . "£")
    ("#164"   . "¤") ("#165"   . "¥") ("#166"   . "¦") ("#167"   . "§")
    ("#168"   . "¨") ("#169"   . "©") ("#170"   . "ª") ("#171"   . "«")
    ("#172"   . "¬") ("#173"   . "­") ("#174"   . "®") ("#175"   . "¯")
    ("#176"   . "°") ("#177"   . "±") ("#178"   . "²") ("#179"   . "³")
    ("#180"   . "´") ("#181"   . "µ") ("#182"   . "¶") ("#183"   . "·")
    ("#184"   . "¸") ("#185"   . "¹") ("#186"   . "º") ("#187"   . "»")
    ("#188"   . "¼") ("#189"   . "½") ("#190"   . "¾") ("#191"   . "¿")
    ("#192"   . "À") ("#193"   . "Á") ("#194"   . "Â") ("#195"   . "Ã")
    ("#196"   . "Ä") ("#197"   . "Å") ("#198"   . "Æ") ("#199"   . "Ç")
    ("#200"   . "È") ("#201"   . "É") ("#202"   . "Ê") ("#203"   . "Ë")
    ("#204"   . "Ì") ("#205"   . "Í") ("#206"   . "Î") ("#207"   . "Ï")
    ("#208"   . "Ð") ("#209"   . "Ñ") ("#210"   . "Ò") ("#211"   . "Ó")
    ("#212"   . "Ô") ("#213"   . "Õ") ("#214"   . "Ö") ("#215"   . "×")
    ("#216"   . "Ø") ("#217"   . "Ù") ("#218"   . "Ú") ("#219"   . "Û")
    ("#220"   . "Ü") ("#221"   . "Ý") ("#222"   . "Þ") ("#223"   . "ß")
    ("#224"   . "à") ("#225"   . "á") ("#226"   . "â") ("#227"   . "ã")
    ("#228"   . "ä") ("#229"   . "å") ("#230"   . "æ") ("#231"   . "ç")
    ("#232"   . "è") ("#233"   . "é") ("#234"   . "ê") ("#235"   . "ë")
    ("#236"   . "ì") ("#237"   . "í") ("#238"   . "î") ("#239"   . "ï")
    ("#240"   . "ð") ("#241"   . "ñ") ("#242"   . "ò") ("#243"   . "ó")
    ("#244"   . "ô") ("#245"   . "õ") ("#246"   . "ö") ("#247"   . "÷")
    ("#248"   . "ø") ("#249"   . "ù") ("#250"   . "ú") ("#251"   . "û")
    ("#252"   . "ü") ("#253"   . "ý") ("#254"   . "þ") ("#255"   . "ÿ")
    ("#34"    . "\"") ("#38"    . "&") ("#39"    . "'")
    ("AElig"  . "Æ") ("Aacute" . "Á") ("Acirc"  . "Â") ("Agrave" . "À")
    ("Aring"  . "Å") ("Atilde" . "Ã") ("Auml"   . "Ä") ("Ccedil" . "Ç")
    ("ETH"    . "Ð") ("Eacute" . "É") ("Ecirc"  . "Ê") ("Egrave" . "È")
    ("Euml"   . "Ë") ("Iacute" . "Í") ("Icirc"  . "Î") ("Igrave" . "Ì")
    ("Iuml"   . "Ï") ("Ntilde" . "Ñ") ("Oacute" . "Ó") ("Ocirc"  . "Ô")
    ("Ograve" . "Ò") ("Oslash" . "Ø") ("Otilde" . "Õ") ("Ouml"   . "Ö")
    ("THORN"  . "Þ") ("Uacute" . "Ú") ("Ucirc"  . "Û") ("Ugrave" . "Ù")
    ("Uuml"   . "Ü") ("Yacute" . "Ý") ("aacute" . "á") ("acirc"  . "â")
    ("acute"  . "´") ("aelig"  . "æ") ("agrave" . "à") ("amp"    . "&")
    ("apos"   . "'") ("aring"  . "å") ("atilde" . "ã") ("auml"   . "ä")
    ("brvbar" . "¦") ("ccedil" . "ç") ("cedil"  . "¸") ("cent"   . "¢")
    ("copy"   . "©") ("curren" . "¤") ("deg"    . "°") ("divide" . "÷")
    ("eacute" . "é") ("ecirc"  . "ê") ("egrave" . "è") ("eth"    . "ð")
    ("euml"   . "ë") ("frac12" . "½") ("frac14" . "¼") ("frac34" . "¾")
    ("iacute" . "í") ("icirc"  . "î") ("iexcl"  . "¡") ("igrave" . "ì")
    ("iquest" . "¿") ("iuml"   . "ï") ("laquo"  . "«")
    ("macr"   . "¯") ("micro"  . "µ") ("middot" . "·") ("nbsp"   . " ")
    ("not"    . "¬") ("ntilde" . "ñ") ("oacute" . "ó") ("ocirc"  . "ô")
    ("ograve" . "ò") ("ordf"   . "ª") ("ordm"   . "º") ("oslash" . "ø")
    ("otilde" . "õ") ("ouml"   . "ö") ("para"   . "¶") ("plusmn" . "±")
    ("pound"  . "£") ("quot"   . "\"") ("raquo"  . "»") ("reg"    . "®")
    ("sect"   . "§") ("shy"    . "­") ("sup1"   . "¹") ("sup2"   . "²")
    ("sup3"   . "³") ("szlig"  . "ß") ("thorn"  . "þ") ("times"  . "×")
    ("uacute" . "ú") ("ucirc"  . "û") ("ugrave" . "ù") ("uml"    . "¨")
    ("uuml"   . "ü") ("yacute" . "ý") ("yen"    . "¥") ("yuml"   . "ÿ"))
  "List of special chars to be replaced during conversion."
  :type '(repeat (cons string string))
  :group 'html-to-markdown
  :package-version '(html-to-markdown . "1.4"))

(defun htm--entities-regexp ()
  "Replace &xx; entities with their chars.

\">\" is not replaced to avoid conflict with quotes."
  (format "&\\(%s\\);"
          (regexp-opt 
           (remove nil
                   (mapcar (lambda (x) (when (char-displayable-p (string-to-char (cdr x)))
                                    (car x)))
                           htm-entities-alist)))))

(defun htm--convert (erase-unknown)
  "Perform the actual conversion.

This sort-of expects a temp buffer, because major-mode will be changed."
  (html-mode)
  (goto-char (point-min))
  ;; Perform the conversion
  (let ((htm--erase-unknown-tags erase-unknown))
    (htm--find-close-while-parsing nil))
  (goto-char (point-min))
  ;; Sometimes we get a blank line at the top
  (when (looking-at "[	 ]*\n") (replace-match ""))
  ;; We overkill when it comes to linebreaks, this is where we fix it
  (while (search-forward-regexp "\\(< *br *>\\|  \\)\n" nil t)
    (replace-match "\\1" :fixedcase))
  (goto-char (point-min))
  ;; We overkill when it comes to linebreaks, this is where we fix it
  (while (search-forward-regexp "\n\\(\n *>\\)" nil t)
    (replace-match "\\1" :fixedcase))
  (goto-char (point-min))
  (while (search-forward-regexp
          "\n\\(\n *[-\\*+] \\|\n *[2-9][0-9]*\\. \\)" nil t)
    (replace-match "\\1" :fixedcase))
  (goto-char (point-min))
  ;; Convert Special entities
  (let ((er (htm--entities-regexp)))
    (while (search-forward-regexp er nil t)
      (replace-match (cdr (assoc (match-string-no-properties 1)
                                 htm-entities-alist)) :fixedcase))))

;;;###autoload
(defun html-to-markdown (&optional erase-unknown)
  "Convert contents of current buffer from html to markdown.

This is meant for interactive use. For lisp code, use:
    (html-to-markdown-string (buffer-string))

If the prefix argument ERASE-UNKNOWN is non-nil, tags which can't
be converted to markdown will be erased (default is to keep them
as-is).
Further behavior is controlled by two variables,
`htm-do-fill-paragraph' and `htm-output-buffer-name'.

Understands the following html tags: p, br, ol, ul, li, h[1-9],
b, it, strong, em, blockquote, pre, code."
  (interactive "P")
  (let* ((l (if (region-active-p) (region-beginning) (point-min)))
         (r (if (region-active-p) (region-end) (point-max)))
         (source (buffer-substring l r)))
    (with-output-to-temp-buffer htm-output-buffer-name
      (set-buffer htm-output-buffer-name)
      (insert source)
      (htm--convert erase-unknown)
      (when (and (called-interactively-p 'any)
                 (fboundp 'markdown-mode))
        (markdown-mode)))))

;;;###autoload
(defun html-to-markdown-string (source &optional erase-unknown)
  "Convert contents of string SOURCE from html to markdown.

Returns a string with the result.

If ERASE-UNKNOWN is non-nil, tags which can't be converted to
markdown will be erased (default is to keep them as-is).
Further behavior is controlled by two variables,
`htm-do-fill-paragraph' and `htm-output-buffer-name'.

Understands the following html tags: p, br, ol, ul, li, h[1-9],
b, it, strong, em, blockquote, pre, code."
  (interactive "MHTML Source: \nP")
  (let ((res
         (with-temp-buffer
           (insert source)
           (htm--convert erase-unknown)
           (buffer-string))))
    (when (called-interactively-p 'any)
      (with-output-to-temp-buffer htm-output-buffer-name
        (set-buffer htm-output-buffer-name)
        (insert res)
        (when (fboundp 'markdown-mode)
          (markdown-mode)))
      (kill-new res)
      (message "Resulting Markdown pushed to kill-ring."))
    res))


;;;###autoload
(defun html-to-markdown-this-buffer (&optional erase-unknown)
  "Like `html-to-markdown', except ERASES the current buffer and inserts the result."
  (interactive "P")
  (let ((res (html-to-markdown-string (buffer-string) erase-unknown)))
    (erase-buffer)
    (insert res)
    (when (and (called-interactively-p 'any)
               (fboundp 'markdown-mode))
      (markdown-mode))))

(provide 'html-to-markdown)
;;; html-to-markdown.el ends here.
