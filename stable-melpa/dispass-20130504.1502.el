;;; dispass.el --- Emacs wrapper for DisPass

;; Copyright (C) 2012 Tom Willemsen <tom@ryuslash.org>

;; Author: Tom Willemsen <tom@ryuslash.org>
;; Created: Jun 8, 2012
;; Version: 1.1.2
;; Package-Version: 20130504.1502
;; Package-Commit: 38b880e72cfe5e65179b16791903b0900c73eff4
;; Keywords: processes
;; URL: http://projects.ryuslash.org/dispass.el/

;; Permission to use, copy, modify, and distribute this software for any
;; purpose with or without fee is hereby granted, provided that the
;; above copyright notice and this permission notice appear in all
;; copies.

;; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
;; WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
;; WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
;; AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
;; CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
;; OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
;; NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
;; CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

;;; Commentary:

;; dispass.el is an Emacs wrapper around DisPass
;; (http://dispass.babab.nl).  For more information see the README.org
;; and NEWS files.

;; This version is written for use with DisPass v0.2.0.

;;; Code:

(defgroup dispass nil
  "Customization options for the DisPass wrapper."
  :group 'external)

(defcustom dispass-default-length 30
  "The default length to use when generating passphrases."
  :package-version '(dispass . "1")
  :group 'dispass
  :type '(integer))

(defcustom dispass-executable "dispass"
  "The location of the dispass executable."
  :package-version '(dispass . "0.1a7.3")
  :group 'dispass
  :type '(string)
  :risky t)

(defcustom dispass-labels-executable "dispass-label"
  "The location of the dispass-label executable."
  :package-version '(dispass . "1.1")
  :group 'dispass
  :type 'string
  :risky t)

(defcustom dispass-labelfile nil
  "The location of your preferred labelfile.

A value of nil means to just let DisPass figure it out."
  :package-version '(dispass . "1.1.1")
  :group 'dispass
  :type 'file
  :risky t)

(defvar dispass-labels-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map "c" 'dispass-create)
    (define-key map "a" 'dispass-add-label)
    (define-key map "d" 'dispass-remove-label)
    map)
  "Keymap for `dispass-labels-mode'.

Uses `tabulated-list-mode-map' as its parent.")

;; This should be extracted from DisPass at some point.
(defconst dispass-algorithms
  '("dispass1" "dispass2")
  "The list of algorithms supported by DisPass.")

(defun dispass-process-sentinel (proc status)
  "Report PROC's status change to STATUS."
  (let ((status (substring status 0 -1))
        (buffer (process-buffer proc)))
    (unless (string-equal status "finished")
      (message "dispass %s" status))

    (unless (eq (current-buffer) proc)
      (kill-buffer buffer))))

(defun dispass-erase-buffer (buffer)
  "Completely erase the contents of BUFFER."
  (save-current-buffer
    (set-buffer buffer)
    (buffer-disable-undo buffer)
    (kill-buffer buffer)))

(defun dispass-label-at-point ()
  "When in `dispass-labels-mode', get the label at `point'."
  (let ((labels-mode-p (eq major-mode 'dispass-labels-mode)))
    (tabulated-list-get-id)))

(defun dispass-process-filter-for (label)
  "Create a specialized filter for LABEL.

This filter checks if a password has been asked for or if the
label shows up in a line, which will be the line with the
passphrase that has been generated."
  `(lambda (proc string)
     "Process STRING coming from PROC."
     (cond ((string-match "^\\(Password[^:]*\\|Again\\): ?$" string)
            (process-send-string
             proc
             (concat (read-passwd
                      (concat (replace-regexp-in-string
                               "^[ \t\n]+\\|[ \t\n]+$" "" string) " ")
                      nil) "\n")))

           ((string-match (concat "^[ \t]*" ,label "[ \t]*\\(.+\\)$")
                          string)
            (let ((buffer (process-buffer proc)))
              (with-current-buffer buffer
                (insert (match-string 1 string))
                (clipboard-kill-ring-save (point-min) (point-max))
                (message "Password copied to clipboard.")))))))

(defun dispass-start-process (label create length
                                    &optional algo seqno args)
  "Ask DisPass to generate a passphrase for LABEL.

When CREATE is non-nil send along the -c switch to make it ask
for a password twice.  When LENGTH is an integer and greater than
0, we request that DisPass make the passphrase LENGTH long.  ALGO
should be one of `dispass-algorithms' and requests a certain
algorithm be used by DisPass to generate the passphrase.  SEQNO
asks DisPass to use SEQNO as a sequence number.

If specified add ARGS to the command."
  (let ((args `("-o" ,@args ,label))
        proc)
    (when create
      (setq args (append '("-c") args)))

    (when (and (integerp length) (> length 0))
      (setq args (append `("-l" ,(number-to-string length)) args)))

    (when (and algo (not (equal algo ""))
               (member algo dispass-algorithms))
      (setq args (append `("-a" ,algo) args)))

    (when (and seqno (> seqno 0))
      (setq args (append `("-n" ,(number-to-string seqno)) args)))

    (when dispass-labelfile
      (setq args (append `("-f" ,dispass-labelfile) args)))

    (setq proc (apply 'start-process "dispass" "*dispass*"
                      dispass-executable args))
    (set-process-sentinel proc 'dispass-process-sentinel)
    (set-process-filter proc (dispass-process-filter-for label))))

(defun dispass-get-labels ()
  "Get the list of labels and their information."
  (let ((result '()))
    (with-temp-buffer
      (dispass-read-labels)
      (while (re-search-forward
              "^\\(\\(?:\\sw\\|\\s_\\|\\.\\)+\\)"
              nil t)
        (add-to-list 'result (match-string 1)))
      result)))

(defun dispass-get-labels-for-display ()
  "Prepare the list of labels for info table."
  (let ((result '()))
    (with-temp-buffer
      (dispass-read-labels)
      (while (re-search-forward
              "^\\(\\(?:\\sw\\|\\s_\\|\\.\\)+\\) +\\([0-9]+\\) +\\(\\(?:\\sw\\|\\s_\\)+\\)"
              nil t)
        (let ((label (match-string 1))
              (length (match-string 2))
              (algo (match-string 3)))
          (add-to-list 'result
                       (list label
                          `[(,label
                             face link
                             help-echo ,(concat "Generate passphrase for " label)
                             follow-link t
                             dispass-label ,label
                             dispass-length ,length
                             action dispass-from-button)
                            ,length
                            ,algo])))))
    result))

(defun dispass-read-labels ()
  "Load a list of all labels into a buffer."
  (insert (shell-command-to-string
           (concat dispass-labels-executable
                   (when dispass-labelfile
                     (concat " -f " dispass-labelfile))
                   " -l --script")))
  (goto-char (point-min)))

;;;###autoload
(defun dispass-create (label &optional length algo seqno)
  "Create a new password for LABEL.

Optionally also specify to make the passphrase LENGTH long, use
the ALGO algorithm with sequence number SEQNO."
  (interactive (list
                (read-from-minibuffer "Label: ")
                current-prefix-arg
                (completing-read "Algorithm: " dispass-algorithms)
                (read-from-minibuffer
                 "Sequence no. (1): " nil nil t nil "1")))
  (let ((length (or length dispass-default-length)))
    (dispass-start-process label t length algo seqno)))

;;;###autoload
(defun dispass (label &optional length algo seqno)
  "Recreate a passphrase for LABEL.

Optionally also specify to make the passphrase LENGTH long, use
the ALGO algorithm with sequence number SEQNO.  This is useful
when you would like to generate a one-shot passphrase, or prefer
not to have LABEL added to your labelfile for some other reason."
  (interactive (list
                (completing-read
                 "Label: " (dispass-get-labels))
                current-prefix-arg))
  (when (and (called-interactively-p 'any)
             (not (member label (dispass-get-labels))))
    (setq algo (completing-read "Algorithm: " dispass-algorithms))
    (setq seqno (read-from-minibuffer
                 "Sequence no. (1): " nil nil t nil "1")))
  (let ((length (or length dispass-default-length)))
    (dispass-start-process
     label nil length algo seqno
     (when (member label (dispass-get-labels)) '("-s")))))

;; Labels management
;;;###autoload
(defun dispass-add-label (label length algo &optional seqno)
  "Add LABEL with length LENGTH and algorithm ALGO to DisPass.

Optionally also specify sequence number SEQNO."
  (interactive
   (list (read-from-minibuffer "Label: ")
         (read-from-minibuffer
          (format "Length (%d): " dispass-default-length) nil nil t nil
          (number-to-string dispass-default-length))
         (completing-read
          "Algorithm (dispass1): "
          dispass-algorithms nil nil nil nil "dispass1")
         (read-from-minibuffer "Sequnce no. (1): " nil nil t nil "1")))
  (shell-command
   (format "%s %s --add %s:%d:%s:%s"
           dispass-labels-executable
           (if dispass-labelfile
               (concat "-f " dispass-labelfile)
             "")
           label length algo seqno)))

;;;###autoload
(defun dispass-remove-label (label)
  "Remove LABEL from DisPass.

If LABEL is not given `tabulated-list-get-id' will be used to get
the currently pointed-at label.  If neither LABEL is not found an
error is thrown."
  (interactive
   (list (or (dispass-label-at-point)
             (completing-read
              "Label: " (dispass-get-labels)))))
  (shell-command
   (format "%s %s --remove %s" dispass-labels-executable
           (if dispass-labelfile
               (concat "-f " dispass-labelfile)
             "")
           label)))

(defun dispass-from-button (button)
  "Call dispass with information from BUTTON."
  (dispass (button-get button 'dispass-label)
           (button-get button 'dispass-length)))

(defun dispass-labels--refresh ()
  "Reload labels from dispass."
  (setq tabulated-list-entries nil)

  (let ((tmp-list '()))
    (setq tabulated-list-entries (dispass-get-labels-for-display))))

(define-derived-mode dispass-labels-mode tabulated-list-mode "DisPass"
  "Major mode for listing dispass labels.

\\<dispass-labels-mode-map>
\\{dispass-labels-mode-map}"
  (setq tabulated-list-format [("Label" 30 t)
                               ("Length" 6 nil)
                               ("Algorithm" 0 t)]
        tabulated-list-sort-key '("Label" . nil))
  (add-hook 'tabulated-list-revert-hook 'dispass-labels--refresh)
  (tabulated-list-init-header))

;;;###autoload
(defun dispass-list-labels ()
  "Display a list of labels for dispass."
  (interactive)
  (let ((buffer (get-buffer-create "*DisPass Labels*")))
    (with-current-buffer buffer
      (dispass-labels-mode)
      (dispass-labels--refresh)
      (tabulated-list-print))
    (switch-to-buffer-other-window buffer))
  nil)

(provide 'dispass)

;;; dispass.el ends here

;; Local Variables:
;; sentence-end-double-space: t
;; End:
