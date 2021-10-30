;;; slirm.el --- Systematic Literature Review Mode for Emacs.  -*- lexical-binding: t; -*-

;; Author: Florian Biermann <fbie@itu.dk>
;; URL: http://github.com/fbie/slirm
;; Package-Version: 20160201.1425
;; Package-Commit: 9adfbe1fc67580e7d0d90f7e927a25d63a797464
;; Version: 1.0
;; Package-Requires: ((emacs "24.4."))

;; Copyright 2016 Florian Biermann <fbie@itu.dk>
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;; DEALINGS IN THE SOFTWARE.

;; Commentary:

;; Convenient browsing of BibTeX files for annotating individual
;; entries.  See http://github.com/fbie/slirm/Readme.md for further
;; instructions.

;; Code:

;; All functions that must be called with (slirm--bibtex-buffer) as
;; the current buffer are prefixed with "slirm--bibtex-".  It is okay
;; to call such BibTeX functions from within other BibTeX functions
;; without enclosing them in slirm--with-bibtex-buffer, which
;; temporarily makes (slirm--bibtex-buffer) current and stores the
;; point used by Slirm.  Nesting calls to slirm--with-bibtex-buffer
;; must be avoided, as slirm--with-bibtex-buffer is not an idempotent
;; operation.

(require 'bibtex)
(require 'subr-x)

;; Macros to handle with-current-buffer so that we can keep references
;; to the point of the buffer that we modify.

(defmacro slirm--with-current-buffer (buffer &rest body)
  "Like (with-current-buffer BUFFER (save-excursion &BODY)) but save the point."
  (declare (indent 1))
  ;; We jump through a bunch of hoops to keep a buffer-local reference
  ;; to our point in the BibTeX buffer.
  (let ((body-res (cl-gensym "body-res"))
	(current-point (cl-gensym "current-point")))
    `(let ((,current-point slirm--point)
	   (,body-res nil))
       (with-current-buffer ,buffer
	 (save-excursion
	   (goto-char ,current-point)	  ;; Load point.
	   (setq ,body-res (progn ,@body) ;; Execute body and bind result.
		 ,current-point (point)))) ;; Store point and return to BibTeX buffer.
       (setq slirm--point ,current-point)
       ,body-res))) ;; Return body's result.

(defmacro slirm--with-bibtex-buffer (&rest body)
  "Perform BODY in slirm--bibtex-buffer."
  (declare (indent 0))
  `(slirm--with-current-buffer (slirm--bibtex-buffer)
     ,@body))

(defmacro slirm--override-readonly (&rest body)
  "Execute BODY, overriding readonly mode."
  (declare (indent 0))
  `(progn
     (setq inhibit-read-only t)
     ,@body
     (setq inhibit-read-only nil)))

(defmacro slirm--for-all-entries-do (&rest body)
  "Execute BODY once for each entry."
  (declare (indent 0))
  `(slirm--with-bibtex-buffer
     (save-excursion
       (goto-char (point-min))
       (while (slirm--bibtex-move-point-to-entry slirm--next)
	 (progn
	   ,@body)))))

;; BibTeX utility functions for moving point from entry to entry and
;; to access fields conveniently.
(defconst slirm--next 're-search-forward)
(defconst slirm--prev 're-search-backward)

;; Mode hook.
(defvar slirm-mode-hook nil)

;; Local variables for keeping track of the corresponding BibTeX file
;; and the corresponding point.
(defvar slirm--bibtex-file-tmp "" "The name of the BibTeX file, temporarily.")
(defvar-local slirm--bibtex-file "" "The name of the BibTeX file.")
(defvar-local slirm--point 0 "Slirm's point in the BibTeX file.")

(defconst slirm--review "review" "The review field name.")
(defconst slirm--accept "accepted")
(defconst slirm--reject "rejected")
(defconst slirm--abstract "abstract" "The abstract field name.")
(defconst slirm--full-text-url "fullTextUrl" "The fullTextUrl field name.")
(defconst slirm--full-text-file "fullTextFile" "The fullTextFile field name.")

(defun slirm--bibtex-move-point-to-entry (direction)
  "Move point to the next entry in DIRECTION, which is one of slirm--{next, prev}."
  (when (save-excursion
	  (funcall direction "^@[a-zA-Z0-9]+{" nil t))
    (goto-char (match-beginning 0))))

(defun slirm--bibtex-parse-next ()
  "Convenience function to parse next entry."
  (slirm--bibtex-move-point-to-entry slirm--next)
  (bibtex-parse-entry t))

(defun slirm--bibtex-parse-prev ()
  "Convenience fuction to parse previous entry."
  ;; Gotta move up twice.
  (slirm--bibtex-move-point-to-entry slirm--prev)
  (slirm--bibtex-move-point-to-entry slirm--prev)
  (bibtex-parse-entry t))

(defun slirm--bibtex-parse ()
  "Parse current entry."
  (bibtex-parse-entry t))

(defun slirm--bibtex-reparse ()
  "Re-parse an entry, useful after modifications and so on."
  (slirm--bibtex-move-point-to-entry slirm--prev)
  (bibtex-parse-entry t))

(defun slirm--bibtex-move-point-to-field (field)
  "Move point to start of FIELD's text."
  (when (save-excursion
	  (re-search-backward (format "\s*%s\s*=[\s\t]*{" field) nil t))
    (goto-char (match-end 0))))

(defun slirm--bibtex-get-field (field entry)
  "Nil if FIELD is not present in ENTRY, otherwise the associated value."
  (let ((val (assoc field entry)))
    (when val
	(cdr val))))

(defun slirm--bibtex-add-field (field)
  "Add a field FIELD to the entry."
  (bibtex-make-field field t 'nil 'nil))

(defun slirm--bibtex-maybe-add-field (field entry)
  "Add FIELD to ENTRY if not already present."
  (when (not (slirm--bibtex-get-field field entry))
    (slirm--bibtex-add-field field)
    t))

(defun slirm--bibtex-write-to-field (field content)
  "Fill a FIELD with CONTENT if CONTENT is non-nil."
  (when content
    (slirm--bibtex-move-point-to-field field)
    (insert content)))

(defun slirm--bibtex-maybe-write-to-field (field entry content)
  "Write to FIELD if ENTRY does not contain it.  CONTENT is what is written if non-nil."
  (when (and content (slirm--bibtex-maybe-add-field field entry))
    (slirm--bibtex-write-to-field field content)))

(defun slirm--bibtex-kill-field (field)
  "Delete and return FIELD from current entry."
  (slirm--bibtex-move-point-to-field field)
  (when (save-excursion
	    (re-search-forward "},\n" nil t))
      (delete-region (point) (match-beginning 0))))

(defun slirm--bibtex-write (entry)
  "Write ENTRY to current buffer."
  (insert (format "@%s{%s,\n}\n\n"
		  (slirm--bibtex-get-field "=type=" entry)
		  (slirm--bibtex-get-field "=key=" entry)))
  (slirm--bibtex-move-point-to-entry slirm--prev)
  (dolist (field entry)
    (let ((key (car field))
	  (val (cdr field)))
      (unless (or (string-equal key "=type=") (string-equal key "=key="))
	(slirm--bibtex-add-field key)
	(slirm--bibtex-write-to-field key val))))
  (bibtex-end-of-entry)
  (goto-char (1+ (point))))

(defun slirm--make-user-annotation (annotation)
  "Make a string of the form \"user-login-name: ANNOTATION\"."
  (format "%s: %s," user-login-name annotation))

(defun slirm--first-match (regex)
  "Return the first string matching REGEX in the entire buffer."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward regex nil t)
      (match-string 0))))

;; ACM utility functions to download full-text and abstract.
(defun slirm--acm-get-full-text-link ()
  "Return the link to the full-text from the current buffer containing an ACM website."
  (slirm--first-match "ft_gateway\.cfm\\?id=[0-9]+&ftid=[0-9]+&dwn=[0-9]+&CFID=[0-9]+&CFTOKEN=[0-9]+"))

(defun slirm--acm-get-abstract-link ()
  "Return the link to the abstract from the current buffer containing an ACM website."
  (slirm--first-match "tab_abstract\.cfm\\?id=[0-9]+&usebody=tabbody&cfid=[0-9]+&cftoken=[0-9]+"))

(defun slirm--acm-make-dl-link (link)
  "Build ACM link address from LINK."
  (when link
      (format "http://dl.acm.org/%s" link)))

(defun slirm--acm-get-links (acm-url)
  "Retrieves the links to the abstract and the full-text by retrieving ACM-URL."
  (with-current-buffer (url-retrieve-synchronously acm-url)
    (mapcar 'slirm--acm-make-dl-link
	    (list (slirm--acm-get-abstract-link)
		  (slirm--acm-get-full-text-link)))))

;; Original map from
;; http://ergoemacs.org/emacs/elisp_replace_html_entities_command.html
(defconst slirm--html-replace-map '(("&nbsp;" " ") ("&ensp;" " ")
  ("&emsp;" " ") ("&thinsp;" " ") ("&rlm;" "‏") ("&lrm;" "‎")
  ("&zwj;" "‍") ("&zwnj;" "‌") ("&iexcl;" "¡") ("&cent;" "¢")
  ("&pound;" "£") ("&curren;" "¤") ("&yen;" "¥") ("&brvbar;" "¦")
  ("&sect;" "§") ("&uml;" "¨") ("&copy;" "©") ("&ordf;" "ª")
  ("&laquo;" "«") ("&not;" "¬") ("&shy;" "­") ("&reg;" "®")
  ("&macr;" "¯") ("&deg;" "°") ("&plusmn;" "±") ("&sup2;" "²")
  ("&sup3;" "³") ("&acute;" "´") ("&micro;" "µ") ("&para;" "¶")
  ("&middot;" "·") ("&cedil;" "¸") ("&sup1;" "¹") ("&ordm;" "º")
  ("&raquo;" "»") ("&frac14;" "¼") ("&frac12;" "½")
  ("&frac34;" "¾") ("&iquest;" "¿") ("&Agrave;" "À")
  ("&Aacute;" "Á") ("&Acirc;" "Â") ("&Atilde;" "Ã")
  ("&Auml;" "Ä") ("&Aring;" "Å") ("&AElig;" "Æ") ("&Ccedil;" "Ç")
  ("&Egrave;" "È") ("&Eacute;" "É") ("&Ecirc;" "Ê")
  ("&Euml;" "Ë") ("&Igrave;" "Ì") ("&Iacute;" "Í")
  ("&Icirc;" "Î") ("&Iuml;" "Ï") ("&ETH;" "Ð") ("&Ntilde;" "Ñ")
  ("&Ograve;" "Ò") ("&Oacute;" "Ó") ("&Ocirc;" "Ô")
  ("&Otilde;" "Õ") ("&Ouml;" "Ö") ("&times;" "×")
  ("&Oslash;" "Ø") ("&Ugrave;" "Ù") ("&Uacute;" "Ú")
  ("&Ucirc;" "Û") ("&Uuml;" "Ü") ("&Yacute;" "Ý") ("&THORN;" "Þ")
  ("&szlig;" "ß") ("&agrave;" "à") ("&aacute;" "á")
  ("&acirc;" "â") ("&atilde;" "ã") ("&auml;" "ä") ("&aring;" "å")
  ("&aelig;" "æ") ("&ccedil;" "ç") ("&egrave;" "è")
  ("&eacute;" "é") ("&ecirc;" "ê") ("&euml;" "ë")
  ("&igrave;" "ì") ("&iacute;" "í") ("&icirc;" "î")
  ("&iuml;" "ï") ("&eth;" "ð") ("&ntilde;" "ñ") ("&ograve;" "ò")
  ("&oacute;" "ó") ("&ocirc;" "ô") ("&otilde;" "õ")
  ("&ouml;" "ö") ("&divide;" "÷") ("&oslash;" "ø")
  ("&ugrave;" "ù") ("&uacute;" "ú") ("&ucirc;" "û")
  ("&uuml;" "ü") ("&yacute;" "ý") ("&thorn;" "þ") ("&yuml;" "ÿ")
  ("&fnof;" "ƒ") ("&Alpha;" "Α") ("&Beta;" "Β") ("&Gamma;" "Γ")
  ("&Delta;" "Δ") ("&Epsilon;" "Ε") ("&Zeta;" "Ζ") ("&Eta;" "Η")
  ("&Theta;" "Θ") ("&Iota;" "Ι") ("&Kappa;" "Κ") ("&Lambda;" "Λ")
  ("&Mu;" "Μ") ("&Nu;" "Ν") ("&Xi;" "Ξ") ("&Omicron;" "Ο")
  ("&Pi;" "Π") ("&Rho;" "Ρ") ("&Sigma;" "Σ") ("&Tau;" "Τ")
  ("&Upsilon;" "Υ") ("&Phi;" "Φ") ("&Chi;" "Χ") ("&Psi;" "Ψ")
  ("&Omega;" "Ω") ("&alpha;" "α") ("&beta;" "β") ("&gamma;" "γ")
  ("&delta;" "δ") ("&epsilon;" "ε") ("&zeta;" "ζ") ("&eta;" "η")
  ("&theta;" "θ") ("&iota;" "ι") ("&kappa;" "κ") ("&lambda;" "λ")
  ("&mu;" "μ") ("&nu;" "ν") ("&xi;" "ξ") ("&omicron;" "ο")
  ("&pi;" "π") ("&rho;" "ρ") ("&sigmaf;" "ς") ("&sigma;" "σ")
  ("&tau;" "τ") ("&upsilon;" "υ") ("&phi;" "φ") ("&chi;" "χ")
  ("&psi;" "ψ") ("&omega;" "ω") ("&thetasym;" "ϑ")
  ("&upsih;" "ϒ") ("&piv;" "ϖ") ("&bull;" "•") ("&hellip;" "…")
  ("&prime;" "′") ("&Prime;" "″") ("&oline;" "‾") ("&frasl;" "⁄")
  ("&weierp;" "℘") ("&image;" "ℑ") ("&real;" "ℜ") ("&trade;" "™")
  ("&alefsym;" "ℵ") ("&larr;" "←") ("&uarr;" "↑") ("&rarr;" "→")
  ("&darr;" "↓") ("&harr;" "↔") ("&crarr;" "↵") ("&lArr;" "⇐")
  ("&uArr;" "⇑") ("&rArr;" "⇒") ("&dArr;" "⇓") ("&hArr;" "⇔")
  ("&forall;" "∀") ("&part;" "∂") ("&exist;" "∃") ("&empty;" "∅")
  ("&nabla;" "∇") ("&isin;" "∈") ("&notin;" "∉") ("&ni;" "∋")
  ("&prod;" "∏") ("&sum;" "∑") ("&minus;" "−") ("&lowast;" "∗")
  ("&radic;" "√") ("&prop;" "∝") ("&infin;" "∞") ("&ang;" "∠")
  ("&and;" "∧") ("&or;" "∨") ("&cap;" "∩") ("&cup;" "∪")
  ("&int;" "∫") ("&there4;" "∴") ("&sim;" "∼") ("&cong;" "≅")
  ("&asymp;" "≈") ("&ne;" "≠") ("&equiv;" "≡") ("&le;" "≤")
  ("&ge;" "≥") ("&sub;" "⊂") ("&sup;" "⊃") ("&nsub;" "⊄")
  ("&sube;" "⊆") ("&supe;" "⊇") ("&oplus;" "⊕") ("&otimes;" "⊗")
  ("&perp;" "⊥") ("&sdot;" "⋅") ("&lceil;" "⌈") ("&rceil;" "⌉")
  ("&lfloor;" "⌊") ("&rfloor;" "⌋") ("&lang;" "〈") ("&rang;" "〉")
  ("&loz;" "◊") ("&spades;" "♠") ("&clubs;" "♣")
  ("&hearts;" "♥") ("&diams;" "♦") ("&quot;" "\"")
  ("&OElig;" "Œ") ("&oelig;" "œ") ("&Scaron;" "Š")
  ("&scaron;" "š") ("&Yuml;" "Ÿ") ("&circ;" "ˆ") ("&tilde;" "˜")
  ("&ndash;" "–") ("&mdash;" "—") ("&lsquo;" "‘") ("&rsquo;" "’")
  ("&sbquo;" "‚") ("&ldquo;" "“") ("&rdquo;" "”") ("&bdquo;" "„")
  ("&dagger;" "†") ("&Dagger;" "‡") ("&permil;" "‰")
  ("&lsaquo;" "‹") ("&rsaquo;" "›") ("&euro;" "€")
  ("&equals;" "=") ("&lt;" "<") ("&gt;" ">")))

(defun slirm--replace-html-chars (html)
  "Replace all HTML characters like &quot; with their corresponding unicode."
  (let ((replaced html))
    (dolist (r slirm--html-replace-map)
      (setq replaced (replace-regexp-in-string (elt r 0) (elt r 1) replaced)))
    replaced))

(defun slirm--replace-regexps-in-string (regexps string)
  "Replace all of the regular-expression and string pairs from REGEXPS in STRING."
  (if regexps
      (let* ((head (car regexps))
	     (tail (cdr regexps))
	     (regexp (car head))
	     (replacement (cdr head)))
	(slirm--replace-regexps-in-string tail (replace-regexp-in-string regexp replacement string)))
    string))

(defun slirm--acm-get-abstract (url)
  "Download and format abstract text from URL."
  (with-current-buffer (url-retrieve-synchronously url)
    (slirm--first-match "<div .*>.*")
    (let ((abstract (buffer-substring (match-beginning 0) (point-max))))
      (slirm--replace-regexps-in-string (list ;; Replace latex reserved characters.
					 '("%" (replace-quote "\\%"))
					 '("{" (replace-quote "\\{"))
					 '("}" (replace-quote "\\}")))
				(slirm--replace-html-chars ;; Replace HTML characters.
				 (string-trim
				  (replace-regexp-in-string "<[^>]*>" "" abstract)))))))

;; Slirm URL handlers.
(defvar slirm--get-links-map nil)
(defvar slirm--get-abstract-map nil)

(defun slirm--lookup (map key)
  "Perform lookup in MAP for KEY."
  (car (cdr (assoc key map))))

(defun slirm-add-handlers (url links-handler abstract-handler)
  "Add handlers for URL, e.g. \"acm.org\".  LINKS-HANDLER must accept a url and return a list of links, ABSTRACT-HANDLER must accept a url and return a string."
  (setq slirm--get-links-map (cons (list url links-handler) slirm--get-links-map))
  (setq slirm--get-abstract-map (cons (list url abstract-handler) slirm--get-abstract-map)))

(slirm-add-handlers "acm.org" 'slirm--acm-get-links 'slirm--acm-get-abstract)

;; Functions for downloading webcontent, based on the mode handlers.

(defun slirm--get-base-url (url)
  "Return the base url of URL."
  (string-match "[a-zA-Z0-0+\\.-]+\\.[a-zA-Z]+" url)
  (let ((es (reverse (split-string (match-string 0 url) "\\."))))
    (format "%s.%s" (car (cdr es)) (car es))))

(defun slirm--get-remote (url getters)
  "Get something from a remote URL using the corresponding getter.
Getter is listed in GETTERS.  Returns nil if no adequate getter
can be found."
  (let ((getter (slirm--lookup getters (slirm--get-base-url url))))
    (when getter
      (funcall getter url))))

(defun slirm--get-links (url)
  "Get links from URL."
  (when url
    (slirm--get-remote url slirm--get-links-map)))

(defun slirm--get-abstract (url)
  "Get abstract from URL."
  (when url
    (slirm--get-remote url slirm--get-abstract-map)))

(defun slirm--bibtex-update-abstract-full-text-url (entry)
  "Update abstract and fullTextURL fields if they are empty in ENTRY."
  (when (not (and ;; Any of the two fields is empty.
	      (slirm--bibtex-get-field slirm--abstract entry)
	      (slirm--bibtex-get-field slirm--full-text-url entry)))
    (let* ((url (slirm--bibtex-get-field "url" entry))
	   (urls (slirm--get-links url))) ;; Download from the article's website.
      (when urls
	(slirm--bibtex-maybe-write-to-field slirm--abstract entry (slirm--get-abstract (car urls)))
	(slirm--bibtex-maybe-write-to-field slirm--full-text-url entry (car (cdr urls)))
	(save-buffer)))))

;; The main Slirm interaction functions.

(defun slirm--bibtex-mark-reviewed (entry verdict)
  "Mark ENTRY as reviewed with VERDICT."
  (slirm--bibtex-maybe-add-field slirm--review entry)
  (let* ((entry (slirm--bibtex-reparse))
	 (reviews (slirm--to-review-string (slirm--set-review
					    (slirm--to-review-list entry)
					    verdict))))
    (slirm--bibtex-kill-field slirm--review) ;; Find and delete review field content.
    (slirm--bibtex-write-to-field slirm--review reviews)
    (message (format
	      "Marked %s as %s."
	      (slirm--bibtex-get-field "=key=" entry)
	      verdict))))

(defun slirm--to-review-list (entry)
  "Return reviews in ENTRY as a list of pairs."
  (let ((reviews (slirm--bibtex-get-field slirm--review entry)))
    (when reviews
      (mapcar (lambda (s)
		(split-string s ":\s+"))
	      (split-string reviews ",\s+" t)))))

(defun slirm--to-review-string (reviews)
  "Return REVIEWS as a nicely formatted string."
  (string-join
   (mapcar (lambda (ss)
	     (format "%s: %s" (car ss) (car (cdr ss))))
	   reviews)
   ", "))

(defun slirm--format-verdict (verdict)
  "Formats VERDICT as \"VERDICT <timestamp>\"."
  (format "%s \<%s\>" verdict (format-time-string "%Y-%m-%d %T")))

(defun slirm--set-review (reviews verdict)
  "Set the current user's review in REVIEWS to VERDICT or append to the end of the list."
  (if reviews
      (let ((head (car reviews))
	    (tail (cdr reviews)))
	(if (string-equal (car head) user-login-name) ;; Current first entry is of this user.
	    (cons (list user-login-name (slirm--format-verdict verdict)) tail) ;; Exchange it for new one.
	  (cons head (slirm--set-review verdict tail)))) ;; Else keep and recurse.
    (list (list user-login-name (slirm--format-verdict verdict)))))

(defun slirm-accept ()
  "Mark current entry as accepted."
  (interactive)
  (slirm--with-bibtex-buffer
    (slirm--bibtex-mark-reviewed (slirm--bibtex-reparse) slirm--accept)))

(defun slirm-reject ()
  "Mark current entry as rejected."
  (interactive)
  (slirm--with-bibtex-buffer
    (slirm--bibtex-mark-reviewed (slirm--bibtex-reparse) slirm--reject)))

(defun slirm--clear ()
  "Clear current slirm buffer."
  (delete-region (point-min) (point-max)))

(defun slirm--insert-title (title)
  "Insert and format TITLE at point."
  (let ((ttitle (format "%s:" title)))
    (put-text-property 0 (length ttitle) 'face 'bold ttitle)
    (insert ttitle)))

(defun slirm--insert-paragraph (title text)
  "Insert and format a paragraph with TITLE as header and TEXT as body."
  (when text
    (slirm--insert-title title)
    (insert (format " %s" (replace-regexp-in-string "[\s\t\n\r]+" " " text)))
    (fill-paragraph t)
    (slirm--insert-newline)
    (slirm--insert-newline)))

(defun slirm--insert-line (title text)
  "Insert text as TITLE: TEXT without further formatting."
  (slirm--insert-title title)
  (insert (format " %s" text))
  (slirm--insert-newline)
  (slirm--insert-newline))

(defun slirm--insert-newline ()
  "Insert a newlines."
  (insert "\n"))

(defun slirm--insert-indent (indent text)
  "Insert a line indented by INDENT spaces, containing TEXT."
  (when text
    (insert (format "%s%s" (make-string indent ? ) text))))

(defun slirm--show (entry)
  "Show ENTRY in the review buffer."
  (slirm--override-readonly
    (slirm--clear)
    (save-excursion
      (slirm--insert-paragraph "Title" (slirm--replace-html-chars (slirm--bibtex-get-field "title" entry)))
      (slirm--insert-paragraph "Author(s)" (slirm--bibtex-get-field "author" entry))
      (slirm--insert-paragraph "Editor(s)" (slirm--bibtex-get-field "editor" entry))
      (slirm--insert-line "Year" (slirm--bibtex-get-field "year" entry))
      (slirm--insert-paragraph "In" (or (slirm--bibtex-get-field "booktitle" entry)
					(slirm--bibtex-get-field "journal" entry)))
      (slirm--insert-paragraph "Abstract" (slirm--bibtex-get-field "abstract" entry))
      (slirm--insert-paragraph "Source" (slirm--bibtex-get-field "source" entry))
      (slirm--insert-paragraph "Keywords" (slirm--bibtex-get-field "keywords" entry))
      (let ((reviews (slirm--to-review-list entry)))
	(when reviews
	  (slirm--insert-line "Reviews" "")
	  (dolist (review reviews)
	    (slirm--insert-indent 2 (format "%s: %s\n" (car review ) (nth 1 review))))
	  (slirm--insert-newline)))
      (slirm--insert-paragraph "Notes" (slirm--bibtex-get-field "notes" entry)))))

(defun slirm--update-and-show (entry)
  "Show ENTRY in the review buffer after update."
  (slirm--show
   (slirm--with-bibtex-buffer
     (slirm--bibtex-update-abstract-full-text-url entry)
     (slirm--bibtex-reparse))))

(defun slirm-show-next ()
  "Show the next entry in the review buffer."
  (interactive)
  (slirm--update-and-show (slirm--with-bibtex-buffer
			    (slirm--bibtex-parse-next))))

(defun slirm-show-prev ()
  "Show the previous entry in the review buffer."
  (interactive)
  (slirm--update-and-show (slirm--with-bibtex-buffer
			    (slirm--bibtex-parse-prev))))

(defun slirm--bibtex-find-next-entry (predicate)
  "Find next entry for which PREDICATE does not hold or the last entry in the file."
  (let ((entry (slirm--bibtex-parse-next)))
    (while (and (funcall predicate entry)
		(< (- (point) (point-max)) 3))
      (setq entry (slirm--bibtex-parse-next)))
    entry))

(defun slirm--reviewed? (entry)
  "Non-nil if ENTRY is already reviewed by current user."
  (let ((review (slirm--bibtex-get-field slirm--review entry)))
    (when review
      (string-match user-login-name review))))

(defun slirm--bibtex-find-next-undecided ()
  "Return next undecided entry or the last entry in the list."
  (slirm--bibtex-find-next-entry 'slirm--reviewed?))

(defun slirm-show-next-undecided ()
  "Show next undecided entry after current point."
  (interactive)
  (slirm--update-and-show
   (slirm--with-bibtex-buffer
    (slirm--bibtex-find-next-undecided))))

(defun slirm-show-first-undecided ()
  "Show the first not yet annotated entry."
  (interactive)
  (slirm--update-and-show
   (slirm--with-bibtex-buffer
     (goto-char 0)
     (slirm--bibtex-find-next-undecided))))

(defun slirm-accept-or-reject ()
  "Choose whether to accept or reject entry and continue to next undecided."
  (interactive)
  (if (yes-or-no-p "Accept current entry? ")
      (slirm-accept)
    (slirm-reject))
  (slirm-show-next-undecided))

(defun slirm--make-relative (path)
  "Make PATH relative to BibTeX file directory."
  (file-relative-name (file-name-directory slirm--bibtex-file) path))

(defun slirm--make-absolute (path)
  "Make PATH absolute."
  (if (file-name-absolute-p path)
      path
    (concat (file-name-directory slirm--bibtex-file) path)))

(defun slirm--gen-filename (entry)
  "Generate a file name for ENTRY's full text file."
  (let ((author (car (split-string (slirm--bibtex-get-field "author" entry) ",\s*")))
	(year (slirm--bibtex-get-field "year" entry))
	(title-elems (split-string (slirm--bibtex-get-field "title" entry) "[^a-zA-Z0-9]")))
    (format "%s_%s_%s-%s.pdf" author year (nth 0 title-elems) (nth 1 title-elems))))

(defun slirm--filepath (file)
  "Return the full file path for FILE."
  (concat
   (file-name-as-directory ".slirm_cache")
   (directory-file-name file)))

(defun slirm--download-full-text (entry filepath)
  "Download the full text for ENTRY if possible.
The full text is stored in FILEPATH if non-nil, otherwise a
filename is generated based on the entry.  Generated files are
always stored in .slirm-cache/."
  (unless filepath
    (setq filepath (slirm--filepath (slirm--gen-filename entry))))
  (let* ((filepath-abs (slirm--make-absolute filepath))
	 (dir (file-name-directory filepath-abs))
	 (url (slirm--bibtex-get-field slirm--full-text-url entry)))
    (when url
      (unless (file-exists-p dir)
	(dired-create-directory dir))
      (when (or (file-exists-p filepath-abs) (url-copy-file url filepath-abs))
	(slirm--with-bibtex-buffer
	  (slirm--bibtex-maybe-write-to-field slirm--full-text-file entry filepath)
	  (save-buffer))
	filepath))))

(defun slirm-show-full-text ()
  "Show full text if cached, try downloading otherwise."
  (interactive)
  (let* ((entry (slirm--with-bibtex-buffer
		  (slirm--bibtex-reparse)))
	 (file (slirm--bibtex-get-field slirm--full-text-file entry)))
    (unless (and file (file-exists-p (slirm--make-absolute file)))
      (setq file (slirm--download-full-text entry file)))
    (if file
	(pop-to-buffer (save-window-excursion
			 (find-file (slirm--make-absolute file))))
      (message "Cannot download, current entry has no full text URL."))))

(defun slirm-edit-notes ()
  "Edit the notes field of the current entry."
  (interactive)
  (let* ((entry (slirm--with-bibtex-buffer
		  (slirm--bibtex-reparse)))
	 (notes-old (slirm--bibtex-get-field "notes" entry))
	 (notes-new (read-string "Edit notes: " notes-old)))
    (slirm--with-bibtex-buffer
      (if notes-old
	  (slirm--bibtex-kill-field "notes")
	(slirm--bibtex-add-field "notes"))
      (slirm--bibtex-write-to-field "notes" notes-new))
    (slirm--show (slirm--with-bibtex-buffer
		   (slirm--bibtex-reparse)))))

(require 'browse-url)

(defun slirm-browse-url ()
  "Open the current publication's url in a browser."
  (interactive)
  (let* ((entry (slirm--with-bibtex-buffer (slirm--bibtex-reparse)))
	 (url (slirm--bibtex-get-field "url" entry)))
    (if url
	(browse-url-default-browser url)
      (message "Current entry has no URL, cannot open it."))))

(defun slirm-count-entries ()
  "Count entries and display in minibuffer."
  (interactive)
  (let ((seen nil)
	(all 0)
	(unique 0)
	(remaining 0))
    (slirm--for-all-entries-do
      (let* ((entry (slirm--bibtex-parse))
	     (key (split-string (slirm--bibtex-get-field "=key=" entry) ":"))
	     (id (format "%s:%s:%s" (nth 0 key) (nth 1 key) (nth 2 key))))
	(unless (member id seen)
	  (setq seen (cons id seen)
		unique (1+ unique)))
	(setq all (1+ all))
	(unless (slirm--reviewed? entry)
	  (setq remaining (1+ remaining)))))
    (message (format "Counting %d entries of which %d unique and %s not yet reviewed." all unique remaining))))

(defun slirm--find-entries (predicate)
  "Find all entries for which PREDICATE holds."
  (let ((entries nil))
    (slirm--for-all-entries-do
      (let ((entry (slirm--bibtex-parse)))
	(when (funcall predicate entry)
	  (setq entries (cons entry entries)))))
    entries))

(defun count-if (lst predicate)
  "Count the number of items in LST that satisfy PREDICATE."
  (if lst
      (let ((head (car lst))
	    (tail (cdr lst)))
	(if (funcall predicate head)
	    (1+ (count-if tail predicate))
	  (count-if tail predicate)))
    0))

(defun slirm--count-positive-reviews (entry)
  "Count the number of positive reviews of ENTRY."
  (let ((reviews (slirm--to-review-list entry)))
    (count-if reviews
	      (lambda (review)
		(string-match slirm--accept (nth 1 review))))))

(defun slirm-export-accepted ()
  "Export all accepted entries.  Promts for a minimum number of positive reviews."
  (interactive)
  (let* ((min-reviews (read-number "Mimimun number of positive reviews: " 1))
	 (predicate (lambda (entry) (<= min-reviews (slirm--count-positive-reviews entry))))
	 (entries (slirm--find-entries predicate))
	 (default (format "%s-accepted.bib" (file-name-sans-extension (file-name-base slirm--bibtex-file))))
	 (filename (read-file-name "Write to: " nil nil nil (slirm--make-absolute default) nil)))
    (with-current-buffer (get-buffer-create filename)
      (save-excursion
	(dolist (entry entries)
	  (slirm--bibtex-write entry)))
      (bibtex-mode)
      (write-file filename)
      (pop-to-buffer (current-buffer)))))

(defun slirm-delete-reviews ()
  "Delete all reviews from current BibTeX file."
  (interactive)
  (when (yes-or-no-p (format "Really delete all reviews from %s and save? " slirm--bibtex-file))
    (slirm--for-all-entries-do
      (when (slirm--bibtex-get-field slirm--review (slirm--bibtex-parse))
	(slirm--bibtex-kill-field slirm--review)))))

(defun slirm--bibtex-buffer ()
  "Return the buffer containing the BibTeX file."
  (save-window-excursion
    (let ((other (find-file-existing slirm--bibtex-file)))
      (bury-buffer other)
      other)))

;;;###autoload
(defun slirm-start ()
  "Start a systematic literature review of the BibTeX file in the current buffer."
  (interactive)
  (let* ((current-file (when (string-equal (file-name-extension (buffer-name)) "bib")
			 (buffer-file-name)))
	 (file (expand-file-name (read-file-name "Open a bibliography to review: " nil nil nil current-file nil))))
    (switch-to-buffer (get-buffer-create (format "*Review of %s*" (file-name-nondirectory file))))
    (setq slirm--bibtex-file-tmp file)
    (slirm-mode)))

(define-derived-mode slirm-mode special-mode
  "Systematic Literature Review Mode."
  (setq slirm--bibtex-file slirm--bibtex-file-tmp)
  (bury-buffer (slirm--bibtex-buffer))
  (slirm-show-first-undecided))

(define-key slirm-mode-map (kbd "n") 'slirm-show-next)
(define-key slirm-mode-map (kbd "C-n") 'slirm-show-next-undecided)
(define-key slirm-mode-map (kbd "p") 'slirm-show-prev)
(define-key slirm-mode-map (kbd "C-f") 'slirm-show-first-undecided)
(define-key slirm-mode-map (kbd "SPC") 'slirm-accept-or-reject)
(define-key slirm-mode-map (kbd "C-c C-t") 'slirm-show-full-text)
(define-key slirm-mode-map (kbd "C-c C-n") 'slirm-edit-notes)
(define-key slirm-mode-map (kbd "C-c C-u") 'slirm-browse-url)

(provide 'slirm)
;;; slirm.el ends here
