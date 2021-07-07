;;; vimgolf.el --- VimGolf interface for the One True Editor
;; Copyright (C) never, by no one

;; Author: Tim Visher <tim.visher@gmail.com>
;; Maintainer: Tim Visher <tim.visher@gmail.com>
;; Created: 2011-11-02
;; Version: 0.10.4-SNAPSHOT
;; Package-Version: 20200205.1420
;; Package-Commit: f565447ed294898588a19438d56c116555d8c628
;; Keywords: games vimgolf vim
;; URL: https://github.com/timvisher/vimgolf.el

;; This file is not part of GNU Emacs

;; VimGolf In Emacs is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.
;;
;; VimGolf In Emacs is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with VimGolf In Emacs. If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; This is a simple package that allows Emacs users to compete on
;; [VimGolf][1] using the One True Editor. Competition can be commenced
;; utilizing `M-x vimgolf`. When finished with a challenge, `C-c C-v C-c`
;; should finish your editing, ensure correctness, and submit your score
;; and keystrokes to [VimGolf][1].
;;
;; On second thought, let's not go to Camelot. It's a silly place.
;;
;; Patches and Issues are accepted at
;; https://github.com/timvisher/vimgolf.el
;;
;; [1]: https://vimgolf.com/

;;; Installation:

;; Use MELPA Stable, preferably.

;; I make no guarantees that vimgolf.el works with anything but the latest
;; version of Emacs.

;;; Contributors

;; Tim Visher (@timvisher)
;; Steve Purcell (@sanityinc)
;; Adam Collard (@acollard)
;; Siddhanathan Shanmugam (@siddhanathan)

;;; Code:

(require 'json)
(require 'url-http)
(defvar url-http-end-of-headers)

(defgroup vimgolf nil
  "Compete on VimGolf with the One True Editor."
  :prefix "vimgolf-"
  :group 'applications)

(defcustom vimgolf-key nil
  "Your VimGolf API Key. Must be set in order to submit your solution."
  :type 'string
  :group 'vimgolf)

(defcustom vimgolf-mode-hook '((lambda () (whitespace-mode t)))
  "A list of functions to call upon the initialization of vimgolf."
  :type 'hook
  :group 'vimgolf)

(defvar vimgolf-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-v C") 'vimgolf-submit)
    (define-key map (kbd "C-c C-v r") 'vimgolf-revert)
    (define-key map (kbd "C-c C-v C-r") 'vimgolf-revert)
    (define-key map (kbd "C-c C-v d") 'vimgolf-diff)
    (define-key map (kbd "C-c C-v C-d") 'vimgolf-diff)
    (define-key map (kbd "C-c C-v c") 'vimgolf-continue)
    (define-key map (kbd "C-c C-v C-c") 'vimgolf-continue)
    (define-key map (kbd "C-c C-v p") 'vimgolf-pause)
    (define-key map (kbd "C-c C-v C-p") 'vimgolf-pause)
    (define-key map (kbd "C-c C-v q") 'vimgolf-quit)
    (define-key map (kbd "C-c C-v C-q") 'vimgolf-quit)
    map))

(define-minor-mode vimgolf-mode
  "Toggle VimGolf mode.

With no argument, this command toggles the mode. Non-null prefix
argument turns on the mode. Null prefix argument turns off the
mode.

When VimGolf mode is enabled, several key bindings are defined
with `C-c C-v` prefixes to help in playing VimGolf.

\\{vimgolf-mode-map}"
  ;; The initial value.
  nil
  ;; The indicator for the mode line.
  " VimGolf"
  ;; The minor mode bindings.
  :keymap vimgolf-mode-map
  :group 'vimgolf)

(defvar vimgolf-challenge nil)
(defvar vimgolf-challenge-history nil)

(defvar vimgolf-prior-window-configuration nil)

(defvar vimgolf-working-window-configuration nil)

(defvar vimgolf-work-buffer-name "*vimgolf-work*")
(defvar vimgolf-start-buffer-name "*vimgolf-start*")
(defvar vimgolf-end-buffer-name "*vimgolf-end*")
(defvar vimgolf-keystrokes-buffer-name "*vimgolf-keystrokes*")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Keystroke logging
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro vimgolf-with-saved-command-environment
    (&rest body)
  "Execute BODY without poluting Emacs command memory."
  `(let ((deactivate-mark nil)
         (this-command this-command)
         (last-command last-command))
     ,@body))

(defun vimgolf-capturable-keystroke-p
    ()
  "Predicate for keys that shouldn't be counted."
  (not (or executing-kbd-macro
           (member this-command
                   '(digit-argument
                     negative-argument
                     universal-argument
                     universal-argument-other-key
                     universal-argument-minus
                     universal-argument-more
                     isearch-other-meta-char))
           (string-prefix-p "vimgolf-" (symbol-name this-command)))))

(defun vimgolf-capturable-dangling-keystroke-p
    ()
  "Some keystrokes are only visible after they resolve."
  (member this-command
          '(calc-dispatch)))

(defvar vimgolf-keystrokes nil
  "A list of (keys-vector . command) pairs for the keystrokes entered.

Each entry is a cons cell containing a key sequence vector
suitable for use with `key-description', and a symbol for the
command that was executed as a result (which may be nil if an
unknown key sequence was entered).")

(defun vimgolf-maybe-capture-keystroke
    (pred)
  "Store the keystrokes for `this-command' if PRED is truthy."
  (vimgolf-with-saved-command-environment
   (when (funcall pred)
     (setq vimgolf-keystrokes
           (append vimgolf-keystrokes (list (cons (this-command-keys-vector)
                                                  this-command)))))))

(defun vimgolf-capture-keystroke
    ()
  "Convenience function for capturing normal keystrokes."
  (vimgolf-maybe-capture-keystroke 'vimgolf-capturable-keystroke-p))

(defun vimgolf-capture-dangling-keystroke
    ()
  "Convenience function for capturing dangling keystrokes."
  (vimgolf-maybe-capture-keystroke 'vimgolf-capturable-dangling-keystroke-p))

(defun vimgolf-get-keystrokes-as-string
    (&optional separator)
  "Convert current keystrokes to a human readable string.

SEPARATOR defaults to ` '"
  (unless separator (setq separator " "))
  (mapconcat 'key-description (mapcar 'car vimgolf-keystrokes) separator))

(defun vimgolf-refresh-keystroke-log
    ()
  "Refresh the contents of the keystrokes log buffer."
  (let ((deactivate-mark nil))
    (with-current-buffer (get-buffer-create vimgolf-keystrokes-buffer-name)
      (vimgolf-mode t)
      (erase-buffer)
      (insert (format "Challenge ID: %s\n%s\n\n" vimgolf-challenge (vimgolf-challenge-url vimgolf-challenge))
              (format "Keystrokes (%d):\n\n" (vimgolf-count-keystrokes))
              (vimgolf-get-keystrokes-as-string)
              "\n\nFull command log:\n\n")
      (when vimgolf-keystrokes
        (let* ((descrs-and-commands
                (mapcar (lambda (entry) (cons (key-description (car entry)) (cdr entry))) vimgolf-keystrokes))
               (maxlen (apply 'max (mapcar 'length (mapcar 'car descrs-and-commands))))
               (fmt (format "%%-%ds  %%s" maxlen)))
          (dolist (entry descrs-and-commands)
            (insert (format fmt (car entry) (prin1-to-string (cdr entry) t)) "\n")))))))

(defun vimgolf-enable-capture
    (enable)
  "Enable keystroke logging if `ENABLE' is non-nil otherwise disable it."
  (let ((f (if enable 'add-hook 'remove-hook)))
    (funcall f 'pre-command-hook 'vimgolf-capture-keystroke)
    (funcall f 'post-command-hook 'vimgolf-capture-dangling-keystroke)
    (funcall f 'post-command-hook 'vimgolf-refresh-keystroke-log)))

(defun vimgolf-count-keystrokes
    ()
  "Count keystrokes used for challenge."
  (apply '+ (mapcar 'length (mapcar 'car vimgolf-keystrokes))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Managing and scoring challenges
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun vimgolf-solution-correct-p
    ()
  "Return t if the work text is identical to the solution, nil otherwise."
  (let ((working (with-current-buffer vimgolf-work-buffer-name (buffer-string)))
        (end (with-current-buffer vimgolf-end-buffer-name (buffer-string))))
    (string= working end)))

(defun vimgolf-wrong-solution
    ()
  "Inform the player they got it wrong."
  (message "Wrong!")
  (vimgolf-diff))

(defun vimgolf-right-solution
    ()
  "Inform they player they got it right."
  (delete-other-windows)
  (switch-to-buffer vimgolf-keystrokes-buffer-name)
  (message "Hurray! You solved %s in %d keystrokes!" vimgolf-challenge (vimgolf-count-keystrokes)))

(defun vimgolf-submit
    ()
  "Stop the challenge and attempt to submit the solution to VimGolf."
  (interactive)
  (vimgolf-enable-capture nil)
  (if (vimgolf-solution-correct-p) (vimgolf-right-solution) (vimgolf-wrong-solution)))

(defun vimgolf-clear-keystrokes
    ()
  "Clear out what vimgolf thinks the player's typed."
  (setq vimgolf-keystrokes nil))

(defun vimgolf-reset-work-buffer
    ()
  "Reset the contents of the work buffer, and clear undo/macro history etc."
  (with-current-buffer (get-buffer-create vimgolf-work-buffer-name)
    (vimgolf-init-buffer (current-buffer)
                         (with-current-buffer vimgolf-start-buffer-name
                           (buffer-string)))
    (when defining-kbd-macro
      (end-kbd-macro))
    (vimgolf-clear-keystrokes)
    (setq buffer-undo-list nil)
    (set-buffer-modified-p nil)))

(defun vimgolf-revert
    ()
  "Revert the work buffer to it's original state and reset keystrokes."
  (interactive)
  (vimgolf-reset-work-buffer)
  (set-window-configuration vimgolf-working-window-configuration)
  (message "If at first you don't succeed, try, try again."))

(defun vimgolf-diff
    ()
  "Pause the competition and view differences between the buffers."
  (interactive)
  (vimgolf-enable-capture nil)
  (ediff-buffers (get-buffer-create vimgolf-work-buffer-name) (get-buffer-create vimgolf-end-buffer-name))
  (message "Remember to `C-c C-v c` when you're done."))

(defun vimgolf-continue
    ()
  "Restore work and end buffers and begin recording keystrokes again."
  (interactive)
  (vimgolf-enable-capture t)
  (set-window-configuration vimgolf-working-window-configuration)
  (message "Golf away!"))

(defun vimgolf-pause
    ()
  "Stop recording keystrokes."
  (interactive)
  (vimgolf-enable-capture nil)
  (message "Come `C-c C-v c` soon."))

(defun vimgolf-quit
    ()
  "Cancel the competition."
  (interactive)
  (vimgolf-enable-capture nil)
  (vimgolf-kill-existing-session)
  (set-window-configuration vimgolf-prior-window-configuration)
  (message "I declare you, n00b!"))

(defvar vimgolf-host "https://www.vimgolf.com/")

;; (setq vimgolf-host "https://vimgolf.local:8888/")
;; (setq vimgolf-host "https://vimgolf.com/")
;; Overall VimGolf Rank ID: 4d2fb20e63b08b08b0000075
;; Sort entries based on date ID: 4ea9bc988b36f70001000008
;; HTML to Haml ID: 4d3c51f1aabf526ed6000030
;; Assignment Allignment: 4d2c9d06eda6262e4e00007a

(defvar vimgolf-challenge-extension ".json")

(defun vimgolf-challenge-path
    (challenge-id)
  "Generate the challenge url path component for CHALLENGE-ID."
  (concat "challenges/" challenge-id))

(defun vimgolf-challenge-url
    (challenge-id)
  "Generate the full VimGolf url for CHALLENGE-ID."
  (concat vimgolf-host (vimgolf-challenge-path challenge-id) vimgolf-challenge-extension))

(defun vimgolf-init-buffer
    (buffer text)
  "Make BUFFER managed by vimgolf ready to mess with TEXT."
  (with-current-buffer buffer
    (erase-buffer)
    (insert text)
    (goto-char (point-min))
    (vimgolf-mode t)))

(defun vimgolf-kill-existing-session
    ()
  "Kill any vimgolf-related buffers."
  (dolist (buf (list vimgolf-start-buffer-name
                     vimgolf-work-buffer-name
                     vimgolf-end-buffer-name
                     vimgolf-keystrokes-buffer-name))
    (when (get-buffer buf)
      (kill-buffer buf))))

(defun vimgolf-get-text
    (var response)
  "Get text associated with VAR from a VimGolf RESPONSE."
  (format "%s" (assoc-default 'data (assq var response))))

(defun vimgolf-retrieve-challenge
    (challenge-id)
  "Get CHALLENGE-ID's in and out text."
  (interactive)
  (with-current-buffer
      (url-retrieve-synchronously (vimgolf-challenge-url challenge-id))
    ;; `url-http-end-of-headers' is set by `url-retrieve-synchronously' as
    ;; a local variable in the retrieval buffer to the position at the end
    ;; of the headers.
    (goto-char url-http-end-of-headers)
    (json-read)))

(defvar vimgolf-response nil
  "Holds the most recent HTTP response from VimGolf.")

(defun vimgolf-setup
    (_ challenge-id)
  "Setup Emacs to play VimGolf challenge CHALLENGE-ID.

This function is a callback for `url-retrieve' but it doesn't
attempt to deal with HTTP statuses gracefully so it throws that
part of the arg list away."
  (let ((url-mime-encoding-string "identity"))
    (setq vimgolf-response (vimgolf-retrieve-challenge challenge-id)))

  (vimgolf-clear-keystrokes)
  (setq vimgolf-prior-window-configuration (current-window-configuration)
        vimgolf-challenge challenge-id)
  (goto-char (point-min))

  (let* ((start-text (vimgolf-get-text 'in vimgolf-response))
         (end-text   (vimgolf-get-text 'out vimgolf-response)))
    (vimgolf-kill-existing-session)

    (let ((vimgolf-start-buffer (get-buffer-create vimgolf-start-buffer-name))
          (vimgolf-work-buffer (get-buffer-create vimgolf-work-buffer-name))
          (vimgolf-end-buffer (get-buffer-create vimgolf-end-buffer-name)))

      (vimgolf-init-buffer vimgolf-start-buffer start-text)
      (vimgolf-init-buffer vimgolf-end-buffer end-text)
      (with-current-buffer vimgolf-end-buffer (setq buffer-read-only t))
      (vimgolf-reset-work-buffer)

      ;; Set up windows
      (delete-other-windows)
      (display-buffer vimgolf-end-buffer 'display-buffer-pop-up-window)
      (set-window-buffer (selected-window) vimgolf-work-buffer)
      (switch-to-buffer vimgolf-work-buffer)
      (setq vimgolf-working-window-configuration (current-window-configuration))

      (vimgolf-continue))))

(defvar vimgolf--browse-list nil
  "Holds a list of parsed VimGolf challenges.")

(defun vimgolf-browse
    (&optional force-pull)
  "Browse VimGolf challenges in a dedicated buffer.

Optional FORCE-PULL will retrieve challenges again even if
`vimgolf--browse-list' was already generated.

TODO Is there no API for browsing all the challenges?"
  (interactive)
  (if (or (eq vimgolf--browse-list nil)
          force-pull)
      (url-retrieve vimgolf-host 'vimgolf-parse-browse-html)
    (vimgolf-browse-list)
    (vimgolf-browse-next)))

(defun vimgolf-browse-refresh
    ()
  "Refresh the VimGolf browser list."
  (interactive)
  (vimgolf-browse t))

(defun vimgolf-replace-control-m
    (string &optional replace)
  "Replace carriage return (ASCII Code 13) character in STRING.

Optional REPLACE defaults to ` '"
  (replace-regexp-in-string (char-to-string 13) (or replace " ") string))

(defun vimgolf-parse-html-entites
    (string)
  "Parse HTML entities from HTML partial STRING."
  (replace-regexp-in-string
   "&lt;" "<"
   (replace-regexp-in-string
    "&gt;" ">"
    (replace-regexp-in-string
     "&amp;" "&"
     (replace-regexp-in-string
      "&quot" "\""
      string)))))

(defun vimgolf-parse-browse-html
    (_)
  "Callback function parsing VimGolf homepage HTML.

No attempt is made to gracefully handle HTTP errors so the status
argument is dropped on the floor."
  ;; TODO is (with-current-buffer (current-buffer) …) necessary here?
  (with-current-buffer (current-buffer)
    (let ((html (vimgolf-parse-html-entites
                 (replace-regexp-in-string "\n" "" (buffer-string)))))
      (setq vimgolf--browse-list nil)
      (while
          (string-match
           "<a href=\"/challenges/\\([a-zA-Z0-9]+\\)\">\\(.*?\\)</a>.*?<p>\\(.*?\\)</p>"
           html)
        (add-to-list 'vimgolf--browse-list
                     (cons (match-string 1 html)
                           (list (match-string 2 html)
                                 (vimgolf-replace-control-m
                                  (match-string 3 html))))
                     t)
        (setq html (substring html (match-end 0))))
      vimgolf--browse-list))
  (vimgolf-browse-list)
  (vimgolf-browse-next))

(defun vimgolf-browse-list
    ()
  "Setup a dedicated VimGolf Browser buffer."
  ;; TODO I wonder how much of this could be replaced by EWW usage?
  (let ((browse-buffer (get-buffer-create "*VimGolf Browse*")))
    (switch-to-buffer browse-buffer)
    (setq buffer-read-only nil)
    (kill-region (point-min) (point-max))
    (insert "VimGolf Challenges")
    (newline 2)
    (dolist (challenge vimgolf--browse-list)
      (let ((title (substring (cadr challenge)
                              0
                              (min (length (cadr challenge))
                                   (- fill-column 3))))
            (description (car (cdr (cdr challenge))))
            (challenge-id (car challenge)))
        (when (< (length title) (length (cadr challenge)))
          (setq title (concat title "...")))
        (insert-text-button title
                            'action 'vimgolf-browse-select
                            'follow-link t
                            'challenge-id challenge-id
                            'help-echo description))
      (newline)))
  (goto-char (point-min))
  (vimgolf-browse-mode))

(defun vimgolf-browse-select
    (_)
  "Start a vimgolf session for challenge at point.

This function is used as a callback for `insert-text-button' but
the arg is ignored."
  (let ((challenge-id (get-text-property (point) 'challenge-id)))
    (vimgolf challenge-id)))

(defun vimgolf-message-title
    ()
  "Get title for the challenge at point."
  (let ((challenge-id (get-text-property (point) 'challenge-id)))
    (when challenge-id
      (message (cadr (assoc challenge-id vimgolf--browse-list))))))

(defun vimgolf-browse-next
    ()
  "Move point to the next challenge."
  (interactive)
  (goto-char (next-single-property-change (point) 'challenge-id))
  (unless (get-text-property (point) 'challenge-id)
    (goto-char (next-single-property-change (point) 'challenge-id)))
  (vimgolf-message-title))

(defun vimgolf-browse-previous
    ()
  "Move point to the previous challenge."
  (interactive)
  (goto-char (previous-single-property-change (point) 'challenge-id))
  (unless (get-text-property (point) 'challenge-id)
    (goto-char (previous-single-property-change (point) 'challenge-id)))
  (vimgolf-message-title))

(defun vimgolf-show-description
    ()
  "Show the description for challenge at point."
  (interactive)
  (let ((challenge-id (get-text-property (point) 'challenge-id)))
    (save-excursion
      (setq buffer-read-only nil)
      (if (text-property-any (point-min) (point-max) 'challenge-description challenge-id)
          (progn
            (goto-char (point-min))
            (while (not (eq (get-text-property (point) 'challenge-description) challenge-id))
              (goto-char (next-single-property-change (point) 'challenge-description)))
            (let ((start (point)))
              (goto-char (next-single-property-change (point) 'challenge-description))
              (delete-region start (point))
              (delete-blank-lines)
              (delete-blank-lines)))
        (end-of-line)
        (newline 3)
        (forward-line -1)
        (let ((start (point)))
          (insert "  " (car (cddr (assoc challenge-id vimgolf--browse-list))))
          (fill-region start (point))
          (add-text-properties start (point) `(challenge-description ,challenge-id))))
      (setq buffer-read-only t))))

;;;###autoload
(defun vimgolf
    (challenge-id)
  "Open a VimGolf session for CHALLENGE-ID."
  (interactive (list (read-from-minibuffer "Challenge ID: " nil nil nil 'vimgolf-challenge-history)))
  (url-retrieve (vimgolf-challenge-url challenge-id) 'vimgolf-setup `(,challenge-id)))

(defvar vimgolf-browse-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "TAB") 'vimgolf-show-description)
    (define-key keymap "g" 'vimgolf-browse-refresh)
    (define-key keymap "n" 'vimgolf-browse-next)
    (define-key keymap "p" 'vimgolf-browse-previous)
    keymap)
  "Keymap for browsing VimGolf.")

(define-derived-mode vimgolf-browse-mode special-mode "VimGolf browse"
  "A major mode for completing VimGolf challenges."
  vimgolf-browse-mode-map)

(put 'vimgolf-mode 'mode-class 'special)

(provide 'vimgolf)

;;; Local Variables:
;;; tab-width:2
;;; indent-tabs-mode:nil
;;; End:
;;; vimgolf.el ends here
