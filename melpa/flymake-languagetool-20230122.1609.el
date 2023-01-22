;;; flymake-languagetool.el --- Flymake support for LanguageTool  -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2023  Shen, Jen-Chieh
;; Created date 2021-04-02 23:22:37

;; Authors: Shen, Jen-Chieh <jcs090218@gmail.com>, Trey Peacock <git@treypeacock.com>
;; URL: https://github.com/emacs-languagetool/flymake-languagetool
;; Package-Version: 20230122.1609
;; Package-Commit: ad8c724147d5a3a9f6ee59e0c7581e68fba4a2f8
;; Version: 0.2.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience grammar check

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Flymake support for LanguageTool.
;;

;;; Code:

(require 'seq)
(require 'url)
(require 'json)
(require 'cl-lib)
(require 'flymake)

;; Dynamically bound.
(defvar url-http-end-of-headers)

(defgroup flymake-languagetool nil
  "Flymake support for LanguageTool."
  :prefix "flymake-languagetool-"
  :group 'flymake
  :link '(url-link :tag "Github"
                   "https://github.com/emacs-languagetool/flymake-languagetool"))

(defcustom flymake-languagetool-active-modes
  '(text-mode latex-mode org-mode markdown-mode message-mode)
  "List of major mode that work with LanguageTool."
  :type 'list
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-ignore-faces-alist
  '((org-mode . (org-code org-block)))
  "Filters out errors if they are of fortified with faces in this alist.
It is an alist of (major-mode . faces-to-ignore)"
  :type '(alist :key-type symbol
                :value-type (repeat symbol))
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-url nil
  "The URL for the LanguageTool API we should connect to."
  :type '(choice (const :tag "Auto" nil)
                 (string :tag "URL"))
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-server-jar nil
  "The path of languagetool-server.jar.

The server will be automatically started if specified.  Set to
nil if you’re going to connect to a remote LanguageTool server,
or plan to start a local server some other way."
  :type '(choice (const :tag "Off" nil)
                 (file :tag "Filename" :must-match t))
  :link '(url-link :tag "LanguageTool embedded HTTP Server"
                   "https://dev.languagetool.org/http-server.html")
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-server-port "8081"
  "Port used to make api url requests on local server."
  :type 'string
  :link '(url-link :tag "LanguageTool embedded HTTP Server"
                   "https://dev.languagetool.org/http-server.html")
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-server-command ()
  "Custom command to start LanguageTool server.
If non-nil, this list of strings replaces the standard java cli command."
  :type '(repeat string)
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-server-args ()
  "Extra arguments to pass when starting the LanguageTool server."
  :type '(repeat string)
  :link '(url-link :tag "LanguageTool embedded HTTP Server"
                   "https://dev.languagetool.org/http-server.html")
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-language "en-US"
  "The language code of the text to check."
  :type '(string :tag "Language")
  :safe #'stringp
  :group 'flymake-languagetool)
(make-variable-buffer-local 'flymake-languagetool-language)

(defcustom flymake-languagetool-check-spelling nil
  "If non-nil, LanguageTool will check spelling."
  :type 'boolean
  :safe #'booleanp
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-check-params ()
  "Extra parameters to pass with LanguageTool check requests."
  :type '(alist :key-type string :value-type string)
  :link '(url-link :tag "LanguageTool API"
                   "https://languagetool.org/http-api/swagger-ui/#!/default/post_check")
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-spelling-rules
  '("HUNSPELL_RULE"
    "HUNSPELL_RULE_AR"
    "MORFOLOGIK_RULE_AST"
    "MORFOLOGIK_RULE_BE_BY"
    "MORFOLOGIK_RULE_BR_FR"
    "MORFOLOGIK_RULE_CA_ES"
    "MORFOLOGIK_RULE_DE_DE"
    "MORFOLOGIK_RULE_EL_GR"
    "MORFOLOGIK_RULE_EN"
    "MORFOLOGIK_RULE_EN_AU"
    "MORFOLOGIK_RULE_EN_CA"
    "MORFOLOGIK_RULE_EN_GB"
    "MORFOLOGIK_RULE_EN_NZ"
    "MORFOLOGIK_RULE_EN_US"
    "MORFOLOGIK_RULE_EN_ZA"
    "MORFOLOGIK_RULE_ES"
    "MORFOLOGIK_RULE_GA_IE"
    "MORFOLOGIK_RULE_IT_IT"
    "MORFOLOGIK_RULE_LT_LT"
    "MORFOLOGIK_RULE_ML_IN"
    "MORFOLOGIK_RULE_NL_NL"
    "MORFOLOGIK_RULE_PL_PL"
    "MORFOLOGIK_RULE_RO_RO"
    "MORFOLOGIK_RULE_RU_RU"
    "MORFOLOGIK_RULE_RU_RU_YO"
    "MORFOLOGIK_RULE_SK_SK"
    "MORFOLOGIK_RULE_SL_SI"
    "MORFOLOGIK_RULE_SR_EKAVIAN"
    "MORFOLOGIK_RULE_SR_JEKAVIAN"
    "MORFOLOGIK_RULE_TL"
    "MORFOLOGIK_RULE_UK_UA"
    "SYMSPELL_RULE")
  "LanguageTool rules for checking of spelling.
These rules will be enabled if `flymake-languagetool-check-spelling' is
non-nil."
  :type '(repeat string)
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-disabled-rules '()
  "LanguageTool rules to be disabled by default. "
  :type '(repeat string)
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-disabled-categories '()
  "LanguageTool categories to be disabled by default. "
  :type '(repeat string)
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-use-categories t
  "Report errors with LanguageTool Category."
  :type 'boolean
  :safe #'booleanp
  :group 'flymake-languagetool)

(defvar-local flymake-languagetool--source-buffer nil
  "Current buffer we are currently using for grammar check.")

(defvar-local flymake-languagetool--proc-buf nil
  "Current process we are currently using for grammar check.")

(defvar flymake-languagetool--local nil
  "Can we reach the local LanguageTool server API?")

(defconst flymake-languagetool-category-map
  '(("CASING" . :casing)
    ("COLLOQUIALISMS" . :colloquialisms)
    ("COMPOUNDING" . :compounding)
    ("CONFUSED_WORDS" . :confused-words)
    ("FALSE_FRIENDS" . :false-friends)
    ("GENDER_NEUTRALITY" . :gender-neutrality)
    ("GRAMMAR" . :grammar)
    ("MISC" . :misc)
    ("PLAIN_ENGLISH" . :plain-english)
    ("PUNCTUATION" . :punctuation)
    ("REDUNDANCY" . :redundancy)
    ("REGIONALISMS" . :regionalisms)
    ("REPETITIONS" . :repetitions)
    ("REPETITIONS_STYLE" . :repetitions-style)
    ("SEMANTICS" . :semantics)
    ("STYLE" . :style)
    ("TYPOGRAPHY" . :typography)
    ("TYPOS" . :typos)
    ("WIKIPEDIA" . :wikipedia))
  ;; https://languagetool.org/development/api/org/languagetool/rules/Categories.html
  "LanguageTool category mappings")

;;; Util
(defun flymake-languagetool--category-setup ()
  "Setup LanguageTool categories as Flymake types."
  (cl-loop for (n . key) in flymake-languagetool-category-map
           for name = (downcase (string-replace "_" "-" n))
           for cat = (intern (format "flymake-languagetool-%s" name))
           do
           (put key 'flymake-category cat)
           (put cat 'face 'flymake-warning)
           (put cat 'flymake-bitmap 'flymake-warning-bitmap)
           (put cat 'severity (warning-numeric-level :warning))
           (put cat 'mode-line-face 'compilation-warning)
           (put cat 'flymake-type-name name)))

(when flymake-languagetool-use-categories
  (flymake-languagetool--category-setup))

;; Ignore some faces
(defun flymake-languagetool--ignore-at-pos-p (pos src-buf
                                                  faces-to-ignore)
  "Return non-nil if faces at POS in SRC-BUF intersect FACES-TO-IGNORE."
  (let ((x (get-text-property pos 'face src-buf)))
    (cl-intersection faces-to-ignore (ensure-list x))))

(defun flymake-languagetool--check-all (errors source-buffer)
  "Check grammar ERRORS for SOURCE-BUFFER document."
  (let ((faces (alist-get (buffer-local-value 'major-mode source-buffer)
                          flymake-languagetool-ignore-faces-alist))
        check-list)
    (dolist (error errors)
      (let-alist error
        (unless (and faces (flymake-languagetool--ignore-at-pos-p
                            (+ .offset (point-min))
                            source-buffer faces))
          (push (flymake-make-diagnostic
                 source-buffer
                 (+ .offset (point-min))
                 (+ .offset .length (point-min))
                 (if flymake-languagetool-use-categories
                     (map-elt flymake-languagetool-category-map
                              .rule.category.id)
                   :warning)
                 (concat .message " [LanguageTool]")
                 ;; add text property for suggested replacements
                 `((suggestions . (,@(seq-map (lambda (rep)
                                                (car (map-values rep)))
                                              .replacements)))
                   (rule-id . ,.rule.id)
                   (rule-desc . ,.rule.description)
                   (type . ,.rule.issueType)
                   (category . ,.rule.category.id)))
                check-list))))
    check-list))

(defun flymake-languagetool--output-to-errors (output source-buffer)
  "Parse the JSON data from OUTPUT of LanguageTool. "
  (let* ((json-array-type 'list)
         (full-results (json-read-from-string output))
         (errors (cdr (assoc 'matches full-results))))
    (flymake-languagetool--check-all errors source-buffer)))

(defun flymake-languagetool--handle-finished (status source-buffer report-fn)
  "Callback function for LanguageTool process for SOURCE-BUFFER.
STATUS provided from `url-retrieve'."
  (when-let ((err (plist-get status :error))
             (test (equal (current-buffer) flymake-languagetool--proc-buf)))
    (funcall report-fn :panic :explanation (error-message-string err))
    (error (error-message-string err)))
  (if (and url-http-end-of-headers
           (equal (current-buffer)
                  (with-current-buffer source-buffer
                    flymake-languagetool--proc-buf)))
      (let ((output (save-restriction
                      (set-buffer-multibyte t)
                      (goto-char url-http-end-of-headers)
                      (buffer-substring (point) (point-max)))))
        (with-current-buffer source-buffer
          (funcall report-fn
                   (flymake-languagetool--output-to-errors output source-buffer)
                   :region (cons (point-min) (point-max)))
          (kill-buffer flymake-languagetool--proc-buf)
          (setq flymake-languagetool--proc-buf nil)))
    (with-current-buffer source-buffer
      (flymake-log :warning "Canceling tha obsolete check %s"
                   flymake-languagetool--proc-buf))))

(defun flymake-languagetool--check (report-fn)
  "Run LanguageTool on the current buffer's contents."
  (when (buffer-live-p flymake-languagetool--proc-buf)
    (flymake-log :warning "Canceling the obsolete check %s"
                 flymake-languagetool--proc-buf)
    ;; need to check if buffer has ongoing process or else we may
    ;; potentially delete the wrong one.
    (when (get-buffer-process flymake-languagetool--proc-buf)
      (delete-process (get-buffer-process flymake-languagetool--proc-buf)))
    (kill-buffer flymake-languagetool--proc-buf)
    (setq flymake-languagetool--proc-buf nil))
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/x-www-form-urlencoded")))
         (source-buffer (current-buffer))
         (disabled-cats
          (string-join flymake-languagetool-disabled-categories ","))
         (disabled-rules
          (string-join (append flymake-languagetool-disabled-rules
                               (unless flymake-languagetool-check-spelling
                                 flymake-languagetool-spelling-rules))
                       ","))
         (params (list (list "text" (with-current-buffer source-buffer
                                      (buffer-substring-no-properties
                                       (point-min) (point-max))))
                       (list "language" flymake-languagetool-language)
                       (unless (string-empty-p disabled-rules)
                         (list "disabledRules" disabled-rules))
                       (unless (string-empty-p disabled-cats)
                         (list "disabledCategories" disabled-cats))))
         (url-request-data (url-build-query-string params nil t)))
    (if (flymake-languagetool--reachable-p)
        (setq flymake-languagetool--proc-buf
              (url-retrieve
               (concat (or flymake-languagetool-url
                           (format "http://localhost:%s"
                                   flymake-languagetool-server-port))
                       "/v2/check")
               #'flymake-languagetool--handle-finished
               (list source-buffer report-fn) t))
      ;; can't reach LanguageTool API, try again. TODO:
      (sit-for 1)
      (funcall report-fn '()))))

(defun flymake-languagetool--reachable-p ()
  (let ((res (or flymake-languagetool--local
                 (condition-case nil
                     (url-retrieve-synchronously
                      (concat (or flymake-languagetool-url
                                  (format "http://localhost:%s"
                                          flymake-languagetool-server-port))
                              "/v2/languages")
                      t)
                   (file-error nil)))))
    (when (buffer-live-p res)
      (kill-buffer res)
      (setq res t))
    res))

(defun flymake-languagetool--start-server (report-fn)
  "Start the LanguageTool server if we didn’t already."
  (let* ((source (current-buffer))
         (cmd (or flymake-languagetool-server-command
                  (list "java" "-cp" flymake-languagetool-server-jar
                        "org.languagetool.server.HTTPServer"
                        "--port" flymake-languagetool-server-port))))
    (make-process
     :name "languagetool-server" :noquery t :connection-type 'pipe
     :buffer " *LanguageTool server*"
     :command (append cmd flymake-languagetool-server-args)
     :filter
     (lambda (proc string)
       (funcall #'internal-default-process-filter proc string)
       (when (string-match ".*Server started\n$" string)
         (with-current-buffer source
           (setq flymake-languagetool--local t)
           (flymake-languagetool--checker report-fn))
         (set-process-filter proc nil)))
     :sentinel
     (lambda (proc _event)
       (when (memq (process-status proc) '(exit signal))
         (setq flymake-languagetool--local nil)
         (kill-buffer (process-buffer proc)))))))

(defun flymake-languagetool--checker (report-fn &rest _args)
  "Diagnostic checker function with REPORT-FN."
  (setq flymake-languagetool--source-buffer (current-buffer))
  (cond
   ((flymake-languagetool--reachable-p)
    (flymake-languagetool--check report-fn))
   ((or flymake-languagetool-server-command flymake-languagetool-server-jar)
    (flymake-languagetool--start-server report-fn))
   (t (funcall report-fn :panic :explanation
               (format "Cannot reach LanguageTool URL: %s"
                       flymake-languagetool-url)))))

(defun flymake-languagetool--ovs (&optional format)
  "List of all `flymake-languagetool' diagnostic overlays."
  (let* ((n 1)
         (ovs (flymake--overlays
               :filter (lambda (ov)
                         (when-let ((diag (overlay-get ov 'flymake-diagnostic)))
                           (eq (flymake-diagnostic-backend diag)
                               'flymake-languagetool--checker)))
               :compare (if (cl-plusp n) #'< #'>)
               :key #'overlay-start)))
    (if format
        (seq-map
         (lambda (ov) (cons (format "%s: %s"
                                    (line-number-at-pos (overlay-start ov))
                                    (flymake-diagnostic-text
                                     (overlay-get ov 'flymake-diagnostic)))
                            ov))
         ovs)
      ovs)))

(defvar-local flymake-languagetool-current-cand nil
  "Current overlay candidate.")

(defun flymake-languagetool--ov-at-point ()
  "Return `flymake-languagetool' overlay at point."
  (setq flymake-languagetool-current-cand
        (car (flymake--overlays
              :beg (point)
              :filter
              (lambda (ov)
                (let ((diag (overlay-get ov 'flymake-diagnostic)))
                  (eq (flymake-diagnostic-backend diag)
                      'flymake-languagetool--checker)))))))

(defun flymake-languagetool--suggestions ()
  "Show corrections suggested from LanguageTool."
  (overlay-put flymake-languagetool-current-cand 'face 'isearch)
  (let ((sugs (map-elt (flymake-diagnostic-data
                        (overlay-get flymake-languagetool-current-cand
                                     'flymake-diagnostic))
                       'suggestions)))
    (cl-remove-if #'null `(,@sugs "Ignore Rule" "Ignore Category"))))

(defun flymake-languagetool--clean-overlay ()
  "Remove highlighting of current candidate."
  (ignore-errors
    (overlay-put flymake-languagetool-current-cand 'face 'flymake-warning))
  (setq flymake-languagetool-current-cand nil))

(defun flymake-languagetool--check-buffer ()
  (when (bound-and-true-p flymake-mode)
    (flymake-start)))

(defun flymake-languagetool--ignore (ov id type)
  (let ((desc (map-elt (flymake-diagnostic-data
                        (overlay-get ov 'flymake-diagnostic))
                       'rule-desc)))
    (when (eq type 'Rule)
      (make-local-variable 'flymake-languagetool-disabled-rules)
      (add-to-list 'flymake-languagetool-disabled-rules id))
    (when (eq type 'Category)
      (make-local-variable 'flymake-languagetool-disabled-categories)
      (add-to-list 'flymake-languagetool-disabled-categories id))
    (flymake-languagetool--check-buffer)
    (message "%s %s: (%s) has been disabled" type id desc)
    (flymake-languagetool--clean-overlay)))

(defun flymake-languagetool--correct (ov choice)
  (let ((start (overlay-start ov))
        (end (overlay-end ov)))
    (delete-region start end)
    (goto-char start)
    (insert choice))
  (flymake-languagetool--clean-overlay))

;;; Corrections

;;;###autoload
(defun flymake-languagetool-next (&optional n)
  "Go to Nth next flymake languagetool error."
  (interactive (list (or current-prefix-arg 1)))
  (let* ((ovs (flymake-languagetool--ovs))
         (tail (cl-member-if (lambda (ov)
                               (if (cl-plusp n)
                                   (> (overlay-start ov) (point))
                                 (< (overlay-start ov) (point))))
                             ovs))
         (chain (if flymake-wrap-around
                    (if tail
                        (progn (setcdr (last tail) ovs) tail)
                      (and ovs (setcdr (last ovs) ovs)))
                  tail))
         (target (nth (1- n) chain)))
    (goto-char (overlay-start target))))

;;;###autoload
(defun flymake-languagetool-previous (&optional n)
  "Go to Nth previous flymake languagetool error."
  (interactive (list (or current-prefix-arg 1)))
  (flymake-languagetool-next (- n)))

;;;###autoload
(defun flymake-languagetool-correct-at-point (&optional ol)
  "Correct `flymake-languagetool' diagnostic at point.
Use OL as diagnostic if non-nil."
  (interactive)
  (if-let (flymake-languagetool-current-cand
           (or ol (flymake-languagetool--ov-at-point)))
      (condition-case nil
          (when-let*
              ((ov flymake-languagetool-current-cand)
               (type (map-elt (flymake-diagnostic-data
                               (overlay-get ov 'flymake-diagnostic))
                              'type))
               (sugs (flymake-languagetool--suggestions))
               (prompt (flymake-diagnostic-text
                        (overlay-get ov 'flymake-diagnostic)))
               (id (map-elt (flymake-diagnostic-data
                             (overlay-get ov 'flymake-diagnostic))
                            'rule-id))
               (choice (completing-read
                        (format "Correction (%s): " prompt) sugs)))
            (pcase choice
              ("Ignore Rule" (flymake-languagetool--ignore ov id 'Rule))
              ("Ignore Category"
               (flymake-languagetool--ignore ov id 'Category))
              (_ (flymake-languagetool--correct ov choice))))
        (t (flymake-languagetool--clean-overlay)))
    (user-error "No correction at point")))

;;;###autoload
(defun flymake-languagetool-correct ()
  "Use `completing-read' to select and correct diagnostic."
  (interactive)
  (let* ((cands (flymake-languagetool--ovs 'format))
         (cand (if cands
                   (completing-read "Error: " cands)
                 (user-error "No candidates")))
         (ov (map-elt cands cand)))
    (save-excursion
      (goto-char (overlay-start ov))
      (condition-case nil
          (funcall #'flymake-languagetool-correct-at-point ov)
        (quit (flymake-languagetool--clean-overlay))
        (t (flymake-languagetool--clean-overlay))))))

;;;###autoload
(defun flymake-languagetool-correct-dwim ()
  "DWIM function for correcting `flymake-languagetool' diagnostics."
  (interactive)
  (if-let ((ov (flymake-languagetool--ov-at-point)))
      (funcall #'flymake-languagetool-correct-at-point ov)
    (funcall-interactively #'flymake-languagetool-correct)))


;;; Entry

;;;###autoload
(defun flymake-languagetool-load ()
  "Convenience function to setup flymake-languagetool.
This adds the language-tool checker to the list of flymake diagnostic
functions."
  (add-hook 'flymake-diagnostic-functions #'flymake-languagetool--checker nil t))

;;;###autoload
(defun flymake-languagetool-maybe-load ()
  "Load backend if major-mode in `flymake-languagetool-active-modes'"
  (interactive)
  (when (memq major-mode flymake-languagetool-active-modes)
    (flymake-languagetool-load)))

(provide 'flymake-languagetool)
;;; flymake-languagetool.el ends here
