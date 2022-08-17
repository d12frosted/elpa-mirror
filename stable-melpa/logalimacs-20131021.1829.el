;;; logalimacs.el --- Front-end to logaling-command for Ruby gems

;; Copyright (C) 2011, 2012 by Yuta Yamada

;; Author: Yuta Yamada <cokesboy"at"gmail.com>
;; URL: https://github.com/logaling/logalimacs
;; Package-Version: 20131021.1829
;; Package-Commit: 8286e39502250fc6c3c6656a7f46a8eee8e9a713
;; Version: 1.0.1
;; Package-Requires: ((popwin "0.6.2") (popup "0.5.0") (stem "20130120"))
;; Keywords: translation, logaling-command

;;; License:
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

;;; Commentary:
;; This is Front-end to logaling-command for Ruby gems.
;; Logalimacs.el lookup to registered term at logaling-command and,
;; Executes other commands for logaling-command from emacs.

;;; Usage:
;;  Paste below Emacs lisp code to config file as ~/.emacs.d/init.el etc..
;; (require 'logalimacs)
;; (global-set-key (kbd "M-g M-i") 'loga-interactive-command)
;; (global-set-key (kbd "C-:") 'loga-lookup-in-popup)

;;; Preference setting:
;; (setq
;;  ;; Attach dictionary option for loga-lookup.
;;  loga-use-dictionary-option t
;;  ;; Attempt fallback by stemming if the lookup failed (require stem.el).
;;  loga-use-stemming t
;;  ;; Transform to singular-form from multiple form.
;;  loga-use-singular-form t
;;  ;; Detect language automatically when loga-add/update is used.
;;  ;; Note that yet Japanese and English pair only.
;;  loga-use-auto-detect-language t)

(eval-when-compile
  (require 'cl))

(require 'popwin)
(require 'popup)

;; for word-at-point
(require 'thingatpt)

;; for spaces-string
(require 'rect)

;; json
(require 'json)

;; for flymake-err-info
(require 'flymake)

;; for stem:stripping-inflection function
(require 'stem)

(defcustom loga-popup-output-type :auto
  "Assign 'auto or 'max, available modifying of popup width"
  :group 'logalimacs
  :type  'symbol)

(defcustom loga-cascade-output t
  "If nonnil, output by cascade popup"
  :group 'logalimacs
  :type  'boolean)

(defcustom loga-fly-mode-interval 1
  "Timer-valiable for loga-fly-mode, credit par sec."
  :group 'logalimacs
  :type  'integer)

(defcustom loga-popup-margin 0
  "Margin variable for popup-tip."
  :group 'logalimacs
  :type  'integer)

(defcustom loga-word-cache-limit 10
  "Number of cached words."
  :group 'logalimacs
  :type  'integer)

(defcustom loga-width-limit-source 30
  "Limit width of source word."
  :group 'logalimacs
  :type  'integer)

(defcustom loga-width-limit-target 0
  "Limit of width of target word."
  :group 'logalimacs
  :type  'integer)

(defcustom loga-use-dictionary-option nil
  "If nonnil, use --dictionary for lookup option."
  :group 'logalimacs
  :type  'boolean)

(defcustom loga-use-stemming nil
  "If nonnil, use function of stem.el as fallback"
  :group 'logalimacs
  :type  'boolean)

(defcustom loga-use-singular-form nil
  "If nonnil, convert the search word to singular-form"
  :group 'logalimacs
  :type  'boolean)

(defcustom loga-use-auto-detect-language nil
  "
If nonnil, auto-detect language of source and target for loga-add/update.
Note that yet can specify en and ja pair only"
  :group 'logalimacs
  :type  'boolean)

(defcustom loga-popup-ignoring-major-mode-list '()
  "Set list of major-mode for not displayed as errant format when popup used.
Example:
\(setq loga-popup-ignoring-major-mode-list
  '(org-mode twittering-mode))"
  :group 'logalimacs
  :type  'list)

(defcustom loga-result-limit 0
  "Attach `head' of shell command"
  :group 'logalimacs
  :type  'integer)

(defvar loga-fly-mode nil
  "If nonnil, logalimacs use loga-fly-mode")

(defvar loga-fly-timer nil
  "Timer object for loga-fly-mode.")

(defvar loga-word-cache nil
  "Cache word used by loga-lookup")

(defvar loga-current-command nil
  "Get executed current command-name and symbol")

(defvar loga-current-endpoint nil
  "Store current endpoint symbol")

(defvar loga-current-max-length nil)

(defvar loga-current-highlight-regexp "")

(defvar loga-current-language-option '())

(defvar loga-base-buffer nil)

(defvar loga-popup-point 0)

(defvar loga-popup-width 0)

(defvar loga-fallback-function nil "
Allow your favorite function.
It will be execute when the lookup was failed if it set your function.
Example:
  (setq loga-fallback-function
      (lambda (search-word)
        (your-awesome-translation-function search-word)))")

(defvar loga-mark-region-separator "/")

(defvar loga-marked-words '())

(defvar loga-buffer-string "")

(defvar loga-prototype-word "")

(defconst loga-singular-regexp '(("ies$"         "y")
                                 ("ses$"         "s")
                                 ("oes$"         "o")
                                 ("xes$"         "x")
                                 ("sses$"        "ss")
                                 ("shes$"        "sh")
                                 ("ches$"        "ch")
                                 ("'?s$"         "")))

(defconst logalimacs-buffer "*logalimacs*"
  "buffer name for logalimacs")

(defun loga-pave-regexp (list)
  (loop for (plural single) in list
        collect `(,(format "^%s$" plural)
                  ,single)))

(defvar loga-ignoring-regexp-words
  '("^alps$" "^aegis$" "^apparatus$" "^as$" "^census$"
    "^Christmas$"
    "^ethics$" "^news$" "^overseas$" "^pathos$"
    "^perhaps$" "^radius$" "^shoes$" "^stimulus$"
    "^this$" "^thus$" "^virus$" "^Xmas$"
    ;; word for suffix is "ous"
    "[ceghijklmnortuv]ous$"
    ;; selves themselves ourselves yourselves
    "selves$"
    ;; periplus surplus plus etc..
    "plus$"
    ;; basis crisis emphasis necrosis thesis hypothesis etc..
    "sis$"
    ;; amass bless press etc..
    "ss$"))

(defvar loga-irregular-nouns
  (loga-pave-regexp
   '(("expenses"  "expense")
     ("dies"      "die")
     ("headaches" "headache")
     ("stimuli"   "stimulus")
     ("ties"      "tie")
     ("foes"      "foe")
     ("lies"      "lie")
     ;; former English (~fe or ~f -> ~ves)
     ("knives"    "knife")
     ("lives"     "life")
     ("leaves"    "leaf")
     ("halves"    "half")
     ("wives"     "wife")
     ("thieves"   "thief"))))

(defvar loga-command-alist nil)

(defvar logalimacs-popup-mode-map
  (let ((map (copy-keymap popup-menu-keymap)))
    (define-key map "q" 'keyboard-quit)
    (define-key map "d" 'loga-lookup-in-buffer)
    (define-key map "n" 'popup-next)
    (define-key map "p" 'popup-previous)
    (define-key map "j" 'popup-next)
    (define-key map "k" 'popup-previous)
    (define-key map "f" 'popup-open)
    (define-key map "b" 'popup-close)
    (define-key map "s" 'loga-lookup-by-stemming)
    (define-key map "o" 'loga-fallback) ;; Other function
    map))

(defvar logalimacs-buffer-mode-map
  (let ((map (make-sparse-keymap)))
    (loop for i from ?a upto ?z do
          (define-key map (char-to-string i) 'logalimacs-buffer-mode-off))
    (define-key map "n" 'loga-next-scroll-line)
    (define-key map "p" 'loga-previous-scroll-line)
    (define-key map "j" 'loga-next-scroll-line)
    (define-key map "k" 'loga-previous-scroll-line)
    (define-key map "s" 'loga-lookup-by-stemming)
    (define-key map "o" 'loga-fallback)
    map))

(easy-mmode-define-minor-mode
 logalimacs-buffer-minor-mode
 "Minor mode for logalimacs buffer" nil " LG"
 (copy-keymap logalimacs-buffer-mode-map))

(defun logalimacs-buffer-mode-on ()
  (interactive)
  (loga-delete-popup)
  (logalimacs-buffer-minor-mode t))

(defun logalimacs-buffer-mode-off ()
  (interactive)
  (kill-buffer logalimacs-buffer)
  (logalimacs-buffer-minor-mode 0))

(defun loga-next-scroll-line ()
  (interactive)
  (scroll-other-window 1))

(defun loga-previous-scroll-line ()
  (interactive)
  (scroll-other-window -1))

(defun loga-response-of-event (command-alist)
  (assoc-default last-input-event command-alist))

(defun loga-make-displaying-commands ()
  (lexical-let
      ((commands
        (loop for (prefix . command) in loga-command-alist
              collect (loga-mixture-bracket prefix command))))
    (mapconcat 'identity commands ",")))

(defun loga-mixture-bracket (command-prefix command-symbol)
  (lexical-let*
      ((command (loga-from-symbol-to-string command-symbol))
       (prefix  (char-to-string command-prefix))
       (list-of-rest (nthcdr 2 (string-to-list (split-string command ""))))
       (rest (mapconcat 'identity list-of-rest "")))
    (concat prefix ")" rest)))

;;;###autoload
(defun loga-interactive-command ()
  "interactive-command for logaling-command, types following mini-buffer."
  (interactive)
  (read-event (concat "types prefix of feature that want you :\n "
                      (loga-make-displaying-commands)))
  (setq loga-current-command (loga-response-of-event loga-command-alist))
  (case loga-current-command
    (:lookup (loga-lookup-at-manually))
    (t       (loga-command))))

(defun loga-to-shell (cmd &optional arg async?)
  (if async?
      (async-shell-command (concat cmd " " arg) logalimacs-buffer)
    (shell-command-to-string (concat cmd " " arg " &"))))

(defun loga-do-ruby (body &optional lang)
  (shell-command-to-string (concat lang "ruby -e " "'" body "'")))

(defun loga-from-symbol-to-string (symbol)
  (replace-regexp-in-string ":" "" (symbol-name symbol)))

(defun loga-command (&optional search-word)
  (lexical-let* ((loga "\\loga")
                 (task (loga-from-symbol-to-string loga-current-command))
                 (word-and-options (loga-lookup-attach-option search-word)))
    (setq loga-base-buffer (current-buffer)
          loga-marked-words nil)
    (case loga-current-command
      (:lookup             (loga-produce-contents search-word word-and-options))
      ((:add  :update)     (loga-add/update task))
      ((:show :list)
       (loga-make-buffer   (loga-to-shell loga task)))
      ((:config :copy :delete :help :import :new)
       (loga-make-buffer   (loga-to-shell loga (concat task " " (loga-input)))))
      ((:register :unregister :version)
       (minibuffer-message (loga-to-shell loga task))))))

(defun loga-produce-contents (search-word word-and-options)
  (lexical-let ((terminal-output
                 (loga-to-shell "\\loga" (format "lookup %s" word-and-options))))
    (loga-register-output (cons search-word terminal-output))
    terminal-output))

(defun loga-add/update (task)
  (if mark-active
      (loga-return-marked-region))
  (lexical-let* ((input (loga-input)))
    (loga-to-shell "\\loga" (concat task " " input) t)
    (loga-read-buffer-string)
    (if (and (string-match "^term '.+' already exists in '.+'" loga-buffer-string)
             (y-or-n-p
              (format "%sAre you sure you want to 'update' followed by?"
                      loga-buffer-string)))
        (loga-update)
      (loga-quit))))

(defun loga-read-buffer-string ()
  (interactive)
  (switch-to-buffer logalimacs-buffer)
  (setq loga-buffer-string ""
        loga-buffer-string (buffer-string))
  (switch-to-buffer loga-base-buffer))

(defun loga-lookup-attach-option (search-word)
  (lexical-let* ((options '()))
    (if loga-use-dictionary-option
        (push "--dictionary" options))
    (if (eq loga-current-endpoint :popup)
        (push "--output=json" options))
    (concat search-word " " (mapconcat 'identity options " "))))

(defun loga-register-output (current-search-words)
  (lexical-let* ((cached-list-length (length loga-word-cache)))
    (cond ((<= loga-word-cache-limit cached-list-length)
           (setq loga-word-cache (loga-nthcar (- cached-list-length 1)
                                              loga-word-cache))))
    (push current-search-words loga-word-cache)))

(defun loga-nthcar (n list)
  (reverse (nthcdr (- (length list) n) (reverse list))))

;;;###autoload
(defun loga-add ()
  "this is command to adding word, first source word, second target word."
  (interactive)
  (setq loga-current-command :add)
  (loga-command))

;;;###autoload
(defun loga-update ()
  "update to registered word"
  (interactive)
  (setq loga-current-command :update)
  (loga-command))

(defun loga-ignore-login-message (terminal-output)
  "Ignore 'user-name has logged on 7 from :0.'etc.. if endpoint is popup"
  (with-temp-buffer
    (insert terminal-output)
    (goto-char (point-min))
    (search-forward "[\n{" nil t)
    (backward-char 3)
    (set-mark-command nil)
    (search-forward "}\n]" nil t)
    (forward-char 1)
    (narrow-to-region (point) (mark))
    (buffer-string)))

(defun loga-lookup (endpoint &optional prototype-of-search-word)
  (setq loga-current-endpoint endpoint)
  (let* ((loga-current-command :lookup)
         (source-word
          (format "\"%s\""
                  (or prototype-of-search-word (loga-decide-source-word))))
         (terminal-output (loga-command source-word)))
    (save-excursion
      (if (string< "" terminal-output)
          (case endpoint
            (:popup  (loga-make-popup
                      (loga-ignore-login-message terminal-output)))
            (:buffer (loga-make-buffer terminal-output)))
        (if (loga-fallback-with-stemming-p source-word prototype-of-search-word)
            (loga-lookup-by-stemming)
          (if (functionp loga-fallback-function)
              (loga-fallback (loga-get-search-word))
            (minibuffer-message
             (format "%s is not found" source-word))))))))

(defun loga-decide-source-word ()
  (if mark-active
      (loga-return-marked-region)
    (if current-prefix-arg
        (loga-input)
      (loga-singularize (loga-return-word-on-cursor)))))

(defun loga-return-marked-region ()
  (lexical-let ((marked-region
                 (buffer-substring-no-properties
                  (region-beginning) (region-end))))
    (loga-register-mark-words marked-region)
    marked-region))

(defun loga-register-mark-words (marked-words)
  (lexical-let* ((separator loga-mark-region-separator)
                 (separate-regexp (concat "^\\(.*\\)" separator "\\(.*\\)")))
    (string-match separate-regexp marked-words)
    (setq loga-marked-words (cons (or (match-string 1 marked-words)
                                      marked-words)
                                  (match-string 2 marked-words)))))

(defun loga-convert-from-json (raw-json-data)
  (lexical-let* ((mixed-list (json-read-from-string raw-json-data))
                 (keywords (loga-extract-keywords-from mixed-list))
                 (converted-list (loga-format keywords)))
    (if loga-cascade-output
        converted-list
      (loga-format-to-string converted-list))))

(defun loga-extract-keywords-from (all-data)
  (loop for translation-group across all-data
        collect (loga-trim-and-compute-length translation-group)))

(defun loga-trim-and-compute-length (translation-group)
  (loop with source and target and note
        with source-length and target-length
        for (key . statement) in translation-group do
        (case key
          ('source (setq source (loga-chop-source statement)
                         source-length (loga-compute-length source)))
          ('target (setq target (loga-chop-target statement)
                         target-length (loga-compute-length target)))
          ('note   (setq note statement)))
        finally return `(,source ,target ,note ,source-length ,target-length)))

(defun loga-format-to-string (converted-list)
  `(mapconcat 'identity ,@converted-list "\n"))

(defun loga-format (words)
  (setq loga-current-max-length (loga-compute-max-length words))
  (loop with size = loga-current-max-length
        for (source target note source-length target-length) in words
        if (and (loga-less-than-window-half-p source-length)
                (> loga-width-limit-source source-length))
        collect (loga-append-margin source target note size)))

(defun loga-chop-source (raw-source)
  (lexical-let ((tmp-source-length (loga-compute-length raw-source)))
    (if (string-match "\\[.+\\]" raw-source)
        (replace-regexp-in-string "\\[.+\\]" "" raw-source)
      raw-source)))

(defun loga-chop-target (raw-target)
  (lexical-let ((tmp-target-length (loga-compute-length raw-target))
                (window-half (/ (window-width) 2))
                (pretty-target
                 (loga-reject-brackets-character raw-target)))
    (if (< window-half tmp-target-length)
        (nth 1 (popup-fill-string pretty-target window-half))
      pretty-target)))

(defun loga-reject-brackets-character (target)
  (loop for reject-regexp in '("(.+?)" "^ +")
        for pretty-characters = target then pretty-characters
        do (setq pretty-characters
                 (replace-regexp-in-string reject-regexp "" pretty-characters))
        finally return pretty-characters))

(defun loga-compute-max-length (words)
  (loop with max-source-length = 0
        with max-target-length = 0
        for (source target note source-length target-length) in words
        if (loga-clear-condition-p max-source-length max-target-length
                                   source-length target-length)
        do (setq max-source-length (max max-source-length source-length)
                 max-target-length (max max-target-length target-length))
        finally return (cons max-source-length max-target-length)))

(defun loga-clear-condition-p (max-source-length max-target-length
                               source-length target-length)
  (lexical-let ((more-than-max-p (or (< max-source-length source-length)
                                     (< max-target-length target-length)))
                (less-than-window-half-p
                 (loga-less-than-window-half-p source-length))
                (below-limit-p (< source-length loga-width-limit-source)))
    (and more-than-max-p less-than-window-half-p below-limit-p)))

(defun loga-fallback-with-stemming-p (source-word prototype-of-search-word)
  (lexical-let ((prototype-word (loga-extract-prototype-from source-word)))
    (and loga-use-stemming
         (not prototype-of-search-word)
         (not (equal source-word prototype-word))
         (loga-one-word-p source-word))))

(defun loga-less-than-window-half-p (source-length)
  (lexical-let* ((half (- (/ (window-width) 2) 2)))
    (< source-length half)))

(defun loga-compute-length (sentence)
  (loop with sum = 0
        with tokens = (string-to-list (split-string sentence ""))
        for token in tokens
        if (and (not (equal "" token))
                (multibyte-string-p token)
                (loga-ignore-character-p token))
        do      (setq  sum (+ sum 2))
        else do (setq  sum (+ sum 1))
        finally return sum))

(defun loga-ignore-character-p (token)
  "If mixed Japanese language, wrong count at specific character.
Because it escape character"
  (not (string-match "[\\ -/:->{-~\\?^]\\|\\[\\|\\]" token)))

(defun loga-append-margin (source target note max-length)
  (lexical-let* ((margin (- (car max-length) (loga-compute-length source)))
                 (column (concat source (spaces-string margin) ":" target)))
    (if note
        `(,column ,(concat "\n" note))
      `(,column))))

(defun loga-query (&optional message)
  (lexical-let* ((input (read-string (or message "types here:")
                                     (loga-attach-initial-value message))))
    (case loga-current-command
      ((:add :update) (concat "\"" input "\""))
      (t input))))

(defun loga-attach-initial-value (message)
  (lexical-let ((initial-source (car loga-marked-words))
                (initial-target (cdr loga-marked-words)))
    (case loga-current-command
      (:lookup
       (if current-prefix-arg (loga-get-search-word)))
      ((:add :update)
       (when (or initial-source
                 initial-target)
         (cond ((string-match "source.+" message)
                initial-source)
               ((string-match "target.+" message)
                initial-target)
               (t nil)))))))

(defun loga-input ()
  (lexical-let* ((query (loga-from-symbol-to-string loga-current-command))
                 (task loga-current-command)
                 (messages (concat query ": "))
                 (loga-base-buffer (current-buffer))
                 result)
    (case task
      ((:add :update :config :copy :delete :help :import :new
             :register :unregister)
       (loga-make-buffer (loga-to-shell "\\loga help" query))))
    (case task
      (:add    (setq messages '("source: " "target: " "note(optional): ")))
      (:update (setq messages '("source: " "target(old): "
                                "target(new): " "note(optional): ")))
      (:lookup (setq messages '("search: ")))
      (t       (setq messages `(,messages))))
    (setq result (loga-solve-queries task messages))
    (mapconcat 'identity
               (case task
                 ((:add :update)
                  (append result loga-current-language-option))
                 (t       result))
               " ")))

(defun loga-solve-queries (task messages)
  (loop for message in messages
        for query = (loga-query message)
        if (case task ((:add :update) t))
        do (loga-store-language-option message query)
        collect query))

(defun loga-store-language-option (message input)
  (when loga-use-auto-detect-language
    (cond ((equal message "source: ")
           (setq loga-current-language-option
                 `(,(concat "-S=" (loga-check-language input)))))
          ((or (equal message "target: ")
               (equal message "target(new): "))
           (push
            (concat "-T=" (loga-check-language input))
            loga-current-language-option)))))

(defun loga-check-language (word)
  (cond ((loga-japanese-p word)
         "ja")
        ;; TODO: handle against other language
        ((string-match "[a-zA-Z]" word)
         "en")))

(defun loga-japanese-p (word &optional choice)
  (lexical-let* ((striped-word (replace-regexp-in-string "'" "" word))
                 (sep      loga-mark-region-separator)
                 (hiragana "\\p{hiragana}")
                 (katakana "\\p{katakana}")
                 (kanji    "\\p{Han}")
                 (japanese-regexp
                  (case choice
                     (:hiragana hiragana)
                     (:katakana katakana)
                     (:kanji    kanji)
                     (t         (concat hiragana "|" katakana "|" kanji)))))
    (zerop
     (string-to-number
      (loga-do-ruby
       (concat
        "puts %s" sep striped-word sep " =~ /" japanese-regexp "/ ? 0 : 1")
       ;; If set LANG=C, then can't return Boolean correctly.
       ;; To fix this problem add below LANG.
       "LANG=ja_JP.UTF-8 ")))))

(defun loga-character-at-point ()
  (lexical-let* ((line (thing-at-point 'line))
                 (address (- (point) (point-at-bol)))
                 (limit   (1- (- (point-at-eol) (point-at-bol))))
                 (character (char-to-string (aref line (min address limit)))))
    character))

;;;###autoload
(defun loga-lookup-at-manually ()
  "Search word from logaling.
If not mark region, search word type on manual.
Otherwise passed character inside region."
  (interactive)
  (setq current-prefix-arg 4)
  (loga-lookup :buffer))

;;;###autoload
(defun loga-lookup-in-popup ()
  "Display the output of loga-lookup at tooltip."
  (interactive)
  (if (loga-match-ignoring-list-p)
      (loga-lookup :buffer)
    (loga-lookup :popup)))

(defun loga-match-ignoring-list-p ()
  (loop for major-mode-name in loga-popup-ignoring-major-mode-list
        if (eq major-mode-name major-mode)
        do (return t)
        finally return nil))

;;;###autoload
(defun loga-lookup-in-buffer ()
  (interactive)
  (loga-lookup :buffer))

;;;###autoload
(defun loga-lookup-in-buffer-light()
  "Use async shell commad for lookup and output *logalimacs* buffer"
  (interactive)
  (setq loga-base-buffer (current-buffer)
        loga-current-endpoint :buffer
        other-window-scroll-buffer logalimacs-buffer)
  (popwin:popup-buffer
   (get-buffer-create logalimacs-buffer)
   :noselect t :stick t :height 10 :position :top)
  (loga-to-shell "\\loga lookup "
                 (format "\"%s\" %s --no-pager %s"
                         (loga-decide-source-word)
                         (loga-lookup-attach-option "")
                         (loga-get-option :result-limit))
                 t)
  (loga-modify-buffer-configuration :truncate-line t))

(defun* loga-modify-buffer-configuration (&key truncate-line)
  (switch-to-buffer logalimacs-buffer)
  (if truncate-line (setq truncate-lines t))
  (switch-to-buffer loga-base-buffer))

(defun loga-get-option (option)
  (case option
    (:result-limit
     (if (not (zerop loga-result-limit))
         (format "| \\head -n %i" loga-result-limit)
       ""))))

(defun loga-lookup-by-stemming ()
  (interactive)
  (when loga-use-stemming
    (loga-delete-popup)
    (loga-lookup loga-current-endpoint
                 (loga-extract-prototype-from (loga-get-search-word)))))

(defun loga-delete-popup ()
  (with-no-warnings
    (popup-live-p menu)
    (popup-delete menu)))

(defun loga-singularize (word)
  (if (and loga-use-singular-form
           (not (loga-irregular-word-p word)))
      (loop with singlurar-regexp = (append loga-irregular-nouns
                                            loga-singular-regexp)
            for (regexp replace) in singlurar-regexp
            if (string-match regexp word)
            do (return (replace-regexp-in-string regexp replace word))
            finally return word)
    word))

(defun loga-irregular-word-p (sample-word)
  (loop for irregular-word in loga-ignoring-regexp-words
        if (string-match irregular-word sample-word)
        do (return t)))

(defun loga-return-word-on-cursor ()
  "Return word where point on cursor."
  (save-excursion
    (lexical-let ((match-word (loga-word-at-point)))
      (if (string-match "[上-黑]" match-word)
          (loga-reject-hiragana match-word)
        match-word))))

(defun loga-word-at-point ()
  (interactive)
  (save-excursion
    (lexical-let* ((character      (loga-character-at-point))
                   (classification (loga-classify-language character))
                   kanji+hiragana)
      (when (string-match "[ \n]" character)
        (skip-chars-backward " "))
      (if (null classification)
          (word-at-point)
        (case classification
          (:english  (loga-skip :backward :english))
          (:hiragana (loga-skip :backward :hiragana)
                     (when (loga-japanese-p
                            (char-to-string (char-before)) :kanji)
                       (setq kanji+hiragana t)
                       (loga-skip :backward :kanji)))
          (:katakana (loga-skip :backward :katakana))
          (:kanji    (loga-skip :backward :kanji)))
        (set-mark-command nil)
        (loga-skip :forward
                   (case classification
                     (:english           :english)
                     (:hiragana          (if kanji+hiragana :kanji :hiragana))
                     (:kanji             :kanji)
                     (:katakana          :katakana)))
        (buffer-substring-no-properties
         (region-beginning) (region-end))))))

(defun loga-classify-language (character)
  (if (string-match "[a-zA-Z']" character)
      :english
    (loop for classification in '(:hiragana :katakana :kanji)
          if (loga-japanese-p character classification)
          do (return classification)
          finally return nil)))

(defun loga-skip (direction &optional group)
  (lexical-let ((skip-group
                 (case group
                   (:kanji           "上-黑")
                   (:hiragana        "ぁ-ん")
                   (:katakana        "ァ-ン")
                   (:english         "a-zA-Z'")
                   (t                "a-zA-Zぁ-んァ-ン上-黑'"))))
    (case direction
      (:forward  (skip-chars-forward  skip-group))
      (:backward (skip-chars-backward skip-group)))))

(defun loga-reject-hiragana (string)
  (replace-regexp-in-string "[ぁ-ん]" "" string))

(defun loga-make-buffer(content)
  (setq loga-current-endpoint :buffer
        other-window-scroll-buffer logalimacs-buffer)
  (with-temp-buffer
    (switch-to-buffer (get-buffer-create logalimacs-buffer))
    (setq buffer-read-only nil)
    (erase-buffer) ;;initialize
    (insert content)
    (goto-char 0)
    (when (eq :lookup loga-current-command)
      (loga-highlight (loga-get-search-word)))
    (setq buffer-read-only t))
  (switch-to-buffer loga-base-buffer)
  (popwin:popup-buffer
   (get-buffer-create logalimacs-buffer)
   :noselect t :stick t :height 10 :position :top)
  (case loga-current-command
    ((:lookup :show :list)
     (logalimacs-buffer-mode-on))))

(defun loga-highlight (search-word)
  (when (not (equal "" search-word))
    (setq loga-current-highlight-regexp search-word)
    (highlight-regexp search-word)))

(defun loga-get-search-word ()
  (replace-regexp-in-string "\"" "" (caar loga-word-cache)))

(defun loga-make-popup (content)
  (lexical-let* ((converted-content (loga-convert-from-json content)))
    (setq loga-current-endpoint :popup)
    (loga-setup-point-and-width)
    (typecase converted-content
      (list
       (popup-cascade-menu converted-content
                           :point loga-popup-point
                           :width loga-popup-width
                           :height (/ (window-height) 2)
                           :keymap logalimacs-popup-mode-map))
      (string
       (popup-tip converted-content
                  :margin loga-popup-margin
                  :point loga-popup-point
                  :width loga-popup-width)))))

(defun loga-compute-point ()
  (lexical-let* ((half (/ (window-width) 2))
                 (quarter (/ half 2))
                 (cursor (- (point) (point-at-bol))))
    (cond
     ((< half cursor)
      (+ (point-at-bol) quarter))
     (t (point)))))

(defun loga-popup-output-type ()
  (lexical-let ((type (symbol-name loga-popup-output-type)))
    (if (string-match ":" type)
        loga-popup-output-type
      (make-symbol (concat ":" type)))))

(defun loga-setup-point-and-width ()
  (case (loga-popup-output-type)
    (:auto (setq loga-popup-width (loga-compute-width)
                 loga-popup-point (loga-compute-point)))
    (:max  (setq loga-popup-width (window-width)
                 loga-popup-point (point-at-bol)))))

(defun loga-compute-width ()
  (lexical-let*
      ((sum
        (loop for (source-length . target-length) in `(,loga-current-max-length)
              collect (+ source-length  target-length))))
    (min (+ (car sum) 1) (window-width))))

;;;###autoload
(defun loga-fly-mode ()
  "Toggle loga-fly-mode-on and loga-fly-mode-off."
  (interactive)
  (if loga-fly-mode
      (loga-fly-mode-off)
    (loga-fly-mode-on)))

(defun loga-fly-mode-on ()
  (setq loga-fly-mode t
        loga-fly-timer
        (run-with-idle-timer loga-fly-mode-interval t
                             (lambda()
                               (loga-lookup-in-buffer))))
  (message "loga-fly-mode enable"))

(defun loga-fly-mode-off ()
  (cancel-timer loga-fly-timer)
  (setq loga-fly-mode nil)
  (message "loga-fly-mode disable"))

(defun loga-quit ()
  (loga-delete-popup)
  (switch-to-buffer logalimacs-buffer)
  (when (eq loga-current-endpoint :buffer)
    (quit-window)
    (switch-to-buffer loga-base-buffer)))

(defun loga-check-state ()
  (interactive)
  (lexical-let* ((version (loga-do-ruby "print RUBY_VERSION"))
                 (installed-p
                  (not (string-match "no such file to load"
                                     (loga-do-ruby "require \"logaling\""))))
                 (rvm-p (eq 0 (shell-command "which rvm"))))
    (cond
     ((and installed-p version)
      (message "Check OK: logaling-command already installed")
      t)
     ((not (string-match "1.9.[0-9]\\|[2-9].[0-9].[0-9]" version))
      (message "Note: Ruby version errer, require Ruby 1.9.x"))
     (rvm-p
      (if (require 'rvm nil t)
          (message "Note: require 'gem install logaling-command'")
        (message "Note: if use rvm, require rvm.el and sets the config to your dot emacs.")))
     (t (message "Note: require 'sudo gem install logaling-command'")))))

(defun loga-version ()
  (lexical-let* ((version-string (loga-to-shell "\\loga version")))
    (string-match "[0-9].[0-9].[0-9]" version-string)
    (match-string 0 version-string)))

(defun loga-fallback (&optional search-word)
  (interactive)
  (when (functionp loga-fallback-function)
    (funcall loga-fallback-function (or search-word (loga-get-search-word)))
    (loga-delete-popup)))

(defun loga-one-word-p (search-word)
  (lexical-let ((english-only-p (not (string-match "[^a-zA-Z]" search-word)))
                (spaceless-p    (not (string-match " "      search-word))))
    (and english-only-p
         spaceless-p)))

(defun loga-extract-prototype-from (source-word)
  (setq loga-prototype-word
        (or (car (assoc-default source-word
                                (append loga-irregular-nouns
                                        stem:irregular-verb-alist)))
            (stem:stripping-inflection source-word)))
  loga-prototype-word)

(setq loga-command-alist
      `((?a . :add)
        (?c . :config)
        (?C . :copy)
        (?d . :delete)
        (?h . :help)
        (?i . :import)
        (?l . :lookup)
        (?L . :list)
        (?n . :new)
        (?r . :register)
        (?U . :unregister)
        (?u . :update)
        (?s . :show)
        (?v . :version)))

(provide 'logalimacs)

;; Local Variables:
;; coding: utf-8
;; mode: emacs-lisp
;; End:

;;; logalimacs.el ends here
