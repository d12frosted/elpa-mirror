;;; babel.el --- interface to web translation services such as Babelfish


;; Author: Juergen Hoetzel <juergen@hoetzel.info>
;;         Eric Marsden <emarsden@laas.fr>
;; URL: http://github.com/juergenhoetzel/babel
;; Package-Version: 20201210.1626
;; Package-Commit: 5db131f1edb85a31202fd77ed2fb8f68c0233845
;; Version: 1.4
;; Keywords: translation, web

;;
;;     This program is free software; you can redistribute it and/or
;;     modify it under the terms of the GNU General Public License as
;;     published by the Free Software Foundation; either version 2 of
;;     the License, or (at your option) any later version.
;;
;;     This program is distributed in the hope that it will be useful,
;;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;;     GNU General Public License for more details.
;;
;;     You should have received a copy of the GNU General Public
;;     License along with this program; if not, write to the Free
;;     Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
;;     MA 02111-1307, USA.
;;
;; Please send suggestions and bug reports to <juergen@hoetzel.info>.
;; The latest version of this package should be available at
;;
;;     http://github.com/juergenhoetzel/babel/tree/master

;;; Commentary:

;;; Overview ==========================================================
;;
;; This module provides an Emacs interface to different translation
;; services available on the Internet. You give it a word or paragraph
;; to translate and select the source and destination languages, and
;; it connects to the translation server, retrieves the data, and
;; presents it in a special *babel* buffer. Currently the following
;; backends are available:
;;
;;  * the FOSS MT platform Apertium
;;  * the Google service at translate.google.com
;;  * the Transparent Language motor at FreeTranslation.com

;;
;; Entry points: either 'M-x babel', which prompts for a phrase, a
;; language pair and a backend, or 'M-x babel-region', which prompts
;; for a language pair and backend, then translates the currently
;; selected region, and 'M-x babel-buffer' to translate the current
;; buffer.
;;

;; If you ask for a language combination which several backends could
;; translate, babel.el will allow you to choose which backend to
;; use. Since most servers have limits on the quantity of text
;; translated, babel.el will split long requests into translatable
;; chunks and submit them sequentially.
;;
;; Please note that the washing process (which takes the raw HTML
;; returned by a translation server and attempts to extract the useful
;; information) is fragile, and can easily be broken by a change in
;; the server's output format. In that case, check whether a new
;; version is available (and if not, warn me; I don't translate into
;; Welsh very often).
;;
;; Also note that by accessing an online translation service you are
;; bound by its Terms and Conditions; in particular
;; FreeTranslation.com is for "personal, non-commercial use only".
;;
;;
;; Installation ========================================================
;;
;; Place this file in a directory in your load-path (to see a list of
;; appropriate directories, type 'C-h v load-path RET'). Optionally
;; byte-compile the file (for example using the 'B' key when the
;; cursor is on the filename in a dired buffer). Then add the
;; following lines to your ~/.emacs.el initialization file:
;;
;;   (autoload 'babel "babel"
;;     "Use a web translation service to translate the message MSG." t)
;;   (autoload 'babel-region "babel"
;;     "Use a web translation service to translate the current region." t)
;;   (autoload 'babel-as-string "babel"
;;     "Use a web translation service to translate MSG, returning a string." t)
;;   (autoload 'babel-buffer "babel"
;;     "Use a web translation service to translate the current buffer." t)
;;
;; babel.el requires emacs >= 23
;;
;;
;; Backend information =================================================
;;
;; A babel backend named <zob> must provide three functions:
;;
;;    (babel-<zob>-translation from to)
;;
;;    where FROM and TO are three-letter language abbreviations from
;;    the alist `babel-languages'. This should return non-nil if the
;;    backend is capable of translating between these two languages.
;;
;;    (babel-<zob>-fetch msg from to)
;;
;;    where FROM and TO are as above, and MSG is the text to
;;    translate. Connect to the appropriate server and fetch the raw
;;    HTML corresponding to the request.
;;
;;    (babel-<zob>-wash)
;;
;;    When called on a buffer containing the raw HTML provided by the
;;    server, remove all the uninteresting text and HTML markup.
;;
;; I would be glad to incorporate backends for new translation servers
;; which are accessible to the general public.
;;
;; babel.el was inspired by a posting to the ding list by Steinar Bang
;; <sb@metis.no>. Morten Eriksen <mortene@sim.no> provided several
;; patches to improve InterTrans washing. Thanks to Per Abrahamsen and
;; Thomas Lofgren for pointing out a bug in the keymap code. Matt
;; Hodges <pczmph@unix.ccc.nottingham.ac.uk> suggested ignoring case
;; on completion. Colin Marquardt suggested
;; `babel-preferred-to-language'. David Masterson suggested adding a
;; menu item. Andy Stewart provided
;; `babel-remember-window-configuration' functionality, output window
;; adjustments and more improvements.
;;
;; User quotes: Dieses ist die größte Sache seit geschnittenem Brot.
;;                 -- Stainless Steel Rat <ratinox@peorth.gweep.net>

;;; History

;;    Discontinued Log (Use GIT: git://github.com/juergenhoetzel/babel.git)

;;    1.4 * `babel-region' now yank the translation instead insert him at
;;          point.

;;    1.3 n* Added new Google languages

;;    1.2 * Added FOSS MT platform Apertium
;;         (by Kevin Brubeck Unhammer)
;;	  * Assume UTF-8, if HTTP header missing

;;    1.1 * Fixed invalid language code mapping for serveral
;;          languages

;;    1.0 * Fixed Google backend (new regex)
;;        * New custom variables `babel-buffer-name',
;;         `babel-echo-area', `babel-select-output-window'
;;        * Disable use of echo area usage on xemacs if lines > 1
;;          (resize of minibuffer does not work reliable)
;;        * `babel-url-retrieve' fix for xemacs from Uwe Brauer

;;    0.9  * Use `babel-buffer-name' for output buffer

;;    0.8  * Remember window config if `babel-remember-window-configuration'
;;           is non-nil.
;;         * made *babel* buffer read-only
;;         * use echo area (like `shell-command')
;;         * New functions `babel-as-string-default',`babel-region-default',
;;           `babel-buffer-default', `babel-smart' (provided by Andy)


;;    0.7  * error handling if no backend is available for translating
;;           the supplied languages
;;	   * rely on url-* functions (for charset decoding) on GNU emacs
;;         * increased chunk size for better performance
;;         * added support for all Google languages
;;         * `babel-region' with prefix argument inserts the translation
;;            output at point.

;;    0.6  * get rid of w3-region (implementend basic html entity parsing)
;;         * get rid of w3-form-encode-xwfu (using mm-url-form-encode-xwfu)
;;         * no character classes in regex (for xemacs compatibility)
;;         * default backend: Google

;;    0.5: * Fixed Google and Babelfish backends

;;    0.4: * revised FreeTranslation backend

;;;   0.3: * removed non-working backends: systran, intertrans, leo, e-PROMPT
;;;        * added Google backend
;;;        * revised UTF-8 handling
;;;        * Added customizable variables: babel-preferred-to-language, babel-preferred-from-language
;;;        * revised history handling
;;;        * added helper function: babel-wash-regex


;; TODO:
;;
;; * select multiple engines at once
;;
;; * Adjust output window height. Current versions use
;;  `with-current-buffer' instead `with-output-to-temp-buffer'. So
;;  `temp-buffer-show-hook' will fail to adjust output window height
;;  -> Use (fit-window-to-buffer nil babel-max-window-height) to
;;  adjust output window height in new version.
;;
;; * use non-blocking `url-retrieve'
;;
;; * improve function `babel-simple-html-parse'.
;;
;; * In `babel-quite' function, should be add (boundp
;;   'babel-previous-window-configuration) to make value of
;;   `babel-previous-window-configuration' is valid
;;

;;; Code:

(require 'cl)
(require 'mm-url)
(require 'json)
(require 'easymenu)

;; xemacs compatibility
(eval-and-compile
  (when (featurep 'xemacs)
    (defun url-retrieve-synchronously (url)
      (save-excursion
	(cdr (url-retrieve url))))))

;; ======================================================================
;;; Customizables
;; ======================================================================
(defgroup babel nil
  "provides an Emacs interface to different translation services available on the Internet"
  :group 'applications)


(defconst babel-version "1.4"
  "The version number of babel.el")

(defconst babel-languages
  '(("Afrikaans" . "af")
    ("Albanian" . "sq")
    ("Arabic" . "ar")
    ("Belarusian" . "be")
    ("Bulgarian" . "bg")
    ("Catalan" . "ca")
    ("Chinese" . "zh")
    ("Chinese (trad.)" . "zt")
    ("Croatian" . "hr")
    ("Czech" . "cs")
    ("Danish" . "da")
    ("Dutch" . "nl")
    ("English" . "en")
    ("Estonian" . "et")
    ("Filipino" . "tl")
    ("Finnish" . "fi")
    ("French" . "fr")
    ("Galician" . "gl")
    ("German" . "de")
    ("Greek" . "el")
    ("Hebrew" . "iw")
    ("Hindi" . "hi")
    ("Hungarian" . "hu")
    ("Icelandic" . "is")
    ("Indonesian" . "id")
    ("Irish" . "ga")
    ("Italian" . "it")
    ("Japanese" . "ja")
    ("Korean" . "ko")
    ("Latvian" . "lv")
    ("Lithuanian" . "lt")
    ("Macedonian" . "mk")
    ("Malay" . "ms")
    ("Maltese" . "mt")
    ("Norwegian" . "no")
    ("Persian" . "fa")
    ("Polish" . "pl")
    ("Portuguese" . "pt")
    ("Romanian" . "ro")
    ("Russian" . "ru")
    ("Serbian" . "sr")
    ("Slovak" . "sk")
    ("Slovenian" . "sl")
    ("Spanish" . "es")
    ("Swahili" . "sw")
    ("Swedish" . "sv")
    ("Thai" . "th")
    ("Turkish" . "tr")
    ("Ukrainian" . "uk")
    ("Vietnamese" . "vi")
    ("Welsh" . "cy")
    ("Yiddish" . "yi")))

(defcustom babel-preferred-to-language "German"
  "*Default target translation language.
This must be the long name of one of the languages in the alist"
  :type `(choice ,@(mapcar (lambda (s) `(const ,(car s))) babel-languages))
  :set (lambda (symbol value)
	 (set-default symbol value)
	 (setq babel-to-history (list value)))
  :group 'babel)

(defcustom babel-preferred-from-language "English"
  "*Default target translation language.
This must be the long name of one of the languages in the alist"
  :type `(choice ,@(mapcar (lambda (s) `(const ,(car s))) babel-languages))
  :set (lambda (symbol value)
	 (set-default symbol value)
	 (setq babel-from-history (list value)))
  :group 'babel)


(defcustom babel-remember-window-configuration t
  "Whether to remember window configuration before transform.  If this
variable is t, will use `babel-quit' command restore window
configuration."
  :type 'boolean
  :group 'babel)

(defcustom babel-max-window-height 30
  "The max height that babel output window."
  :type 'integer
  :group 'babel)



(defcustom babel-buffer-name "*babel*"
  "The buffer name of `babel' transform output."
  :type 'string
  :group 'babel)

(defcustom babel-echo-area t
  "If this option is `non-nil' and the output is short enough to
 display in the echo area (which is determined by the variables
 `resize-mini-windows' and `max-mini-window-height'), it is shown in
 echo area.

 Default is `t'."
  :type 'boolean
  :group 'babel)

(defcustom babel-select-output-window t
  "Select output window after transform complete.
 This is useful when you have a complex window layout.
 Save you time to switch babel output window."
   :type 'boolean
   :group 'babel)

(defcustom babel-google-translate-api-key
  nil
  "Google translate api key."
  :type 'string
  :group 'babel)

(defcustom babel-default-chunksize 7000
  "The maximum length of a chunk sent to a translation backend."
  :type 'number
  :group 'babel)

(defvar babel-previous-window-configuration nil
  "The window configuration before transform.")

(defvar babel-to-history (list babel-preferred-to-language))
(defvar babel-from-history (list babel-preferred-to-language))
(defvar babel-backend-history (list))

(defvar babel-mode-hook nil)

(defvar babel-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q")     #'bury-buffer)
    (define-key map (kbd "SPC")   #'scroll-up)
    (define-key map (kbd "DEL")   #'scroll-down)
    (define-key map (kbd "<")   #'beginning-of-buffer)
    (define-key map (kbd ">")   #'end-of-buffer)
    (define-key map (kbd "s")   #'isearch-forward)
    (define-key map (kbd "r")   #'isearch-backward)
    (define-key map (kbd "h")   #'describe-mode)
    map)
  "Keymap used in Babel mode.")

(defvar babel-backends
  '(("Google" . google)
    ("FreeTranslation" . free)
    ("Apertium" .  apertium))
  "List of backends for babel translations.")

(defun babel-sentence-end()
  "portability function. emacs 22.0.50 introduced sentence-end
function, not available on other emacsen"
  (if (fboundp 'sentence-end)
      (sentence-end)
    sentence-end))

;; xemacs compatibility
(eval-and-compile
  (if (featurep 'xemacs)
      ;; XEmacs
      (defun babel-url-retrieve (url)
	"Retrieve URL and decode"
	(let ((current (current-buffer))
	      (tmp (url-retrieve-synchronously url)))
	  (with-current-buffer tmp
	    ;;shrug: we asume utf8
	    (decode-coding-region (point-min) (point-max) 'utf-8)
	    (copy-to-buffer current (point-min) (point-max)))
	  (kill-buffer tmp)))
    ;; GNUs Emacs
    (require 'url-handlers)
    (defun babel-url-retrieve (url)  ;; return a buffer
      (let* ((url-show-status nil)
	     (tmp (url-retrieve-synchronously url)))
	(unless (cadr (url-insert tmp))
	  (mm-decode-coding-region (point-min) (point-max) 'utf-8))
	(kill-buffer tmp)))))

(defun babel-wash-regex (regex)
  "Extract the useful information from the HTML returned by fetch function
translated text should be inside parenthesized expression in regex"
  (goto-char (point-min))
  (if (search-forward-regexp regex (point-max) t)
      (progn
	(delete-region (match-end 1) (point-max))
	(delete-region (point-min) (match-beginning 1))
	t)))

(defun babel-string (msg from to service)
  "Translate MSG between language codes FROM, TO using the backend SERVICE."
  (let* ((backend (symbol-name service))
         (fetcher (intern (concat "babel-" backend "-fetch")))
         (washer  (intern (concat "babel-" backend "-wash"))))
    (loop for chunk in (babel-chunkify msg)
          collect (babel-work chunk from to fetcher washer)
          into translated-chunks
          finally (return (apply #'concat translated-chunks)))))

;;;###autoload
(defun babel (msg &optional no-display accept-default-setup)
  "Use a web translation service to translate the message MSG.
Display the result in a buffer *babel* unless the optional argument
NO-DISPLAY is nil.

If the output is short enough to display in the echo area (which is
determined by the variables `resize-mini-windows' and
`max-mini-window-height'), it is shown there, but it is nonetheless
available in buffer `*babel*' even though that buffer is not
automatically displayed."
  (interactive "sTranslate phrase: ")
  (let* ((completion-ignore-case t)
         (from-suggest (or (first babel-from-history) (caar babel-languages)))
         (from-long
          (if accept-default-setup
              babel-preferred-from-language
            (completing-read (format "Translate from (%s): " from-suggest)
                             babel-languages nil t
                             nil
                             'babel-from-history
			     from-suggest)))
         (to-avail (remove* from-long babel-languages
                            :test #'(lambda (a b) (string= a (car b)))))
         (to-suggest (or (first
			  (remove* from-long babel-to-history
				   :test #'string=))
			 (caar to-avail)))
         (to-long
          (if accept-default-setup
              babel-preferred-to-language
            (completing-read (format "Translate to (%s): "  to-suggest)
			     to-avail nil t
                             nil
                             'babel-to-history
			     to-suggest)))
         (from (cdr (assoc from-long babel-languages)))
         (to   (cdr (assoc to-long babel-languages)))
         (backends (babel-get-backends from to)))
    (if (not backends)
	(error "No Backend available for translating %s to %s"
	       from-long to-long)
      (let* ((backend-str
              (if accept-default-setup (caar backends)
                (completing-read "Using translation service: "
                                 backends nil t
                                 (cons (or (member (first babel-backend-history)
                                                   backends) (caar backends)) 0)
                                 'babel-backend-history)))
	     (backend (symbol-name (cdr (assoc backend-str babel-backends))))
	     (fetcher (intern (concat "babel-" backend "-fetch")))
	     (washer  (intern (concat "babel-" backend "-wash")))
	     (chunks (babel-chunkify msg))
	     (translated-chunks '())
	     (view-read-only nil))
	(loop for chunk in chunks
	      do (push (babel-work chunk from to fetcher washer)
		       translated-chunks))
	(if no-display
	    (apply #'concat (nreverse translated-chunks))
	  (let ((pop-up-frames nil)
                (temp-buffer-show-hook
                 '(lambda ()
                    (fit-window-to-buffer nil babel-max-window-height)
                    (shrink-window-if-larger-than-buffer))))
	    (if (and babel-remember-window-configuration
		     (null babel-previous-window-configuration))
                (setq babel-previous-window-configuration (current-window-configuration)))
            (with-current-buffer
		(get-buffer-create babel-buffer-name) ;; if not exists, create it
	      ;; ensure buffer is writeable
	      (setq buffer-read-only nil)
	      (erase-buffer)
              (loop for tc in (nreverse translated-chunks)
                    do (insert tc))
              (save-excursion
                (with-current-buffer babel-buffer-name
		  (let ((lines
			 (if (= (buffer-size) 0)
			     0
			   ;; xemacs compatibility
			   (if (not (featurep 'xemacs))
			       (count-screen-lines nil nil nil (minibuffer-window))
			     (count-lines (point-min) (point-max))))))
		    (babel-mode)
		    (cond ((= lines 0))
			  ((and babel-echo-area (or (<= lines 1)
				    (and (not (featurep 'xemacs))
					 (<= lines
					     (if resize-mini-windows
						 (cond ((floatp max-mini-window-height)
							(* (frame-height)
							   max-mini-window-height))
						       ((integerp max-mini-window-height)
							max-mini-window-height)
						       (t
							1))
					       1))))
				;; Don't use the echo area if the output buffer is
				;; already dispayed in the selected frame.
				(not (get-buffer-window (current-buffer))))
			   ;; Echo area
			   (goto-char (point-max))
			   (when (bolp)
			     (backward-char 1))
			   (message "%s" (buffer-substring (point-min) (point))))
			  (t
			   ;; Buffer
			   (goto-char (point-min))
			   (display-buffer (current-buffer))))))))))))))

(defun babel-as-string-default (msg)
     "Use a web translation service to translate MSG, returning a string."
     (interactive "sTranslate phrase: ")
     (babel msg t t))

(defun babel-region-default (start end &optional arg)
  "Use a web translation service to translate the current region.
 With prefix argument, yank the translation to the kill-ring."
  (interactive "r\nP")
  (if arg
      (kill-new (babel (buffer-substring-no-properties start end) t))
    (babel (buffer-substring-no-properties start end) nil t)))

(defun babel-buffer-default ()
  "Use a web translation service to translate the current buffer.
 Default is to present the translated text in a *babel* buffer.
 With a prefix argument, replace the current buffer contents by the
 translated text."
  (interactive)
  (let (pos)
    (cond (prefix-arg
	   (setq pos (point-max))
	   (goto-char pos)
	   (insert
	    (babel-as-string-default
	     (buffer-substring-no-properties (point-min) (point-max))))
	   (delete-region (point-min) pos))
	  (t
	   (babel-region-default (point-min) (point-max))))))

 (defun babel-smart (&optional prefix)
   "Smart babel function.  If you use prefix keystroke, prompt with
 input. Same effect with `babel'.  If mark active with current buffer,
 transform region. Same effect with `babel-region'.  Otherwise
 transform all content of current buffer. Same effect with
 `babel-buffer'."
   (interactive "P")
   (if (null prefix)
       (if mark-active
           (babel-region-default (region-beginning) (region-end) 'yank)
         (babel-buffer-default))
     (babel (read-string "Translate phrase: ") nil t)))

(defun babel-word ()
"translate word under cursor use a web service, use preferred settings"
(interactive)
(let (
      (word (thing-at-point 'word))
      )
  (if word
  (babel word nil t))))

(defun babel-quit ()
  "Quit babel window.  If `babel-remember-window-configuration' is t,
restore window configuration before transform.  Otherwise just do
`bury-buffer'."
  (interactive)
  (if (and babel-remember-window-configuration
           babel-previous-window-configuration)
      (progn
        (kill-buffer (get-buffer babel-buffer-name))
        (set-window-configuration babel-previous-window-configuration)
        (setq babel-previous-window-configuration nil))
    (bury-buffer)))

;;;###autoload
(defun babel-region (start end &optional arg)
  "Use a web translation service to translate the current region.
With prefix argument, yank the translation to the kill-ring."
  (interactive "r\nP")
  (if arg
      (kill-new (babel (buffer-substring-no-properties start end) t))
    (babel (buffer-substring-no-properties start end))))

;;;###autoload
(defun babel-as-string (msg)
  "Use a web translation service to translate MSG, returning a string."
  (interactive "sTranslate phrase: ")
  (babel msg t))

;; suggested by Djalil Chafai <djalil@free.fr>
;;
;;;###autoload
(defun babel-buffer ()
  "Use a web translation service to translate the current buffer.
Default is to present the translated text in a *babel* buffer.
With a prefix argument, replace the current buffer contents by the
translated text."
  (interactive)
  (let (pos)
    (cond (prefix-arg
           (setq pos (point-max))
           (goto-char pos)
           (insert
            (babel-as-string
             (buffer-substring-no-properties (point-min) (point-max))))
           (delete-region (point-min) pos))
          (t
           (babel-region (point-min) (point-max))))))
;;;do the real work
(defun babel-work (msg from to fetcher washer)
  (with-temp-buffer
    (funcall fetcher (babel-preprocess msg) from to)
    (funcall washer)
    (babel-postprocess)
    (babel-simple-html-parse)
    (babel-display)
    (buffer-substring-no-properties (point-min) (point-max))))

(defun babel-get-backends (from to)
  "Return a list of those backends which are capable of translating
language FROM into language TO."
  (loop for b in babel-backends
        for name = (symbol-name (cdr b))
        for translator = (intern (concat "babel-" name "-translation"))
        for translatable = (funcall translator from to)
        if translatable collect b))


(defconst babel-html-entity-regex
  "&\\(#\\([0-9]+\\)\\|\\([a-zA-Z]+\\)\\);")

(defun babel-decode-html-entitiy (str)
  (if (and str (string-match babel-html-entity-regex
			     str))
      (if (string= (substring str 1 2) "#")
	  ;TODO: xemacs
	  (if (not (featurep 'xemacs))
	      (let ((number (match-string-no-properties 2 str)))
		(decode-char 'ucs (string-to-number number)))
	    str)
	(let ((letter (match-string-no-properties 3 str)))
	  (cond ((string= "gt" letter) ">")
		((string= "lt" letter) "<")
		(t "?"))))))

(defun babel-display ()
  "Parse and display the region of this for basic HTML entities."
  (save-excursion
    (goto-char (point-min))
    (while (and (< (point) (point-max)) (search-forward-regexp
					 babel-html-entity-regex
					 (point-max) t))
      (let* ((start (match-beginning 0))
	     (end (match-end 0))
	     (entity (buffer-substring start end))
	     (replacement (babel-decode-html-entitiy entity)))
	(delete-region start end)
	(insert replacement)))))

(defun babel-mode ()
  (interactive)
  (kill-all-local-variables)
  (use-local-map babel-mode-map)
  (setq major-mode 'babel-mode
        mode-name "Babel"
	buffer-read-only t)
  (buffer-disable-undo)
  (run-hooks 'babel-mode-hook))

(cond ((fboundp 'string-make-unibyte)
       (fset 'babel-make-unibyte #'string-make-unibyte))
      ((fboundp 'string-as-unibyte)
       (fset 'babel-make-unibyte #'string-as-unibyte))
      (t
       (fset 'babel-make-unibyte #'identity)))

;; from nnweb.el, with added `string-make-unibyte'.
(defun babel-form-encode (pairs)
  "Return PAIRS encoded for forms."
  (mapconcat
   (lambda (data)
     (concat (mm-url-form-encode-xwfu (babel-make-unibyte (car data))) "="
             (mm-url-form-encode-xwfu (babel-make-unibyte (cdr data)))))
   pairs "&"))

;; We mark paragraph endings with a special token, so that we can
;; recover a little information on the original message's format after
;; translation and washing and rendering. Should really be using
;; `paragraph-start' and `paragraph-separate' here, but we no longer
;; have any information on the major-mode of the buffer that STR was
;; ripped from.
;;
;; This kludge depends on the fact that all the translation motors
;; seem to leave words they don't know how to translate alone, passing
;; them through untouched.
(defun babel-preprocess (str)
  (while (string-match "\n\n\\|^\\s-+$" str)
    (setq str (replace-match " FLOBSiCLE " nil t str)))
  str)

;; decode paragraph endings in current buffer
(defun babel-postprocess ()
  (goto-char (point-min))
  (while (search-forward "FLOBSiCLE" nil t)
    (replace-match "\n<p>" nil t)))

(defun babel-simple-html-parse ()
  "Replace basic html markup"
  (goto-char (point-min))
  (while (re-search-forward  "<\\(br\\|p\\)/?>" nil t)
    (replace-match "\n"))
  (goto-char (point-min))
  (while (re-search-forward  "^[ \t]+"  nil t)
    (replace-match "")))

(defun babel-chunkify (str &optional chunksize)
  "Split STR into chunks of around CHUNKSIZE characters.

   Tries to maintain sentence structure (this is used to send big requests in
   several batches, because otherwise the motors cut off the
   translation)."

  (let ((chunksize (or chunksize babel-default-chunksize))
        (start 0)
        (pos 0)
        (chunks '()))
    (while (setq pos (string-match (babel-sentence-end) str pos))
      (incf pos)
      (when (> (- pos start) chunksize)
        (push (substring str start pos) chunks)
        (setq start pos)))
    (when (/= start (length str))
      (push (substring str start) chunks))
    (nreverse chunks)))

;;;###autoload
(defun babel-version (&optional here)
  "Show the version number of babel in the minibuffer.
If optional argument HERE is non-nil, insert version number at point."
  (interactive "P")
  (let ((version-string
         (format "Babel version %s" babel-version)))
    (if here
        (insert version-string)
      (if (interactive-p)
          (message "%s" version-string)
        version-string))))


;; FreeTranslation.com stuff ===========================================

;; translation from  generic letter names to FreeTranslation names
(defconst babel-free-languages
  '(("en" . "English")
    ("de" . "German")
    ("it" . "Italian")
    ("nl" . "Dutch")
    ("pt" . "Portuguese")
    ("es" . "Spanish")
    ("no" . "Norwegian")
    ("ru" . "Russian")
    ("zh" . "SimplifiedChinese")
    ("zh" . "TraditionalChinese")
    ("fr" . "French")))

;; those inter-language translations that FreeTranslation is capable of
(defconst babel-free-translations
  '("English/Spanish" "English/French" "English/German" "English/Italian" "English/Dutch" "English/Portuguese"
    "English/Russian" "English/Norwegian" "English/SimplifiedChinese" "English/TraditionalChinese" "Spanish/English"
    "French/English" "German/English" "Italian/English" "Dutch/English" "Portuguese/English"))

(defun babel-free-translation (from to)
  (let* ((ffrom (cdr (assoc from babel-free-languages)))
         (fto   (cdr (assoc to babel-free-languages)))
         (trans (concat ffrom "/" fto)))
    (find trans babel-free-translations :test #'string=)))

(defun babel-free-fetch (msg from to)
  "Connect to the FreeTranslation server and request the translation."
  (let ((coding-system-for-read 'utf-8)
	(translation (babel-free-translation from to))
	(url "http://ets.freetranslation.com/"))
    (unless translation
      (error "FreeTranslation can't translate from %s to %s" from to))
    (let* ((pairs `(("sequence"  . "core")
                    ("mode"      . "html")
                    ("template"  . "results_en-us.htm")
                    ("srctext"   . ,msg)
		    ("charset"   . "UTF-8")
                    ("language"  . ,translation)))
           (url-request-data (babel-form-encode pairs))
	   (url-mime-accept-string "text/html")
           (url-request-method "POST")
	   (url-privacy-level '(email agent))
	   (url-mime-charset-string "utf-8")
           (url-request-extra-headers
            '(("Content-Type" . "application/x-www-form-urlencoded")
	      ("Referer" . "http://ets.freetranslation.com/"))))
      (babel-url-retrieve url))))

(defun babel-free-wash ()
  "Extract the useful information from the HTML returned by FreeTranslation."
  ;;; <textarea name="dsttext" cols="40" rows="6">hello together</textarea><br />
  (if (not (babel-wash-regex "<textarea name=\"dsttext\"[^>]+>\\([^<]*\\)</textarea>"))
      (error "FreeTranslations HTML has changed ; please look for a new version of babel.el")))


;; Google stuff ===========================================

;; Google supports all languages
(defconst babel-google-languages
  babel-languages)

(defun babel-google-translation (from to)
  ;; Google can always translate in both directions
  (find to babel-google-languages
	:test '(lambda (st el)
		 (string= (cdr el) st))))

(defun babel-google-fetch (msg from to)
  "Connect to google server and request the translation."
  ;; Google can always translate in both directions
  (if (not (find to babel-google-languages
	    :test '(lambda (st el)
		     (string= (cdr el) st))))
      (error "Google can't translate from %s to %s" from to)
    (if (not babel-google-translate-api-key)
        (error "Missing api key")
      (let* ((pairs `(("q" . ,(mm-encode-coding-string msg 'utf-8))
                      ("key" . ,babel-google-translate-api-key)
                      ;; ("source" . ,from)
                      ("target" . ,to)))
             (url-request-data (babel-form-encode pairs))
             (url-request-method "POST")
             (url-request-extra-headers
              '(("Content-Type" . "application/x-www-form-urlencoded")))
             (url-base "https://translation.googleapis.com")
             (url-path "/language/translate/v2"))
        (babel-url-retrieve  (concat url-base url-path))))))

(defun json-get (json path)
  "Traverse a json object JSON along PATH."
  (reduce (lambda (obj prop)
            (cond ((symbolp prop) (cdr (assoc prop obj)))
                  ((numberp prop) (when obj (aref obj prop)))
                  (t (error "Type not suppored: %s" prop))))
          path
          :initial-value json))

(defun babel-google-wash ()
  "Extract the useful information from the HTML returned by google."
  (beginning-of-buffer)
  (let* ((json-object-type 'alist)
	 (json-response (json-read)))
    (erase-buffer)
    (let ((resp-text (json-get json-response '(data translations 0 translatedText)))
          (err-text (json-get json-response '(error message))))
      (if resp-text
          (insert resp-text)
        (if err-text
            (error "Api error: %s" err-text)
          (error "Google API has changed ; please look for a new version of babel.el"))))))

(defconst babel-apertium-languages
  '(("English" . "en")
    ("Spanish" . "es")
    ("Esperanto" . "eo")))

 (defun babel-apertium-translation (from to)
   (member (cons from to)
	   '(("en" . "es")
	     ("es" . "en")
	     ("en" . "eo"))))

(defun babel-apertium-fetch (msg from to)
  "Connect to apertium server and request the translation."
  (if (not (babel-apertium-translation from to))
      (error "Apertium can't translate from %s to %s" from to)
     (let* ((lang-pair (concat from "-" to))
	    (pairs `(("pair" . ,lang-pair)
		     ("text" . ,msg)))
	    (request-url
	     (concat "http://www.neuralnoise.com/ApertiumWeb2/xml.php?"
		     (babel-form-encode pairs)))
	    (url-request-method "GET"))
       (babel-url-retrieve request-url))))


(defun babel-apertium-wash ()
  "Extract the useful information from the XML returned by apertium."
   (if (not (babel-wash-regex
	     "<translation>\\(\\(.\\|\n\\)*?\\)</translation>"))
	     (error "Apertium XML has changed ; please look for a
	     new version of babel.el")))

;; TODO: ecs.freetranslation.com

;; (defun babel-debug ()
;;   (let ((buf (get-buffer-create "*babel-debug*")))
;;     (set-buffer buf)
;;     (babel-free-fetch "state mechanisms are too busy" "eng" "ger")))

(easy-menu-add-item nil '("tools") ["Babel Translation" babel t])

(defun mm-encode-coding-string (str coding-system)
  "Encode STR to CODING-SYSTEM."
  (if coding-system
      (encode-coding-string str coding-system)
    str))

(provide 'babel)

;;; babel.el ends here
