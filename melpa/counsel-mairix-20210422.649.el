;;; counsel-mairix.el --- Counsel interface for Mairix -*- lexical-binding: t -*-

;; Copyright (c) 2020 Antoine Kalmbach

;; Author: Antoine Kalmbach <ane@iki.fi>
;; URL: https://sr.ht/~ane/counsel-mairix
;; Package-Version: 20210422.649
;; Package-Commit: 39fa2ad10a5f899cb3f3275f9a6ebd166c51216a
;; Created: 2020-10-10
;; Version: 0.1
;; Keywords: mail
;; Package-Requires: ((emacs "26.3") (ivy "0.13.1"))

;; This file is not part of GNU Emacs.

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

;; counsel-mairix is an ivy interface for mairix.  Invoke `counsel-mairix' to
;; start a search with an ivy interface.  counsel-mairix builds upon the
;; built-in mairix support in Emacs, adding a fast interactive searching
;; mechanism using the ivy completion engine.
;;
;; counsel-mairix provides the following functions:
;;
;;   * `counsel-mairix' - run mairix search interactively
;;   * `counsel-mairix-save-search' - save a mairix search from your history
;;   * `counsel-mairix-search-from' - start a search using the `From' header
;;   * `counsel-mairix-search-thread' - start a search using the message id,
;;     with threads enabled
;;
;; For counsel-mairix to work one only needs to have configured Mairix properly,
;; see Info node `(mairix-el) Configuring mairix'.

;;; Code:
(require 'cl-lib)
(require 'cl-generic)
(require 'mairix)
(require 'ivy)
(require 'rmail)
(require 'subr-x)
(require 'seq)


;; Custom stuff.
(defgroup counsel-mairix nil
  "Options for counsel-mairix."
  :group :mail
  :prefix "counsel-mairix-")

(defcustom counsel-mairix-mail-frontend nil
  "Mail program to display search results.
The default is to defer to `mairix-mail-program', which is probably a good idea,
because the format used by Mairix might not be compatible with
the frontend set here."
  :type '(choice (const :tag "Default (i.e. nil) to `mairix-mail-program'" nil)
                 (const :tag "RMail" rmail)
		 (const :tag "Gnus mbox" gnus)
		 (const :tag "VM" vm))
  :group 'counsel-mairix)

(defcustom counsel-mairix-include-threads 'prompt
  "Whether to prompt the user for including threads in the Mairix search.

If set to 'prompt, prompt the user.  If set to 'always, always
include threads.  If set to 'never, never prompt for threads."
  :type '(choice (const :tag "Prompt" prompt)
                 (const :tag "Always" t)
                 (const :tag "Never" nil))
  :group 'counsel-mairix)


;; Generic methods that form the backbone of the search mechanism.
(cl-defgeneric counsel-mairix-run-search (frontend search-string threads)
  "Run Mairix with the search string SEARCH-STRING using FRONTEND.

Include threads in the result if THREADS is non-nil.")

(cl-defgeneric counsel-mairix-display-result-message (message)
  "Display MESSAGE using the right frontend.")

(defun counsel-mairix-determine-frontend ()
  "Try to compute the frontend that the user of Mairix is using."
  (or counsel-mairix-mail-frontend
      mairix-mail-program))

(defun counsel-mairix-search-file ()
  "Get the full path to the Mairix search file as given by `mairix-file-path' and `mairix-search-file'."
  (concat (file-name-as-directory (expand-file-name mairix-file-path))
          mairix-search-file))


;;; Rmail implementation of counsel-mairix.

(cl-defstruct counsel-mairix-rmail-result
  "A Mairix result entry to be displayed in Rmail."
  mbox-file msgnum)



(cl-defmethod counsel-mairix-run-search ((_ (eql rmail)) search-string threads)
  "Perform a Mairix search using SEARCH-STRING using Rmail.

If THREADS is non-nil, include threads."
  (require 'rmail)
  (let* ((search-file (counsel-mairix-search-file))
         (large-file-warning-threshold nil)
         (revert-without-query (list (regexp-quote mairix-search-file)))
         (rmail-display-summary t)
         results)
    (progn
      ;; Were we looking at a search file? If so, make a
      ;; copy of it, so if no results appear, we don't lose
      ;; results.
      (when (mairix-call-mairix search-string nil threads)
        (save-window-excursion
          (save-excursion
            (widen)
            (rmail search-file)
            (when rmail-buffer
              (set-buffer rmail-buffer)
              (when rmail-summary-buffer
                (with-current-buffer rmail-summary-buffer
                  (font-lock-ensure)
                  (setq results (split-string (buffer-string) "\n"))))))))
      (if (not (null results))
          (mapcar
           (lambda (str)
             (when-let ((num (string-to-number (substring str 0 6)))
                        (res (make-counsel-mairix-rmail-result
                              :msgnum num :mbox-file search-file)))
               ;; Counsel doesn't support rich results so we have to stuff things
               ;; into text properties.
               (propertize str 'result res)))
           (seq-remove #'string-empty-p results))))))

(defvar counsel-mairix-ephemeral-search-buffer nil
  "Buffer name to hold the current search result.

Prevent `\\[ivy-next-line-and-call]' (etc.) opening a new buffer
every time.")

(cl-defmethod counsel-mairix-display-result-message ((result counsel-mairix-rmail-result))
  "Display RESULT using Rmail."
  (require 'rmail)
  (let* ((large-file-warning-threshold nil)
         (res (counsel-mairix-rmail-result-mbox-file result))
         (num (counsel-mairix-rmail-result-msgnum result))
         (inhibit-message t)
         
         (tmp (if (bufferp counsel-mairix-ephemeral-search-buffer)
                  (buffer-file-name counsel-mairix-ephemeral-search-buffer)
                (expand-file-name (make-temp-name mairix-search-file)
                                  temporary-file-directory)))
         (revert-without-query (list (regexp-quote
                                      (file-name-nondirectory tmp)))))
    ;; make a copy of the search file, since if we start
    ;; a new search, the displayed message will disappear
    (copy-file res tmp t)
    (rmail tmp)
    (rmail-show-message num nil)
    (setq counsel-mairix-ephemeral-search-buffer rmail-buffer)))


;; Gnus implementation of the generic methods.
;; TODO...


;; VM implementation of the generic methods.
;; TODO...


;; The main implementation.

(defun counsel-mairix-do-search (str)
  "Either wait for more chars using `ivy-more-chars' or perform the search using STR after determining the correct search backend."
  (or (ivy-more-chars)
      (counsel-mairix-run-search (counsel-mairix-determine-frontend) str counsel-mairix-include-threads)
      '("" "Searching...")))

(cl-defmethod counsel-mairix-display-result-message ((result string))
  "Dispatch to `counsel-mairix-display-result-message' using the RESULT class stored in the 'result property of the search result, since the result class is stored there."
  (when-let (res (get-text-property 0 'result result))
    (counsel-mairix-display-result-message res)))

(defvar counsel-mairix-save-search-history ()
  "History for `counsel-mairix-save-search'.")

(defun counsel-mairix-save-search-action (search)
  "Save SEARCH as a Mairix search."
  (let ((mairix-last-search search))
    (mairix-save-search)))

(defvar counsel-mairix-history ()
  "History for `counsel-mairix'.")

(defun counsel-mairix-save-search ()
  "Save a search from the history of `counsel-mairix'.

If `counsel-mairix-history' is empty, save `mairix-last-search'."
  (interactive)
  (when (and (not counsel-mairix-history)
             (not mairix-last-search))
    (user-error "No counsel-mairix history or last mairix search to save from"))
  (let ((enable-recursive-minibuffers t))
    (ivy-read "Save search: "
              (or (seq-reverse
                   (mapcar #'substring-no-properties
                           (seq-filter
                            (lambda (item)
                              (and (stringp item)
                                   (get-text-property 0 'ivy-index item)))
                            counsel-mairix-history)))
                  (list (car-safe mairix-last-search)))
              :require-match t
              :action #'counsel-mairix-save-search-action
              :caller 'counsel-mairix-save-search
              :history 'counsel-mairix-save-search-history)))

(defun counsel-mairix--get-field (field)
  "Return the header FIELD from the current message."
  (let ((get-mail-header
         (cadr (assq (counsel-mairix-determine-frontend)
                     mairix-get-mail-header-functions))))
    (if get-mail-header
        (mail-strip-quoted-names
         (funcall get-mail-header field))
      (error "No function for getting headers"))))


(defun counsel-mairix--insert-pattern (pattern new)
  "If we can see PATTERN behind us, add to it.

If something is between point and PATTERN, add a comma.

Unless NEW non-nil, then insert a new pattern."
  (if (not new)
      (let* ((pat (concat (regexp-quote pattern)
                          "\\(.*\\)?")))
        (when (and (save-excursion
                     (and (re-search-backward pat nil t)
                          (not (string-empty-p
                                (match-string-no-properties 1)))))
                   (not (looking-back "[, ]" 1)))
          (insert ",")))
    (insert pattern)))

(defun counsel-mairix--ivy-yank-field (pattern field new &optional process)
  "Use `with-ivy-window' to get FIELD from the current message.

If prefix argument is given, insert search PATTERN before the data.

If PROCESS is given, apply that function to the field value
before formating it."
  (let (from)
    (with-ivy-window
      (setq from (counsel-mairix--get-field field)))
    (when from
      (counsel-mairix--insert-pattern pattern new)
      
      (when (= -1 (prefix-numeric-value current-prefix-arg))
        (insert "~"))
      
      (insert (if process
                  (funcall process from)
                from)))
    
    (with-ivy-window
      (when-let ((bounds (counsel-mairix--field-bounds field)))
        (let ((ivy-pulse-delay (when (numberp ivy-pulse-delay) 1.5)))
          (ivy--pulse-region (car bounds) (cdr bounds)))))))

(defun counsel-mairix-insert-from (new)
  "Insert the `From:' field of a mail message into the minibuffer.
Argument NEW means insert mairix search term `f:' as well, even
if it is already inserted"
  (interactive "P")
  (counsel-mairix--ivy-yank-field "f:" "from" new))

(defun counsel-mairix-insert-to (new)
  "Insert the `Subject:' field of a mail message into the minibuffer.
Argument NEW means insert mairix search term `t:' as well, even
if it is already inserted."
  (interactive "P")
  (counsel-mairix--ivy-yank-field "t:" "to" new))

(defun counsel-mairix-insert-subject (new)
  "Insert the `Subject:' field of a mail message into the minibuffer.
Argument NEW means insert mairix search term `s:' as well, even
if it is already inserted."
  (interactive "P")
  (counsel-mairix--ivy-yank-field "s:" "subject" new))

(defun counsel-mairix-insert-message-id (new)
  "Insert the `Message-Id:' field of a mail message into the minibuffer.
Argument NEW means insert mairix search term `m:' as well, even
if it is already inserted."
  (interactive "P")
  (counsel-mairix--ivy-yank-field "m:" "message-id" new))

(defun counsel-mairix-toggle-threads ()
  "Toggle threading on or off in the current search."
  (interactive)
  (let ((threads (if (eq 'prompt counsel-mairix-include-threads)
                     t
                   (not counsel-mairix-include-threads))))
    (setq-local counsel-mairix-include-threads threads)
    (ivy--reset-state ivy-last)))

(defun counsel-mairix-save-current-search ()
  "Save the current search, prompting for its name."
  (interactive)
  (let ((enable-recursive-minibuffers t))
    (let ((mairix-last-search ivy-text))
      (mairix-save-search))))

(defun counsel-mairix-insert-saved-search ()
  "Insert a saved mairix search."
  (interactive)
  (let ((enable-recursive-minibuffers t)
        (searches (mapcar #'cdr mairix-saved-searches)))
    (insert (completing-read "Insert Mairix search: "
                             searches
                             nil t))))

(declare-function avy-process "ext:avy.el")
(declare-function avy-jump "ext:avy.el")

;;; avy interface -- these features do nothing if avy isn't installed
(defun counsel-mairix--field-bounds (field)
  "Get the bounds for FIELD in the address.

Returns the `(start . end)' of the data for the email field."
  (let ((case-fold-search t)
        (name (concat "^" (regexp-quote field) "[ \t]*:[ \t]*"))
        start end)
    (save-excursion
      (save-restriction
        (goto-char (point-min))
        (when (re-search-forward name nil t)
          (setq start (point))
          (while (progn (forward-line 1)
                        (looking-at "[ \t]")))
          (forward-char -1)
          (setq end (point)))))
    (when (and start end)
      (cons start end))))

(defun counsel-mairix--avy-address (field)
  "Present an avy jump tree for addresses in FIELD.

Each tree leaf will return one email address selected by the user."
  (let ((bounds (counsel-mairix--field-bounds field)))
    (when (and bounds (consp bounds))
      (let* ((start (car bounds)) (end (cdr bounds))
             (addresses (buffer-substring-no-properties start end))
             ;; FIXME is there a smarter way to do this?  This basically strips
             ;; all names from the addresses, so you end up with foo@bar.com
             ;; stuff, and we just find out where those addresses are.
             (stripped (mail-strip-quoted-names addresses))
             (addrs (split-string stripped ","))
             cands)
        (save-excursion
          (save-restriction
            (narrow-to-region start end)
            (goto-char (point-min))
            (dolist (addr addrs)
              (when (re-search-forward
                     (regexp-quote (string-trim addr)) nil t)
                (push (cons (match-beginning 0) (match-end 0))
                      cands)))))
        (let ((res (avy-process (nreverse cands))))
          (if-let ((from (car-safe res))
                   (to (cdr-safe res)))
              (progn
                ;; FIXME give mairix some time to rest, so that the
                ;; pulse is visible - is there a hook for this? could then
                ;; just pulse it once mairix is finished
                (let ((ivy-pulse-delay (when (numberp ivy-pulse-delay) 1.5)))
                  (ivy--pulse-region from to))
                (buffer-substring-no-properties from to))
            (message "No addresses to yank in this buffer")))))))

(defmacro counsel-mairix-with-avy (&rest body)
  "Execute BODY if avy is intalled."
  (declare (indent 0) (debug t))
  `(if (require 'avy nil t)
       ,@body
     (message "avy not installed")))

(defmacro counsel-mairix-defavy (name field pat)
  "Create an avy search for yanking an address from FIELD.

NAME is the name of the binding, and PAT is the pattern to use
when inserting searches."
  (declare (debug t))
  (let ((pattern (cl-gensym "pattern")))
    `(defun ,name (,pattern)
       ,(format "Yank an address from field `%s' using avy.

If PATTERN is non-nil, insert `%s' before the yanked result
if it's not already inserted." (capitalize field) pat)
       (interactive "P")
       (if (require 'avy nil t)
           (progn
             (let (res)
               (with-ivy-window
                 (setq res (counsel-mairix--avy-address ,field)))
               (when res
                 (counsel-mairix--insert-pattern ,pat ,pattern)
                 (when (= -1 (prefix-numeric-value current-prefix-arg))
                   (insert "~"))
                 (insert (replace-regexp-in-string "~" "\\~" res nil 'literal)))))
         (message "avy not installed")))))

(counsel-mairix-defavy counsel-mairix-avy-from "from" "f:")
(counsel-mairix-defavy counsel-mairix-avy-to "to" "t:")
(counsel-mairix-defavy counsel-mairix-avy-cc "cc" "c:")

(defun counsel-mairix--avy-yank-word (bounds)
  "Avy a word within BOUNDS."
  (when-let ((beg (car-safe bounds))
             (end (cdr-safe bounds))
             (word (avy-jump "\\b\\(\\w+\\)\\b"
                             :window-flip t
                             :beg beg
                             :end end)))
    (when (consp word)
      (ivy--pulse-region (car word) (cdr word))
      (buffer-substring-no-properties
       (car word) (cdr word)))))

(defun counsel-mairix-avy-subject-word (pattern)
  "Avy search a single word from the subject.

If PATTERN is non-nil, insert \"s:\" into the search query
if not already present. With negative prefix argument
`\\[negative-argument]' negate the pattern by inserting `~'."
  (interactive "P")
  (counsel-mairix-with-avy
    (let ((subjpat "s:")
          yanked)
      (with-ivy-window
        (setq yanked (counsel-mairix--avy-yank-word
                      (counsel-mairix--field-bounds "subject"))))
      (when yanked
        (counsel-mairix--insert-pattern subjpat pattern)
        (when (= -1 (prefix-numeric-value current-prefix-arg))
          (insert "~"))
        (insert yanked)))))

(defun counsel-mairix-avy-body-word (pattern)
  "Avy search a single word from the body.

If PATTERN is non-nil, insert `b:' before the query if it's not
already inserted."
  (interactive "P")
  (counsel-mairix-with-avy
    (let ((bodypat "b:")
          yanked)
      (with-ivy-window
        (setq yanked
              (counsel-mairix--avy-yank-word
               (save-excursion
                 (save-restriction
                   (goto-char (point-min))
                   (re-search-forward "\n\n" nil t)
                   (cons (point) (point-max)))))))
      (when yanked
        (counsel-mairix--insert-pattern bodypat pattern)
        (when (= -1 (prefix-numeric-value current-prefix-arg))
          (insert "~"))
        (insert yanked)))))

(defvar counsel-mairix-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-f f") 'counsel-mairix-insert-from)
    (define-key map (kbd "C-c C-f t") 'counsel-mairix-insert-to)
    (define-key map (kbd "C-c C-f i") 'counsel-mairix-insert-message-id)
    (define-key map (kbd "C-c C-f s") 'counsel-mairix-insert-subject)
    (define-key map (kbd "C-c C-t")   'counsel-mairix-toggle-threads)
    (define-key map (kbd "C-c C-s s") 'counsel-mairix-save-current-search)
    (define-key map (kbd "C-c C-s i") 'counsel-mairix-insert-saved-search)
    (define-key map (kbd "C-c C-a t") 'counsel-mairix-avy-to)
    (define-key map (kbd "C-c C-a c") 'counsel-mairix-avy-cc)
    (define-key map (kbd "C-c C-a f") 'counsel-mairix-avy-from)
    (define-key map (kbd "C-c C-a s") 'counsel-mairix-avy-subject-word)
    (define-key map (kbd "C-c C-a b") 'counsel-mairix-avy-body-word)
    map)
  "Keymap for `counsel-mairix'.")

(defun counsel-mairix-cleanup ()
  "Unwind forms after quitting `counsel-mairix'."
  (when-let ((search (find-buffer-visiting
                      (expand-file-name mairix-search-file
                                        mairix-file-path))))
    (kill-buffer search)))

;;;###autoload
(defun counsel-mairix (&optional initial-input)
  "Search using Mairix with an Counsel frontend.
It will determine the correct backend automatically based on the variable
`mairix-mail-program', this can be overridden using
`counsel-mairix-mail-frontend'.

'counsel-mairix' should support the same backends as mairix itself,
which are known to be Rmail (default), Gnus and VM.  Currently
only Rmail is supported.

If `counsel-mairix-include-threads' is nil, don't include threads
when searching with Mairix.  If it is t, always include
threads.  If it is prompt (the default), ask whether to include
threads or not.

If INITIAL-INPUT is given, the search has that as the initial input."
  (interactive)
  (let ((counsel-mairix-include-threads
         (if (eq 'prompt counsel-mairix-include-threads)
             (y-or-n-p "Include threads? ")
           counsel-mairix-include-threads))
        (enable-recursive-minibuffers t))
    (ivy-read "Mairix query: " #'counsel-mairix-do-search
              :dynamic-collection t
              :initial-input initial-input
              :action #'counsel-mairix-display-result-message
              :keymap counsel-mairix-map
              :unwind 'counsel-mairix-cleanup
              :history 'counsel-mairix-history
              :caller 'counsel-mairix)))

(defun counsel-mairix-search-from ()
  "Run `counsel-mairix' with the `From' header as the initial input."
  (interactive)
  (counsel-mairix
   (format "f:%s" (counsel-mairix--get-field "from"))))

(defun counsel-mairix-search-thread ()
  "Run `counsel-mairix' with the `Message-Id' header, with threading."
  (interactive)
  (let ((counsel-mairix-include-threads t))
    (counsel-mairix (format "m:%s" (counsel-mairix--get-field "message-id")))))

(provide 'counsel-mairix)

;;; counsel-mairix.el ends here
