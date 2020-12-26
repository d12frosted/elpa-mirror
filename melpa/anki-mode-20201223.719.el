;;; anki-mode.el --- A major mode for creating anki cards -*- lexical-binding: t; -*-

;; Copyright © 2017 David Shepherd

;; Author: David Shepherd <davidshepherd7@gmail.com>
;; Version: 0.1
;; Package-Version: 20201223.719
;; Package-Commit: d9b84028cd6a1ae040fb5604080a8b5fa8138562
;; Package-Requires: ((emacs "24.4") (dash "2.12.0") (markdown-mode "2.2") (s "1.11.0") (request "0.3.0"))
;; Keywords: tools
;; URL: https://github.com/davidshepherd7/anki-mode

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

;; A major mode for creating Anki cards.
;;
;; Requires Anki to be running, with the anki-connect addon installed.
;;
;; Usage: call `anki-mode-menu' to begin.

;;; Code:

(require 'markdown-mode)
(require 'dash)
(require 's)
(require 'request)
(require 'json)

(eval-when-compile
  (require 'cl-lib))

;; (setq request-log-level 'debug)
;; (setq request-message-level 'debug)



(defvar anki-mode--required-anki-connect-version 6
  "Version of the anki connect plugin required.")

(defvar anki-mode--decks '()
  "List of anki deck names.")

(defvar anki-mode--card-types '()
  "List of anki card type names and their fields.")

(defvar anki-mode--previous-deck nil
  "The most recently selected deck.")

(defvar anki-mode--previous-card-type nil
  "The most recently selected card type.")

(defvar anki-mode--deck nil
  "Buffer local variable containing the current deck.")

(defvar anki-mode--card-type nil
  "Buffer local variable containing the current card type.")

(defvar anki-mode--log-requests nil
  "If non-nil anki-mode will log all http requests and responses.")

(defconst anki-mode--field-start-regex "^\\s-*@")




(defgroup anki nil
  "Customisation options for interacting with Anki, a spaced repetition flashcard program."
  :group 'external
  :prefix "anki-mode-")

(defcustom anki-mode-markdown-command "pandoc --from gfm --to html"
  "Markdown command to run to convert markdown to html.

Use pandoc by default because it can do sensible things with underscores in LaTeX."
  :group 'anki
  :type 'string)



;;; Interface

;; github flavoured markdown mode instead of markdown mode because it works with
;; underscores, which come up a lot in LaTeX maths and when talking about code.
(define-derived-mode anki-mode gfm-mode "Anki")

(define-key anki-mode-map (kbd "C-c C-c") #'anki-mode-send-new-card)
(define-key anki-mode-map (kbd "$") #'anki-mode-insert-latex-math)
(define-key anki-mode-map (kbd "<tab>") #'anki-mode-next-field)

(defun anki-mode-insert-latex-math ()
  "Wrap region with [$][/$] (LaTeX math markers)."
  (interactive)
  (if (use-region-p)
      (save-excursion
        (goto-char (region-beginning))
        (insert "[$]")
        (goto-char (region-end))
        (insert "[/$]"))
    ;; else
    (insert "[$][/$]")
    (forward-char -4)))

(defun anki-mode-next-field ()
  "Go to next anki card field."
  (interactive)
  (goto-char
   (save-excursion
     (or (search-forward-regexp anki-mode--field-start-regex nil t)
         (progn (goto-char (point-min))
                (search-forward-regexp anki-mode--field-start-regex nil t)))))
  (forward-line))

;;;###autoload
(defun anki-mode-new-card ()
  "Create a buffer for a new Anki card."
  (interactive)

  (unless anki-mode--decks (anki-mode-refresh))

  (let ((deck (completing-read "Choose deck: " anki-mode--decks))
        (card-type (completing-read "Choose card type: "
                                    (-map #'car anki-mode--card-types))))

    (setq anki-mode--previous-deck deck)
    (setq anki-mode--previous-card-type card-type)

    (anki-mode-new-card-noninteractive deck card-type)))


;;;###autoload
(defun anki-mode-menu ()
  "Open an Anki menu buffer."
  (interactive)
  (switch-to-buffer (anki-mode-menu-buffer))
  (unless (anki-mode-initial-load-done-p)
    (anki-mode-refresh))
  (anki-mode-menu-render))




;;; Menu page

(defun anki-mode-initial-load-done-p ()
  "Check if data has been loaded from Anki connect."
  (and anki-mode--card-types anki-mode--decks anki-mode--card-types))

(define-derived-mode anki-mode-menu-mode special-mode "Anki Menu"
  "Major mode for the anki-mode menu page.")

(define-key anki-mode-menu-mode-map (kbd "n") #'anki-mode-new-card)
(define-key anki-mode-menu-mode-map (kbd "r") (lambda ()
                                            (interactive)
                                            (anki-mode-refresh)
                                            (anki-mode-menu-render)))
(define-key anki-mode-menu-mode-map (kbd "a") (lambda ()
                                            (interactive)
                                            (when (not (and anki-mode--previous-deck anki-mode--previous-card-type))
                                              (error "Can't reuse the previous options because no previous deck/card type is set"))
                                            (anki-mode-new-card-noninteractive
                                             anki-mode--previous-deck
                                             anki-mode--previous-card-type)))

(defun anki-mode-menu-buffer ()
  "Get or create the Anki mode menu buffer."
  (or (get-buffer "*Anki*")
      (with-current-buffer (get-buffer-create "*Anki*")
        (anki-mode-menu-mode)
        (current-buffer))))

(defun anki-mode-menu-render ()
  "Render the Anki mode menu into the current buffer."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert "Anki Mode\n")
    (insert "---------------\n")
    (insert "[n]: New card\n")
    (insert "[a]: New card with current settings (deck: '"
            (or anki-mode--previous-deck "NULL")
            "', card type: '"
            (or anki-mode--previous-card-type "NULL")
            "')\n")
    (insert "[r]: Refresh decks list\n")
    (insert "\n\n\n")
    (insert "Decks\n")
    (insert "---------------\n")
    (--each anki-mode--decks (insert "* ") (insert it) (insert "\n"))))



;;; Anki-connect helpers

(defun anki-mode-connect (callback method params sync)
  "Send a request to the anki-connect extension running inside Anki.

Sends a request to run METHOD with the provided PARAMS.

If SYNC is non-nil the request will be made synchronously.

When done CALLBACK will be called."
  (let ((data (--> (list (cons "action" method)
                         (cons "version" anki-mode--required-anki-connect-version))
                   (-concat it (if params (list (cons "params" params)) (list)))
                   (json-encode it)
                   (encode-coding-string it 'utf-8))))
    (when anki-mode--log-requests
      (message "Anki connect sending %S" data))
    (request "http://localhost:8765"
             :type "POST"
             :data data
             :headers '(("Content-Type" . "application/json"))
             :parser 'json-read
             :sync sync
             :success (anki-mode--http-success-factory callback)
             :error  (cl-function
                      (lambda (&key error-thrown &allow-other-keys)
                        (message "Anki mode http request failed, is anki running and is the anki-connect extension installed?\nrequest.el error was: %S, request.el normally uses the curl backend so check the curl manual for the meaning of exit codes."
                                 error-thrown)
                        ;; NOTE: (error "...") doesn't seem to work here,
                        ;; probably something to do with how async requests work.
                        )))))

(defun anki-mode--http-success-factory (callback)
  (cl-function
   (lambda (&key data &allow-other-keys)
     (when anki-mode--log-requests
       (message "Anki connect recv %S" data))
     (when (not data)
       (message "Warning: anki-mode-connect got null data, this probably means a bad query was sent"))

     (let ((the-error (cdr (assoc 'error data)))
           (the-result (cdr (assoc 'result data))))
       (when the-error
         (error "Anki connect returned error: %S" the-error))
       (funcall callback the-result)))))

(defun anki-mode-refresh ()
  "Refresh data from Anki."
  (interactive)
  (anki-mode-check-version)
  (anki-mode-update-decks)
  (anki-mode-update-card-types))

(defun anki-mode--vector-to-list (vec)
  (append vec nil))

(defun anki-mode-check-version ()
  "Check that the available version of anki-connect is supported."
  (interactive)
  (anki-mode-connect #'anki-mode--check-version-cb "version" nil t))
(defun anki-mode--check-version-cb (version)
  (when (not (= version anki-mode--required-anki-connect-version))
    (message "Warning you have anki connect version %S installed, but %S is required"
             version anki-mode--required-anki-connect-version)))

(defun anki-mode-update-decks ()
  "Load/refresh list of decks from Anki."
  (interactive)
  (anki-mode-connect #'anki-mode--update-decks-cb "deckNames" nil t))
(defun anki-mode--update-decks-cb (decks)
  (setq anki-mode--decks (anki-mode--vector-to-list decks)))


(defun anki-mode-update-card-types ()
  "Load/refresh list of card-types from Anki."
  (interactive)
  (anki-mode-connect #'anki-mode--update-card-types-cb-1 "modelNames" nil t))
(defun anki-mode--update-card-types-cb-1 (card-names)
  (-each (anki-mode--vector-to-list card-names)
    (lambda (card-name)
      (anki-mode-connect (lambda (fields) (anki-mode--update-card-types-cb-2 card-name fields)) "modelFieldNames" (list (cons "modelName" card-name)) t))))
(defun anki-mode--update-card-types-cb-2 (card-name fields)
  (let ((item (assoc card-name anki-mode--card-types)))
    (if item
        (setf (cdr item) (anki-mode--vector-to-list fields))
      (push (cons card-name (anki-mode--vector-to-list fields))
            anki-mode--card-types))))





;;; Card creation

(defun anki-mode-new-card-noninteractive (deck card-type)
  (find-file (make-temp-file "anki-card-"))
  (anki-mode)
  (setq-local anki-mode--deck deck)
  (setq-local anki-mode--card-type card-type)

  (let ((card-fields (assoc anki-mode--card-type anki-mode--card-types)))
    (unless card-fields
      (error "Unrecognised card type: \"%s\"" anki-mode--card-type))
    (-each (cdr card-fields)
      (lambda (field)
        (insert (s-concat "@" field "\n\n\n")))))

  (goto-char (point-min))
  (forward-line 1))

(defun anki-mode--markdown (string)
  (with-temp-buffer
    (insert string)
    (shell-command-on-region (point-min) (point-max) anki-mode-markdown-command (buffer-name))
    (s-trim (buffer-string))))

(defun anki-mode-create-card (deck model fields)
  (save-buffer)
  (let ((md-fields (-map (lambda (pair) (cons (car pair) (anki-mode--markdown (cdr pair)))) fields))
        ;; Unfortunately emacs lisp doesn't distinguish between {"notes" :
        ;; [...]} and ["notes", ...] in alists or plists, so we have to use a
        ;; hash table for this.
        (hash-table (make-hash-table)))
    (puthash 'notes `(((deckName . ,deck)
                       (modelName . ,model)
                       (tags . [])
                       ;; Can't unquote to use json-false in #s, so just use the literal keyword
                       (options . #s(hash-table data (allowDuplicate :json-false)))
                       (fields . ,md-fields))) hash-table)
    (anki-mode-connect #'anki-mode--create-card-cb "addNotes" hash-table t)))

(defun anki-mode--create-card-cb (ret)
  ;; We can't emit errors from here because it runs async, so a message is the
  ;; best we can do
  (if (equal (format "%S" ret) "[nil]")
      (message "Card creation returned a null card id, normally this means that the card already exists")
    (message "Created card, got back %S" ret)
    (anki-mode-menu)))

(defun anki-mode--parse-fields (string)
  (--> string
       (s-split anki-mode--field-start-regex it)
       (-map #'s-trim it)
       (-filter (lambda (field) (not (s-blank? field))) it)
       (-map (lambda (field) (s-split-up-to "\n" field 1)) it)
       (-map #'anki-mode--list-to-pair it)))

(defun anki-mode--list-to-pair (li)
  (cons (car li) (or (cadr li) "")))

;;;###autoload
(defun anki-mode-send-new-card ()
  "Send the current buffer as a card to anki-connect."
  (interactive)
  (anki-mode-create-card anki-mode--deck anki-mode--card-type (anki-mode--parse-fields (buffer-substring-no-properties (point-min) (point-max)))))



;;; Cloze helpers

(defun anki-mode--max-cloze ()
  (--> (buffer-substring-no-properties (point-min) (point-max))
       (s-match-strings-all "{{c\\([0-9]+?\\)::" it)
       (-map #'cadr it) ; First group of each match
       (-map #'string-to-number it)
       (or it '(0))
       (-max it)))

(defun anki-mode-cloze-region (start end)
  "Wrap the START to END or current region in a new cloze tag."
  (interactive "r")
  (save-excursion
    ;; Do end first because inserting at start moves end
    (goto-char end)
    (insert "}}")

    (goto-char start)
    (insert "{{c")
    (insert (number-to-string (1+ (anki-mode--max-cloze))))
    (insert "::")
    ))



(provide 'anki-mode)


;;; anki-mode.el ends here
