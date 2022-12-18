;;; org-grep.el --- Kind of M-x rgrep adapted for Org mode.

;; Copyright © 2013, 2014 Progiciels Bourbeau-Pinard inc.

;; Author: François Pinard <pinard@iro.umontreal.ca>
;; Maintainer: François Pinard <pinard@iro.umontreal.ca>
;; URL: https://github.com/pinard/org-grep
;; Package-Version: 20151202.1229
;; Package-Commit: 5bdd04c0f53b8a3d656f36ea17bba3df7f0cb684
;; Package-Requires: ((cl-lib "0.5"))

;; This is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software Foundation,
;; Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

;;; Commentary:

;; This tool allows for grepping files in a set of Org directories,
;; formatting the results as a separate Org buffer.  This buffer is
;; assorted with a few specific navigation commands so it works a bit
;; like M-x rgrep.  Optionally, the tool may simultaneously search
;; Unix mailboxes, Gnus mailgroups, or other textual files.

;; See https://github.com/pinard/org-grep.

;;; Code:

(require 'org)
(require 'cl-lib)

(defgroup org-grep nil
  "Kind of M-x rgrep adapted for Org mode."
  :group 'org)

(defvar org-grep-directories (list org-directory)
  "List of directories to search, default is org-directory only.")

(defvar org-grep-ellipsis " … "
  "Ellipsis text to replace any removed context, nil means no elision.")

(defvar org-grep-extensions '(".org")
  "List of extensions for searchable files.")

(defvar org-grep-extra-shell-commands nil
  "List of functions providing extra shell commands for grepping.
Each of such function is given REGEXP as an argument.")

(defvar org-grep-gnus-directory nil
  "Directory holding Gnus mail files.  Often \"~/Mail\".")

(defvar org-grep-grep-options "-i"
  "String containing default grep options.")

(defvar org-grep-hide-extension nil
  "Ignore extension while sorting and displaying.")

(defvar org-grep-maximum-context-size 200
  "Maximum size of a context chunk within a hit line, nil means no elision.")

(defvar org-grep-maximum-hits 1000
  "Maximum number of hits, nil means no limit.")

(defvar org-grep-rmail-shell-commands nil
  "List of functions providing shell commands to grep mailboxes.
Each of such function is given REGEXP as an argument.")

(defvar org-grep-shell-command nil
  "Shell executable for launching commands.")

(defface org-grep-match-face
  '((((background dark)) (:background "lavender" :foreground "black"))
    (t (:background "lavender")))
  "Face for each org-grep match.")

(defface org-grep-ellipsis-face
  '((((background dark)) (:background "pink" :foreground "black"))
    (t (:background "pink")))
  "Face for each org-grep ellipsis.")

;; These variables should ideally be buffer-local, but they do not
;; survive switching to Fundamental mode or Org mode.
(defvar org-grep-function nil)
(defvar org-grep-options nil)
(defvar org-grep-regexp nil)

(defvar org-grep-buffer-name "*Org Grep*")
(defvar org-grep-hit-regexp "^- ")
(defvar org-grep-message-initial "Finding occurrences...")
(defvar org-grep-message-final nil)
(defvar org-grep-regexp-history nil)
(defvar org-grep-temp-buffer nil)
(defvar org-grep-temp-buffer-file nil)
(defvar org-grep-temp-buffer-name "*Org Grep temp*")

;;; Main driver functions.

;;;###autoload
(defun org-grep (regexp &optional options)
  (interactive (org-grep-interact))
  (let ((org-grep-grep-options (or options org-grep-grep-options)))
    (org-grep-load-buffer regexp nil)
    (let ((buffer-undo-list t))
      (org-grep-display-browse))
    (message org-grep-message-final)))

;;;###autoload
(defun org-grep-full (regexp &optional arg)
  (interactive (org-grep-interact))
  (let ((org-grep-grep-options (or arg org-grep-grep-options)))
    (org-grep-load-buffer regexp t)
    (let ((buffer-undo-list t))
      (org-grep-display-browse))
    (message org-grep-message-final)))

(defun org-grep-interact ()
  (let ((options
         (if current-prefix-arg
             (read-string "Grep options: "
                          (and (not (string-equal org-grep-grep-options ""))
                               (concat org-grep-grep-options " ")))))
        (regexp
         (if (use-region-p)
             (buffer-substring (region-beginning) (region-end))
           (read-string "Enter a regexp to grep: " nil
                        'org-grep-regexp-history))))
    (list regexp options)))  

(defun org-grep-load-buffer (regexp full)
  (when (string-equal regexp "")
    (user-error "Nothing to find!"))

  ;; Prepare the hits buffer, removing its previous contents.
  (pop-to-buffer org-grep-buffer-name)
  (org-grep-clean-buffer t)

  ;; Save arguments so the command could be relaunched.
  (setq org-grep-function (if full 'org-grep-full 'org-grep))
  (setq org-grep-options org-grep-grep-options)
  (setq org-grep-regexp regexp)

  ;; Find occurrences.  Collecting methods prefix each matched line
  ;; with "- ", clickable information, then " :: ".
  (save-some-buffers t)
  (message org-grep-message-initial)
  (setq buffer-undo-list nil)
  (let ((buffer-undo-list t)
        (shell-file-name (or org-grep-shell-command shell-file-name)))
    (org-grep-from-org regexp)
    (when full
      (org-grep-from-rmail regexp)
      (org-grep-from-gnus regexp)
      (setq org-grep-temp-buffer-file nil))

    ;; Truncate the buffer if it contains too many hits.
    (let ((hit-count (count-lines (point-min) (point-max))))
      (if (not (and org-grep-maximum-hits
                    (> hit-count org-grep-maximum-hits)))
          (setq org-grep-message-final
                (concat org-grep-message-initial
                        (format " done (%d found)" hit-count)))
        (setq org-grep-message-final
              (concat org-grep-message-initial
                      (format " done (showing %d / %d)"
                              org-grep-maximum-hits hit-count)))
        ;; Sort lines so what is retained or not is less random.
        (sort-lines nil (point-min) (point-max))
        (goto-char (point-min))
        (forward-line org-grep-maximum-hits)
        (delete-region (point) (point-max)))

      hit-count)))

;;; Occurrences finders.

(defun org-grep-from-org (regexp)

  ;; Execute shell command.
  (goto-char (point-max))
  (let ((command (mapconcat (lambda (function) (apply function (list regexp)))
                            (cons 'org-grep-from-org-shell-command
                                  org-grep-extra-shell-commands)
                            "; ")))
    (shell-command command t))

  ;; Process received output.
  (while (re-search-forward "^\\([^:]+\\):\\([0-9]+\\):" nil t)
    (let* ((file (match-string 1))
           (line (string-to-number (match-string 2)))
           (base (if org-grep-hide-extension
                     (file-name-base file)
                   (file-name-nondirectory file)))
           (directory (file-name-directory file)))
      ;; Prefix found lines.
      (replace-match (concat "- [[file:\\1::\\2][" base "]]:\\2 :: "))
      (org-grep-shrink-line)
      ;; Moderately try to resolve relative links.
      (while (re-search-forward "\\[\\[\\([^]\n:]+:\\)?\\([^]]+\\)"
                                (line-end-position) t)
        (let ((method (match-string 1))
              (reference (match-string 2)))
          (cond ((not method)
                 (replace-match (concat "[[file:" file "::\\2")))
                ((member method '("file:" "rmail:"))
                 (unless (memq (aref reference 0) '(?~ ?/))
                   (replace-match
                    (concat "[[" method directory reference)))))))
      (forward-line 1))))

(defun org-grep-from-org-shell-command (regexp)
  (if org-grep-directories
      (concat "find "
              (if org-grep-directories
                  (mapconcat #'identity org-grep-directories " ")
                org-directory)
              (and org-grep-extensions
                   (concat " -regex '.*\\("
                           (mapconcat #'regexp-quote org-grep-extensions "\\|")
                           "\\)'"))
              " -print0 | xargs -0 grep " org-grep-grep-options
              " -n -- " (shell-quote-argument regexp))
    ":"))

(defun org-grep-from-gnus (regexp)
  (when (and org-grep-gnus-directory
             (file-directory-p org-grep-gnus-directory))

    ;; Execute shell command.
    (goto-char (point-max))
    (let ((command
           (concat
            "find " org-grep-gnus-directory " -type f"
            " | grep -v"
            " '\\(^\\|/\\)[#.]\\|~$\\|\\.mrk$\\|\\.nov$\\|\\.overview$'"
            " | grep -v"
            " '\\(^\\|/\\)\\(Incoming\\|archive/\\|active$\\|/junk$\\)'"
            " | xargs grep " org-grep-grep-options
            " -n -- " (shell-quote-argument regexp))))
      (shell-command command t))

    ;; Prefix found lines.
    (while (re-search-forward "^\\([^:]+\\):\\([0-9]+\\):" nil t)
      (let* ((file (match-string 1))
             (line (string-to-number (match-string 2)))
             (text (file-name-nondirectory file))
             (link (save-match-data (org-grep-message-link
                                    file line org-grep-gnus-directory))))
        (save-match-data
          (when (string-match "^[0-9]+$" text)
            (setq text (file-name-nondirectory
                        (substring (file-name-directory file) 0 -1)))))
        (replace-match
         (concat "- [[" link "][" text "]]:" (number-to-string line) " :: "))
        (org-grep-shrink-line)
        (forward-line 1)))))

(defun org-grep-from-rmail (regexp)

  ;; Execute shell command.
  (goto-char (point-max))
  (let ((command (mapconcat (lambda (function) (apply function (list regexp)))
                            org-grep-rmail-shell-commands "; ")))
    (shell-command command t))

  ;; Prefix found lines.
  (while (re-search-forward "^\\([^:]+\\):\\([0-9]+\\):" nil t)
    (let* ((file (match-string 1))
           (line (string-to-number (match-string 2)))
           (text (if org-grep-hide-extension
                     (file-name-base file)
                   (file-name-nondirectory file)))
           (link (save-match-data (org-grep-message-link file line nil))))
      (replace-match
       (concat "- [[" link "][" text "]]:" (number-to-string line) " :: "))
      (org-grep-shrink-line)
      (forward-line 1))))

;;; Buffer re-organization and display.

(defun org-grep-clean-buffer (erase)
  (fundamental-mode)
  (setq buffer-read-only nil
        buffer-undo-list nil)
  (let ((buffer-undo-list t))
    (if erase
        (erase-buffer)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((start (point)))
          (when (looking-at "- \\[.\\] ")
            (replace-match "- ")
            (beginning-of-line))
          (if (org-grep-skip-prefix)
              (let ((here (point)))
                (when (search-backward "][dired]] " start t)
                  (search-backward " [[file:")
                  (delete-region (point) (- here 4)))
                (forward-line 1))
            (forward-line 1)
            (delete-region start (point))))))))

(defun org-grep-display-browse ()
  (interactive)
  (org-grep-sort-and-disambiguate)

  ;; Insert title and overall header.
  (goto-char (point-min))
  (insert "#+TITLE: " (org-grep-title-string "browse") "\n"
          "\n"
          "* Occurrences\n")

  ;; Activate Org mode on the results.
  (org-mode)
  (goto-char (point-min))
  (show-all)

  ;; Highlight the search string and each ellipsis.
  (hi-lock-face-buffer (org-grep-hi-lock-helper org-grep-regexp)
                       'org-grep-match-face)
  (hi-lock-face-buffer (regexp-quote org-grep-ellipsis)
                       'org-grep-ellipsis-face)

  ;; Add special commands to the keymap.
  (use-local-map (copy-keymap (current-local-map)))
  (setq buffer-read-only t)
  (local-set-key "\C-c\C-c" 'org-grep-current-jump)
  (local-set-key "\C-x`" 'org-grep-next-jump)
  (local-set-key "." 'org-grep-current)
  (local-set-key "e" 'org-grep-display-edit)
  (local-set-key "g" 'org-grep-revert)
  (local-set-key "n" 'org-grep-next)
  (local-set-key "p" 'org-grep-previous)
  (local-set-key "q" 'org-grep-quit)
  (local-set-key "t" 'org-grep-display-tree)
  (when (boundp 'org-mode-map)
    (define-key org-mode-map "\C-x`" 'org-grep-maybe-next-jump)))

(defun org-grep-display-edit ()
  (interactive)
  (org-grep-sort-and-disambiguate)
  (goto-char (point-min))
  (insert "#+TITLE: " (org-grep-title-string "edit") "\n"
          "\n"
          "* Editable occurrences\n")
  (while (re-search-forward org-grep-hit-regexp nil t)
    (insert "[ ] ")
    (forward-line 1))
  (org-mode)
  (goto-char (point-min))
  (show-all))

(defun org-grep-display-tree ()
  (interactive)
  (let ((buffer (current-buffer))
        (temp (get-buffer-create org-grep-temp-buffer-name))
        ;; INFO is a recursive structure, made up of a list of ITEMs.
        ;; Each ITEM is either (START . END) or (SUBDIR INFO).  START
        ;; and END are integers specifying the limits of a textual
        ;; region in the original, already sorted hits buffer.  SUBDIR
        ;; is a string representing the last fragment of a file path.
        info current-file start)

    ;; Digest all needed information into INFO.
    (save-current-buffer
      (set-buffer temp)
      (erase-buffer)
      (insert-buffer-substring buffer)
      (org-grep-clean-buffer nil)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((prefix-info (org-grep-skip-prefix)))
          (when prefix-info
            (let ((method (car prefix-info))
                  (file (cl-caddr prefix-info)))
              (unless (and current-file (string-equal file current-file))
                (beginning-of-line)
                (when current-file
                  (setq info (org-grep-display-tree-add-file
                              info start (point) current-file)))
                (setq current-file file
                      start (point))))))
        (forward-line 1))
      (when (and start (> (point-max) start))
        (setq info (org-grep-display-tree-add-file
                    info start (point-max) current-file))))

    ;; Reorganise all saved information.
    (org-grep-clean-buffer t)
    (insert "#+TITLE: " (org-grep-title-string "tree") "\n"
            "\n")
    ;; The first SUBDIR is always empty, this loop pops it out.
    (mapc (lambda (pair)
            (org-grep-display-tree-rebuild (cdr pair) temp "*" (car pair)))
          (org-grep-display-tree-sort-info info)))

  ;; Reactivate Org mode.
  (org-mode)
  (goto-char (point-min))
  (org-overview)
  (org-content))

(defun org-grep-display-tree-add-file (info start end text)
  (setq text (abbreviate-file-name (file-name-directory text)))
  (when (= (aref text (1- (length text))) ?/)
    (setq text (substring text 0 (1- (length text)))))
  (org-grep-display-tree-digest
   info start end
   (mapcar (lambda (fragment) (concat fragment "/"))
           (split-string text "/"))))

(defun org-grep-display-tree-digest (info start end fragments)
  "Return INFO recording that START to END are used for path FRAGMENTS."
  (if fragments
      (let ((pair (assoc (car fragments) info)))
        (if (not pair)
            (cons (cons (car fragments)
                        (org-grep-display-tree-digest
                         nil start end (cdr fragments)))
                  info)
          (rplacd pair (org-grep-display-tree-digest
                        (cdr pair) start end (cdr fragments)))
          info))
    (cons (cons start end) info)))

(defun org-grep-display-tree-rebuild (info buffer prefix path)

    ;; Collapse hierarchy whenever possible.
    (while (and (= (length info) 1) (stringp (caar info)))
      (setq path (concat path (caar info))
            info (cdar info)))

    ;; Insert an Org header.
    (insert prefix " [[file:" path "][dired]] =" path "=\n")

    ;; Insert all information under that header.
    (mapc (lambda (pair)
            (if (stringp (car pair))
                ;; We have (SUBDIR INFO).  Insert subdirectories recursively.
                (org-grep-display-tree-rebuild
                 (cdr pair) buffer (concat prefix "*")
                 (concat path (car pair)))
              ;; We have (START . END).  Insert from the original hits buffer.
              (insert-buffer-substring buffer (car pair) (cdr pair))))
          (org-grep-display-tree-sort-info info)))

(defun org-grep-display-tree-sort-info (info)
  "Sort INFO to get all (START . END) first, then all (SUBDIR INFO)."
  (sort info (lambda (a b)
               (if (stringp (car a))
                   (and (stringp (car b))
                        (string-lessp (car a) (car b)))
                 (or (stringp (car b))
                     (< (car a) (car b)))))))

(defun org-grep-sort-and-disambiguate ()
  (org-grep-clean-buffer nil)
  (let (base-info duplicates current-file)

    ;; Decorate and sort, while taking note of duplicate keys.
    (goto-char (point-min))
    (while (not (eobp))
      (let ((prefix-info (org-grep-skip-prefix)))
        (when prefix-info
          (let* ((text (cadr prefix-info))
                 (file (cl-caddr prefix-info))
                 (line (cl-cadddr prefix-info))
                 (base (downcase text))
                 (pair (assoc base base-info)))
            (beginning-of-line)
            (insert base "\0" file "\0" (format "%5s" line) "\0")
            (cond ((not pair) (setq base-info (cons (cons base file) base-info)))
                  ((string-equal (cdr pair) file))
                  ((member (car pair) duplicates))
                  (t (setq duplicates (cons base duplicates))))))
        (forward-line 1)))
    (sort-lines nil (point-min) (point-max))

    ;; Undecorate, while adding disambiguating information.
    (goto-char (point-min))
    (while (not (eobp))
      (looking-at "[^\0]*\0[^\0]*\0[^\0]*\0")
      (delete-region (match-beginning 0) (match-end 0))
      (let ((prefix-info (org-grep-skip-prefix)))
        (let ((text (cadr prefix-info))
              (file (cl-caddr prefix-info)))
          (if (or (= (following-char) ?\n)
                  (member text duplicates))
              (unless (and current-file (string-equal file current-file))
                (let ((directory (file-name-directory file)))
                  (backward-char 4)
                  (insert " [[file:" directory "::" (regexp-quote text)
                          "][dired]] ="
                          (abbreviate-file-name
                           (if org-grep-hide-extension file directory))
                          "=")
                  (forward-char 4))
                (setq current-file file))
            (setq current-file nil))))
      (forward-line 1))))

;;; Additional commands for an Org Grep hits buffer.

(defun org-grep-current ()
  (interactive)
  ;; FIXME: save-current-buffer fails: the current buffer is not restored.
  (save-current-buffer (org-grep-current-jump)))

(defun org-grep-current-jump ()
  (interactive)
  ;; FIXME: org-reveal fails: the goal line stays collapsed and hidden.
  (beginning-of-line)
  (forward-char 2)
  (org-open-at-point)
  (org-reveal))

(defun org-grep-maybe-next-jump ()
  (interactive)
  (let ((buffer (current-buffer))
        (hits (get-buffer org-grep-buffer-name))
        jumped)
    (when hits
      (pop-to-buffer hits)
      (when (re-search-forward org-grep-hit-regexp nil t)
        (org-grep-current-jump)
        (setq jumped t)))
    (unless jumped
      (set-buffer buffer)
      (next-error))))

(defun org-grep-next ()
  (interactive)
  (when (re-search-forward org-grep-hit-regexp nil t)
    (org-grep-current)))

(defun org-grep-next-jump ()
  (interactive)
  (when (re-search-forward org-grep-hit-regexp nil t)
    (org-grep-current-jump)))

(defun org-grep-previous ()
  (interactive)
  (when (re-search-backward org-grep-hit-regexp nil t)
    (forward-char 2)
    (org-grep-current)))

(defun org-grep-quit ()
  (interactive)
  (kill-buffer))

(defun org-grep-revert ()
  (interactive)
  (when org-grep-regexp
    (let ((org-grep-grep-options org-grep-options))
      (apply org-grep-function org-grep-regexp nil))))

;;; Miscellaneous service functions.

(defun org-grep-message-link (file line gnus-directory)
  (unless (and org-grep-temp-buffer (buffer-name org-grep-temp-buffer))
    (setq org-grep-temp-buffer (get-buffer-create org-grep-temp-buffer-name)))
  (save-excursion
    (set-buffer org-grep-temp-buffer)
    (unless (string-equal file org-grep-temp-buffer-file)
      (erase-buffer)
      (insert-file file)
      (setq org-grep-temp-buffer-file file))
    (let ((case-fold-search t))
      (goto-line line)
      ;; FIXME: Should limit search to current message header!
      (if (not (search-backward "\nmessage-id:" nil t))
          (concat "file:" file "::" (number-to-string line))
        (forward-char 12)
        (skip-chars-forward " ")
        (let ((id (buffer-substring (point) (line-end-position))))
          (if gnus-directory
              (let ((group (dired-make-relative file gnus-directory)))
                (if (string-equal (substring group 0 6) "/nnml/")
                    (concat "gnus:nnml:"
                            (substring (file-name-directory group) 6 -1)
                            "#" id)
                  (concat "gnus:nnfolder:" (substring group 1) "#" id)))
            (concat "rmail:" file "#" id)))))))

(defun org-grep-hi-lock-helper (regexp)
  ;; Stolen from hi-lock-process-phrase.
  ;; FIXME: ASCII only.  Sad that hi-lock ignores case-fold-search!
  ;; Also, hi-lock-face-phrase-buffer does not have an unface counterpart.
  (if (string-match "\\b-[A-Za-z]*i" org-grep-grep-options)
      (replace-regexp-in-string
       "\\<[a-z]"
       (lambda (text) (format "[%s%s]" (upcase text) text))
       regexp)
    regexp))

(defun org-grep-shrink-line ()
  "Try to shorten the remaining of line.  Do not move point."
  (let ((here (point))
        (limit (line-end-position)))

    ;; Remove extra whitespace.
    (while (re-search-forward " [ \f\t\b]+\\|[\f\t\b][ \f\t\b]*" limit t)
      (replace-match "  ")
      (setq limit (line-end-position)))

    ;; Possibly elide big contexts.
    (when (and org-grep-ellipsis org-grep-maximum-context-size)
      (let* ((ellipsis-length (length org-grep-ellipsis))
             (distance-trigger (+ org-grep-maximum-context-size
                                  ellipsis-length))
             (half-maximum (/ org-grep-maximum-context-size 2))
             start-context end-context
             resume-point end-delete delete-size shrink-delta)
        (goto-char here)
        (while (< (point) limit)
          (setq start-context (point))
          (if (re-search-forward regexp limit t)
              (setq end-context (match-beginning 0)
                    resume-point (match-end 0))
            (setq end-context limit
                  resume-point limit))
          (when (> (- end-context start-context) distance-trigger)
            (goto-char (- end-context half-maximum))
            (forward-word)
            (backward-word)
            (setq end-delete (point))
            (goto-char (+ start-context half-maximum))
            (backward-word)
            (forward-word)
            (setq delete-size (- end-delete (point))
                  shrink-delta (- delete-size ellipsis-length))
            (when (> shrink-delta 0)
              (delete-char delete-size)
              (insert org-grep-ellipsis)
              (setq resume-point (- resume-point shrink-delta)
                    limit (- limit shrink-delta))))
          (goto-char resume-point))))

    (goto-char here)))

(defun org-grep-skip-prefix ()
  "Skip line prefix and return (METHOD TEXT FILE LINE); else return nil."
  ;; Carefully avoid matching "*" or "+" beyond " :: "; otherwise, the
  ;; Emacs stack might explode on very long lines.
  (let ((here (point)))
    (when (and (looking-at "^- \\[\\[")
               (search-forward " :: " (line-end-position) t))
      (let ((prefix (buffer-substring (+ here 4) (- (point) 4))))
        (when (string-match "\\`\\(.+\\)\\]\\[\\(.*\\)\\]\\]:\\([0-9]+\\)"
                            prefix)
          (let ((ref (match-string-no-properties 1 prefix))
                (text (match-string-no-properties 2 prefix))
                (line (match-string-no-properties 3 prefix))
                method file)
            (cond ((string-match "\\`file:\\(.+\\)::" ref)
                   (list 'file text (match-string 1 ref) line))
                  ((string-match "\\`gnus:\\(nnml\\|nnfolder\\):\\(.*\\)#" ref)
                   (list 'gnus text (match-string 2 ref) line))
                  ((string-match "\\`rmail:\\(.*\\)#" ref)
                   (list 'rmail text (match-string 1 ref) line)))))))))

(defun org-grep-title-string (mode)
  (let ((modes '("browse" "edit" "tree"))
        (result ""))
    (setq result (concat org-grep-regexp
                         " (" (symbol-name org-grep-function)))
    (when (not (string-equal org-grep-grep-options ""))
      (setq result (concat result " " org-grep-grep-options)))
    (setq result (concat result ")    "))
    (while modes
      (setq result (concat result " "
                           (if (string-equal mode (car modes))
                               (car modes)
                             (concat "[[elisp:(org-grep-display-"
                                     (car modes) ")][" (car modes) "]]"))))
      (setq modes (cdr modes)))
    result))

(provide 'org-grep)
;;; org-grep.el ends here
