;;; dispass.el --- Emacs wrapper for DisPass

;; Copyright (C) 2012 Tom Willemsen <tom@ryuslash.org>

;; Author: Tom Willemsen <tom@ryuslash.org>
;; Created: Jun 8, 2012
;; Version: 1.1.2
;; Package-Version: 20140202.1531
;; Package-Commit: b6e8f89040ebaaf0e7609b04bc27a8979f0ae861
;; Keywords: processes
;; URL: http://projects.ryuslash.org/dispass.el/
;; Package-Requires: ((dash "1.0.0"))

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

(require 'dash)

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

(defcustom dispass-labels-executable nil
  "The location of the dispass-label executable."
  :package-version '(dispass . "1.1.3")
  :group 'dispass
  :type 'string
  :risky t)
(make-obsolete-variable 'dispass-labels-executable
                        "dispass-label is no longer used by DisPass."
                        "dispass 1.1.3")

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

(defun dispass-label-at-point ()
  "When in `dispass-labels-mode', get the label at `point'."
  (let ((labels-mode-p (eq major-mode 'dispass-labels-mode)))
    (tabulated-list-get-id)))

(defun dispass--get-passphrase-matcher (label)
  "Return a function that will get the passphrase for LABEL."
  `(lambda (output)
     (string-match ,(concat "^[ \t]*" label "[ \t]*\\(.+\\)$") output)
     (substring output (match-beginning 1) (match-end 1))))

(defun dispass-start-process (cmd label pass create length
                                  &optional algo seqno args)
  "Ask DisPass call CMD for LABEL and PASS.

When CREATE is non-nil send along the -c switch to make it ask
for a password twice.  When LENGTH is an integer and greater than
0, we request that DisPass make the passphrase LENGTH long.  ALGO
should be one of `dispass-algorithms' and requests a certain
algorithm be used by DisPass to generate the passphrase.  SEQNO
asks DisPass to use SEQNO as a sequence number.

If specified add ARGS to the command."
  (let ((args `(,cmd ,@args "-o" "-p" ,pass))
        proc)
    (when create
      (setq args (append args '("-v"))))

    (when (and (integerp length) (> length 0))
      (setq args (append args `("-l" ,(number-to-string length)))))

    (when (and algo (not (equal algo ""))
               (member algo dispass-algorithms))
      (setq args (append args `("-a" ,algo))))

    (when (and seqno (> seqno 0))
      (setq args (append args `("-s" ,(number-to-string seqno)))))

    (when dispass-labelfile
      (setq args (append `("-f" ,dispass-labelfile) args)))

    (shell-command-to-string
     (apply #'concat
            (-interpose " " `(,dispass-executable ,@args ,label))))))

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
           (concat dispass-executable
                   (when dispass-labelfile
                     (concat " -f " dispass-labelfile))
                   " list --script")))
  (goto-char (point-min)))

(defun dispass--verified-password ()
  "Ask for and verify a password."
  (let ((passwd (read-passwd "Password: ")))
    (if (and (equal passwd (read-passwd "Password (again): ")))
        passwd
      (error "Passwords don't match"))))

(defun dispass--generate (label pass create length algo seqno)
  "Call `dispass-start-process' to generate a passphrase.

The LABEL, PASS, CREATE, LENGTH, ALGO and SEQNO arguments have
the same meanings as when passed to `dispass-start-process'.

The result is put in the `kill-ring'."
  (funcall (dispass--get-passphrase-matcher label)
           (dispass-start-process "generate" label pass create length
                                  algo seqno)))

(defun dispass--copy (str)
  "Put STR in the `kill-ring'."
  (kill-new str)
  (message "Passphrase copied to kill ring"))

;;;###autoload
(defun dispass-create (label pass &optional length algo seqno)
  "Create a new password for LABEL using PASS.

Optionally also specify to make the passphrase LENGTH long, use
the ALGO algorithm with sequence number SEQNO."
  (interactive (list
                (read-from-minibuffer "Label: ")
                (dispass--verified-password)
                current-prefix-arg
                (completing-read "Algorithm: " dispass-algorithms)
                (read-from-minibuffer
                 "Sequence no. (1): " nil nil t nil "1")))
  (let ((length (or length dispass-default-length)))
    (dispass--copy (dispass--generate label pass t length algo seqno))))

(defun dispass--interactive-spec ()
  "Return an interactive specification.

This specification is for use with any functions based on the
`dispass--get-phrase' function."
  (list (completing-read "Label: " (dispass-get-labels))
        (read-passwd "Password: ")
        current-prefix-arg))

(defun dispass--get-phrase
    (label pass interactivep &optional length algo seqno)
  "Get a passphrase either by using the label file or asking for info.

LABEL is a string indicating a label (possibly in the label
file).  PASS is the password to use to generate the passphrase.
INTERACTIVEP is an indication of whether its invoker was called
interactively or not.  LENGTH is the requested length of the
generated passphrase.  ALGO is the algrithm to use to generate
the passphrase.  SEQNO is the sequence number to use when
generating the passphrase.

LENGTH, ALGO and SEQNO are not important if LABEL was found in
the labels file."
  (when (and interactivep
             (not (member label (dispass-get-labels))))
    (setq algo (completing-read "Algorithm: " dispass-algorithms))
    (setq seqno (read-from-minibuffer
                 "Sequence no. (1): " nil nil t nil "1")))
  (let ((length (or length dispass-default-length)))
    (dispass--generate label pass nil length algo seqno)))

;;;###autoload
(defun dispass (label pass &optional length algo seqno)
  "Recreate a passphrase for LABEL using PASS.

Optionally also specify to make the passphrase LENGTH long, use
the ALGO algorithm with sequence number SEQNO.  This is useful
when you would like to generate a one-shot passphrase, or prefer
not to have LABEL added to your labelfile for some other reason."
  (interactive (dispass--interactive-spec))
  (dispass--copy
   (dispass--get-phrase
    label pass (called-interactively-p 'any) length algo seqno)))

;;;###autoload
(defun dispass-insert (label pass &optional length algo seqno)
  "Recreate a passphrase for LABEL using PASS.

This command does the exact same thing as `dispass', except it
inserts the results in the current buffer instead of copying them
into the `kill-ring' (and clipboard).  LABEL, PASS, LENGTH, ALGO
and SEQNO are directly passed on to `dispass--get-phrase'."
  (interactive (dispass--interactive-spec))
  (insert
   (dispass--get-phrase
    label pass (called-interactively-p 'any) length algo seqno)))

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
   (format "%s %s add %s:%d:%s:%s"
           dispass-executable
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
   (format "%s %s rm %s" dispass-executable
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
