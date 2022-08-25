;;; cowsay.el --- Poorly drawn ASCII cartoons saying things -*- lexical-binding: t -*-

;; Copyright 2016 Matt Smith (go-cowsay)
;; Copyright 2021 Lassi Kortela
;; SPDX-License-Identifier: MIT

;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-cowsay
;; Package-Version: 20210510.1540
;; Package-Commit: d8a72a311c6875f1aef6a30b3d23a1b02df75941
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.5"))
;; Keywords: games

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This is a workalike of the popular `cowsay' amusement program that
;; runs directly in Emacs and does not require any external programs.
;; This port is not written by the original author of `cowsay', but
;; can load cartoon characters from the same files as the original.

;;; Code:

;;;###autoload
(defgroup cowsay nil
  "Poorly drawn ASCII cartoons saying things."
  :group 'games)

(defcustom cowsay-directories
  '("/usr/local/share/cows" "/usr/share/cowsay/cows")
  "List of directories to search for .cow files.

Any directories listed in the COWPATH environment variable are
searched as well."
  :group 'cowsay
  :type '(list string))

(defvar cowsay-cows '()
  "List of cows that are available for use.

Each entry is a list whose first element is the cow name (a
string) and remaining elements are cow parts.  A cow part is
either a string (which is inserted verbatim) or one of the
symbols 'eyes, 'thoughts, 'tongue.")

(defcustom cowsay-preferred-cows '("default")
  "List of your favorite cows.

When you don't ask for a particular cow, the first loaded cow
from this list is chosen by default.  If none of the preferred
cows are loaded, the first cow available is chosen.

The value is a list of cow names as strings.  Emacs Lisp code
calling cowsay can temporarily override this variable
using (let ((cowsay-preferred-cows ...)) ...) to use particular
cows preferred by the program."
  :group 'cowsay
  :type '(list string))

(defvar cowsay-cow-history '()
  "History of which cows have been used to say things.")

(defcustom cowsay-bubble-style 'say
  "Either 'say or 'think."
  :group 'cowsay
  :type '(radio (say :tag "Speech bubble")
                (think :tag "Thought bubble")))

(defvar cowsay-eyes ""
  "A 2-character string to use as the cow's eyes.")

(defvar cowsay-tongue ""
  "A 2-character string to use as the cow's tongue.")

(defun cowsay--get-accessory (string default)
  "Internal helper to get eyes/tongue from STRING or DEFAULT."
  (if (not (stringp string)) default
    (let ((n (length string)))
      (cond ((= n 0) default)
            ((= n 1) (concat string " "))
            ((= n 2) string)
            (t (substring string 0 2))))))

(defun cowsay--get-bubble ()
  "Internal helper to get the speech or thought bubble."
  (let ((style cowsay-bubble-style))
    (cond ((eq style 'say) "<>/\\\\/||\\")
          ((eq style 'think) "()()()()o")
          (t (error "Unknown cowsay-bubble-style: %S" style)))))

(defun cowsay--get-system-cowpath ()
  "Internal helper to parse COWPATH from the environment."
  (let ((whole (or (getenv "COWPATH") "")))
    (split-string whole (regexp-quote path-separator) t)))

(defun cowsay--parse-cow-file (file)
  "Internal helper to parse a cow from text FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-max))
    (unless (bolp) (insert "\n"))
    (goto-char (point-min))
    (while (re-search-forward "^#.*?\n" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward "^.*EOC.*\n" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (search-forward "\\@" nil t) (replace-match "@"))
    (goto-char (point-min))
    ;; Replace two backslashes with one:
    (while (search-forward "\\\\" nil t) (replace-match "\\\\"))
    (goto-char (point-min))
    (let ((re "\\${?\\([a-z]+\\)}?")  ; Match a variable $eyes or ${eyes}.
          (start (point))
          (parts '()))
      (while (re-search-forward re nil t)
        (let ((tag (match-string 1)))
          (when (member tag '("eyes" "thoughts" "tongue"))
            (let ((end (match-beginning 0)))
              (when (< start end)
                (push (buffer-substring start end) parts))
              (push (intern tag) parts)
              (setq start (match-end 0))))))
      (let ((end (point-max)))
        (when (< start end)
          (push (buffer-substring start end) parts)))
      (reverse parts))))

;;;###autoload
(defun cowsay-load-cow-file (file)
  "Load cow definition from text FILE."
  (interactive "fLoad .cow file: ")
  (let ((cow (file-name-sans-extension (file-name-nondirectory file))))
    (let ((cow-pair (or (assoc cow cowsay-cows)
                        (car (setq cowsay-cows (cons (cons cow "")
                                                     cowsay-cows))))))
      (setcdr cow-pair (cowsay--parse-cow-file file)))
    cow))

;;;###autoload
(defun cowsay-load-cows-directory (directory)
  "Load cow definitions from all matching files in DIRECTORY.

Subdirectories are not visited."
  (interactive "DLoad .cow files from directory: ")
  (let ((cows (mapcar #'cowsay-load-cow-file
                      (let ((case-fold-search t))
                        (directory-files directory t "^[a-z0-9-]+\\.cow$")))))
    (when (called-interactively-p 'interactive)
      (message "Loaded %d cows" (length cows)))
    cows))

;;;###autoload
(defun cowsay-load-cows ()
  "Load cow definitions from the usual files.

Find all the cow files in `cowsay-directories' and add each cow
to to `cowsay-cows'. Existing cows with the same name are
overwritten from the files. Existing cows without matching files
are left intact."
  (interactive)
  (let ((cowpath (append cowsay-directories (cowsay--get-system-cowpath))))
    (dolist (dir (reverse cowpath))
      (when (file-directory-p dir)
        (cowsay-load-cows-directory dir)))))

(defun cowsay-list-cows ()
  "Return a list of all loaded cow names as strings."
  (sort (mapcar #'car cowsay-cows) #'string<))

(defun cowsay--get-cow-parts (cow)
  "Internal helper to get the strings and symbols constituting COW.

Returns nil if COW is not loaded."
  (cdr (assoc cow cowsay-cows)))

(defun cowsay--get-default-cow ()
  "Internal helper to get the name of the default cow."
  (let ((default nil))
    (dolist (cow cowsay-preferred-cows)
      (setq default (or default (and (cowsay--get-cow-parts cow) cow))))
    (let ((cow (and cowsay-cows (caar cowsay-cows))))
      (setq default (or default (and (cowsay--get-cow-parts cow) cow))))
    (or default (error "No cows have been loaded"))))

(defun cowsay--insert-cow (cow thoughts)
  "Internal helper to insert COW with THOUGHTS at point."
  (let ((cow (or cow (cowsay--get-default-cow))))
    (dolist (part (or (cowsay--get-cow-parts cow)
                      (error "No such cow: %S" cow)))
      (insert (cond ((stringp part) part)
                    ((eq part 'eyes)
                     (cowsay--get-accessory cowsay-eyes "oo"))
                    ((eq part 'tongue)
                     (cowsay--get-accessory cowsay-tongue "  "))
                    ((eq part 'thoughts) thoughts)
                    (t (error "Cow %S is ill-defined" cow)))))))

(defun cowsay--bubble-wrap-buffer (bubble)
  "Internal helper to insert BUBBLE around visible region of buffer."
  (unless (and (stringp bubble) (= 9 (length bubble)))
    (error "Bubble should be a 9-character string: %S" bubble))
  (let ((l-only   (substring bubble 0 1))
        (r-only   (substring bubble 1 2))
        (l-top    (substring bubble 2 3))
        (r-top    (substring bubble 3 4))
        (l-bot    (substring bubble 4 5))
        (r-bot    (substring bubble 5 6))
        (l-side   (substring bubble 6 7))
        (r-side   (substring bubble 7 8))
        (longest  0))
    (goto-char (point-max))
    (unless (eql ?\n (char-before)) (insert "\n"))
    (let ((fill-column 70))
      (fill-region (point-min) (point-max)))
    (goto-char (point-min))
    (while (not (eobp))
      (setq longest (max longest (- (point-at-eol) (point-at-bol))))
      (goto-char (min (point-max) (1+ (point-at-eol)))))
    (goto-char (point-min))
    (while (< (point-at-eol) (point-max))
      (let* ((len     (- (point-at-eol) (point-at-bol)))
             (top-p   (= (point-at-bol) (point-min)))
             (bot-p   (= (point-at-eol) (1- (point-max))))
             (only-p  (and top-p bot-p))
             (padding (make-string (- longest len) ?\s)))
        (looking-at "^.*$")
        (let ((text (concat " " (match-string 0) padding " ")))
          (replace-match
           (cond (only-p (concat l-only text r-only))
                 (top-p  (concat l-top  text r-top))
                 (bot-p  (concat l-bot  text r-bot))
                 (t      (concat l-side text r-side)))
           t t))
        (goto-char (1+ (point-at-eol)))))
    (goto-char (point-min))
    (insert " " (make-string (+ 1 longest 1) ?\_) " \n")
    (goto-char (point-max))
    (insert " " (make-string (+ 1 longest 1) ?\-) " \n")))

(defun cowsay--string-to-string (string cow)
  "Internal helper to return a string with COW saying STRING."
  (with-temp-buffer
    (let* ((bubble (cowsay--get-bubble))
           (thoughts (substring bubble 8 9)))
      (insert string)
      (cowsay--bubble-wrap-buffer bubble)
      (cowsay--insert-cow cow thoughts)
      (buffer-string))))

(defun cowsay--display-string (display-p string)
  "Internal helper to display STRING when DISPLAY-P is non-nil."
  (when display-p (display-message-or-buffer string "*Cow Say*"))
  string)

(defun cowsay--prompt-for-cow (prompt-p)
  "Internal helper to select a cow in the minibuffer when PROMPT-P."
  (and prompt-p
       (let ((default (cowsay--get-default-cow)))
         (completing-read "Cow: " cowsay-cows nil t default
                          'cowsay-cow-history default))))

(defun cowsay--get-region-and-cow (prompt-p)
  "Internal helper to interactively get (START END COW) arguments.

When PROMPT-P is non-nil, prompt for the cow."
  (if (not (use-region-p))
      (error "The region is not active now")
    (list (region-beginning)
          (region-end)
          (cowsay--prompt-for-cow prompt-p))))

;;;###autoload
(defun cowsay-replace-region (start end &optional cow)
  "Replace the text between START and END with COW saying it.

When called interactively and a prefix argument is given, ask
which cow to use in the minibuffer."
  (interactive (cowsay--get-region-and-cow current-prefix-arg))
  (let* ((string (buffer-substring start end))
         (cartoon (cowsay--string-to-string string cow)))
    (delete-region start end)
    (insert cartoon)))

;;;###autoload
(defun cowsay-region (start end &optional cow)
  "Show ASCII art with COW saying the text between START and END.

When called interactively and a prefix argument is given, ask
which cow to use in the minibuffer."
  (interactive (cowsay--get-region-and-cow current-prefix-arg))
  (cowsay--display-string
   (called-interactively-p 'interactive)
   (cowsay--string-to-string (buffer-substring start end) cow)))

;;;###autoload
(defun cowsay-string (string &optional cow)
  "Show ASCII art with poorly drawn COW saying STRING.

When called interactively, ask for a string in the minibuffer.
When a prefix argument is given, first ask which cow to use."
  (interactive
   (let ((cow (cowsay--prompt-for-cow current-prefix-arg)))
     (list (read-from-minibuffer "Cow say: ") cow)))
  (cowsay--display-string
   (called-interactively-p 'interactive)
   (cowsay--string-to-string string cow)))

;;;###autoload
(defun cowsay-shell-command (command &optional cow)
  "Show ASCII art with COW saying the output of COMMAND.

COMMAND is passed to the system shell as with `shell-command'.

When called interactively, ask for the command in the minibuffer.
When a prefix argument is given, first ask which cow to use."
  (interactive
   (let ((cow (cowsay--prompt-for-cow current-prefix-arg)))
     (list (read-from-minibuffer
            "Shell command: " nil nil nil 'shell-command-history)
           cow)))
  (cowsay--display-string
   (called-interactively-p 'interactive)
   (cowsay--string-to-string (shell-command-to-string command) cow)))

(provide 'cowsay)

;;; cowsay.el ends here
