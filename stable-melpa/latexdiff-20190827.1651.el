;;; latexdiff.el --- Latexdiff integration in Emacs

;; Copyright (C) 2016-2017 Launay Gaby

;; Author: Launay Gaby <gaby.launay@tutanota.com>
;; Maintainer: Launay Gaby <gaby.launay@tutanota.com>
;; Package-Requires: ((emacs "24.4"))
;; Package-Version: 20190827.1651
;; Package-Commit: 56d0b240867527d1b43d3ddec14059361929b971
;; Version: 0.1.0
;; Keywords: tex, vc, tools, git, helm
;; URL: http://github.com/galaunay/latexdiff.el

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Latexdiff.el is a backend for
;; [Latexdiff](https://github.com/ftilmann/latexdiff).

;; latexdiff requires Emacs-24.4 or later
;; and optionnaly [Helm](https://github.com/emacs-helm/helm).

;; Configuration:

;; latexdiff faces and behaviour can be customized through the customization
;; panel :
;; `(customize-group 'latexdiff)`
;; Latexdiff.el does not define default keybindings, so you may want to add
;; some using `define-key`.

;; Basic usage

;; File to file diff:
;; - `latexdiff` will ask for two tex files and generates a tex diff between
;;   them (that you will need to compile).
;; Version diff (git repo only):
;; - `latexdiff-vc` (and `helm-latexdiff-vc`) will ask for a previous commit
;;   number and make a pdf diff between this version and the current one.
;; - `latexdiff-vc-range` (and `helm-latexdiff-vc-range`) will ask for two
;;   commits number and make a pdf diff between those two versions.


;;; Code:

(require 'seq)


;; Faces and variables
;;;;;;;;;;;;;;;;;;;;;;;;

(defvar-local latexdiff-runningp nil
  "t when a latexdiff process is running for the current buffer")

(defcustom latexdiff-args
  '()
  "Arguments passed to 'latexdiff'.

You may want to add '--flatten' if you have project with
multiple files."
  :type 'string
  :group 'latexdiff)

(defcustom latexdiff-vc-args
  '()
  "Arguments passed to 'latexdiff-vc'.

'--force' '--dir' and '--pdf' are used whatever you set here to ensure the
smooth operation of latexdiff.el.

You may want to add '--flatten' if you have project with
multiple files."
  :type 'string
  :group 'latexdiff)

(defcustom latexdiff-auto-display t
  "If set to `t`, generated diff pdf and tex files are automatically displayed after generation."
  :type 'boolean
  :group 'latexdiff)

(defcustom latexdiff-pdf-viewer "Emacs"
  "Command use to view PDF diffs.

If set to 'Emacs' (default), open the PDF within Emacs."
  :type 'string
  :group 'latexdiff)

(defface latexdiff-ref-labels-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for the ref-labels"
  :group 'latexdiff)

(defface latexdiff-date-face
  '((t (:inherit font-lock-variable-name-face)))
  "Face for the date"
  :group 'latexdiff)

(defface latexdiff-author-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for the author"
  :group 'latexdiff)

(defface latexdiff-message-face
  '((t (:inherit default)))
  "Face for the message"
  :group 'latexdiff)

(defgroup latexdiff nil
  "latexdiff integration in Emacs."
  :prefix "latexdiff-"
  :group 'tex
  :link `(url-link :tag "latexdiff homepage" "https://github.com/galaunay/latexdiff.el"))


;; Internal functions
;;;;;;;;;;;;;;;;;;;;;;;


(defun latexdiff--check-if-installed ()
  "Check if latexdiff is installed."
  (with-temp-buffer
    (call-process "/bin/sh" nil t nil "-c"
                  "hash latexdiff 2>/dev/null || echo 'NOT INSTALLED'")
    (goto-char (point-min))
    (if (re-search-forward "NOT INSTALLED" (point-max) t)
        (error "'latexdiff' is not installed, please install it")))
  (with-temp-buffer
    (call-process "/bin/sh" nil t nil "-c"
                  "hash latexdiff-vc 2>/dev/null || echo 'NOT INSTALLED'")
    (goto-char (point-min))
    (if (re-search-forward "NOT INSTALLED" (point-max) t)
        (error "'latexdiff-vc' is not installed, please install it"))))


(defun latexdiff--check-if-file-produced (diff-file)
  "Check if DIFF-FILE has been produced."
  (and (file-exists-p diff-file)
       (not (eq (nth 7 (file-attributes diff-file)) 0))))


(defun latexdiff--display-pdf (filename)
  "Display the pdf FILENAME according to `latexdiff-pdf-viewer'."
  (if (string= latexdiff-pdf-viewer "Emacs")
      (find-file filename)
    (call-process "/bin/sh" nil 0 nil "-c"
                  (format "%s %s"
                          (shell-quote-argument latexdiff-pdf-viewer)
                          (shell-quote-argument filename)))))


(defun latexdiff--latexdiff-sentinel (proc msg)
  "Sentinel for latexdiff executions.

PROC is the process to watch and MSG the message to
display when the process ends"
  (let* ((diff-file (process-get proc 'diff-file))
         (file1 (process-get proc 'file1))
         (file2 (process-get proc 'file2))
         (filename1 (file-name-base file1))
         (filename2 (file-name-base file2)))
    (kill-buffer " *latexdiff*")
    ;; Display the TeX file if asked
    (when latexdiff-auto-display
      (message "[%s] Displaying TeX diff with %s" filename1 filename2)
      (find-file (format "%s.tex" diff-file))))
  (setq latexdiff-runningp nil))


(defun latexdiff--compile-diff (file1 file2 &optional dir)
  "Use latexdiff to compile the diff between FILE1 and FILE2.

DIR is the path where the diff should be generated, default to the directory
of FILE1 if nil.

Just generate a tex file, you still have to compile it to get a pdf diff."
  (let* ((file1 (expand-file-name file1))
         (file2 (expand-file-name file2))
         (filename1 (file-name-base file1))
         (filename2 (file-name-base file2))
         (diff-dir (if dir (expand-file-name dir)
                     (format "%sdiff-%s" (file-name-directory file1) filename2)))
         (diff-file (format "%s%s-%s-diff"
                            (file-name-as-directory diff-dir)
                            filename1
                            filename2))
         (default-directory diff-dir)
         (process nil))
    (mkdir diff-dir t)
    (latexdiff--check-if-installed)
    (setq latexdiff-runningp t)
    (message "[%s] Generating latex diff with %s" filename1 filename2)
    (setq process (start-process "latexdiff"
                                 " *latexdiff*"
                                 "/bin/sh" "-c"
                                 (format "yes X | latexdiff %s %s %s > %s.tex 2>&1 ;"
                                         (mapconcat 'shell-quote-argument
                                                    latexdiff-args " ")
                                         (shell-quote-argument file1)
                                         (shell-quote-argument file2)
                                         (shell-quote-argument diff-file))))
    (process-put process 'diff-file diff-file)
    (process-put process 'file1 file1)
    (process-put process 'file2 file2)
    (set-process-sentinel process 'latexdiff--latexdiff-sentinel)
    diff-file))


(defun latexdiff-vc--latexdiff-sentinel (proc msg)
  "Sentinel for latexdiff executions.

PROC is the process to watch and MSG the message to
display when the process ends."
  (let ((diff-dir (process-get proc 'diff-dir))
        (file (process-get proc 'file))
        (REV1 (process-get proc 'rev1))
        (REV2 (process-get proc 'rev2)))
    (kill-buffer " *latexdiff*")
    ;; Remove additional files created by latexdiff-vc
    (let ((file-to-del
           (directory-files default-directory t
                            (format "%s-\\(old\\|new\\)tmp-[0-9]+.tex" file))))
      (seq-do 'delete-file file-to-del))
    ;; Check if tex file has been produced
    (if (not (latexdiff--check-if-file-produced (format "%s/%s.pdf" diff-dir file)))
        (progn
          (find-file-noselect "latexdiff.log")
          (with-current-buffer (get-buffer-create "*latexdiff-log*")
            (erase-buffer)
            (insert-buffer-substring "latexdiff.log"))
          (kill-buffer "latexdiff.log")
          (message "[%s] PDF file has not been produced, check `%s' buffer for more information"
                   file "*latexdiff-log*"))
      ;; Display the tex file if asked
      (when latexdiff-auto-display
        (message "[%s] Displaying PDF diff between %s and %s" file REV1 REV2)
        (latexdiff--display-pdf (format "%s/%s.pdf" diff-dir file)))))
  (setq latexdiff-runningp nil))


(defun latexdiff-vc--compile-diff (REV1 REV2)
  "Use latexdiff to compile a pdf file of the difference between REV1 and REV2."
  (let* ((file (file-name-base))
         (diff-dir (format "%sdiff%s-%s" default-directory REV1 REV2))
         (process nil))
    (latexdiff--check-if-installed)
    (setq latexdiff-runningp t)
    (message "[%s] Generating latex diff between %s and %s" file REV1 REV2)
    (setq process (start-process "latexdiff" " *latexdiff*"
                                 "/bin/sh" "-c"
                                 (format "yes X | latexdiff-vc --pdf --force --dir --git %s -r %s -r %s %s.tex > latexdiff.log 2>&1 ;"
                                         (mapconcat 'shell-quote-argument
                                                    latexdiff-vc-args
                                                    " ")
                                         (shell-quote-argument REV1)
                                         (shell-quote-argument REV2)
                                         (shell-quote-argument file))))
    (process-put process 'diff-dir diff-dir)
    (process-put process 'file file)
    (process-put process 'rev1 REV1)
    (process-put process 'rev2 REV2)
    (set-process-sentinel process 'latexdiff-vc--latexdiff-sentinel)
    diff-dir))


(defun latexdiff-vc--compile-diff-with-current (REV)
  "Use latexdiff to compile a pdf file of the difference between the current state and REV."
  (let* ((file (file-name-base))
         (diff-dir (format "%sdiff%s" default-directory REV))
         (process nil))
    (latexdiff--check-if-installed)
    (setq latexdiff-runningp t)
    (message "[%s] Generating latex diff with %s" file REV)
    (setq process (start-process "latexdiff" " *latexdiff*"
                                 "/bin/sh" "-c"
				 (format "yes X | latexdiff-vc --dir --pdf --force --git %s -r %s %s.tex > latexdiff.log 2>&1 ;"
                                         (mapconcat 'shell-quote-argument
                                                    latexdiff-vc-args
                                                    " ")
                                         (shell-quote-argument REV)
                                         (shell-quote-argument file))))
    (process-put process 'diff-dir diff-dir)
    (process-put process 'file file)
    (process-put process 'rev1 "current")
    (process-put process 'rev2 REV)
    (set-process-sentinel process 'latexdiff-vc--latexdiff-sentinel)
    diff-dir))


(defun latexdiff--get-commits-infos ()
  "Return a list with all commits informations."
  (let ((infos nil))
    (with-temp-buffer
      (vc-git-command t nil nil
                      "log" "--all" "--format=%h---%cr---%cn---%s---%d"
                      "--abbrev-commit" "--date=short")
      (goto-char (point-min))
      (while (re-search-forward "^.+$" nil t)
        (push (split-string (match-string 0) "---") infos)))
    infos))


(defun latexdiff--get-commits-description ()
  "Return a nice list of string descripting the current repo commits.

Used to show nice commit description during commit selection."
  (let ((descriptions ())
        (infos (latexdiff--get-commits-infos))
        (col-lengths '((l1 . 0) (l2 . 0) (l3 . 0) (l4 . 0))))
    ;; Get col-lengths
    (dolist (tmp-desc infos)
      (pop tmp-desc)
      (when (> (length (nth 0 tmp-desc)) (cdr (assoc 'l1 col-lengths)))
        (add-to-list 'col-lengths `(l1 . ,(length (nth 0 tmp-desc)))))
      (when (> (length (nth 1 tmp-desc)) (cdr (assoc 'l2 col-lengths)))
        (add-to-list 'col-lengths `(l2 . ,(length (nth 1 tmp-desc)))))
      (when (> (length (nth 2 tmp-desc)) (cdr (assoc 'l3 col-lengths)))
        (add-to-list 'col-lengths `(l3 . ,(length (nth 2 tmp-desc)))))
      (when (> (length (nth 3 tmp-desc)) (cdr (assoc 'l4 col-lengths)))
        (add-to-list 'col-lengths `(l4 . ,(length (nth 3 tmp-desc))))))
    ;; Get infos
    (dolist (tmp-desc infos)
      (pop tmp-desc)
      (push (mapconcat (lambda (obj) obj)
                       (list
                        (propertize (format
                                     (format "%%-%ds "
                                             (cdr (assoc 'l2 col-lengths)))
                                     (nth 1 tmp-desc))
                                    'face 'latexdiff-author-face)
                        (propertize (format
                                     (format "%%-%ds "
                                             (cdr (assoc 'l1 col-lengths)))
                                     (nth 0 tmp-desc))
                                    'face 'latexdiff-date-face)
                        (propertize (format "%s"
                                            (nth 3 tmp-desc))
                                    'face 'latexdiff-ref-labels-face)
                        (propertize (format "%s"
                                            (nth 2 tmp-desc))
                                    'face 'latexdiff-message-face))
                       " ")
            descriptions))
    descriptions))


(defun latexdiff--get-commits-hashes ()
  "Return the list of commits hashes."
  (let ((hashes ())
        (infos (latexdiff--get-commits-infos))
        (tmp-desc nil))
    (dolist (tmp-desc infos)
      (push (pop tmp-desc) hashes))
    hashes))


(defun latexdiff--get-commit-hash-alist ()
  "Return a list of alist (HASH . COMMITS-DESCRIPTION) for each commit."
  (let ((descr (latexdiff--get-commits-description))
        (hash (latexdiff--get-commits-hashes))
        (list ()))
    (while (not (equal (length descr) 0))
      (setq list (cons (cons (pop descr) (pop hash)) list)))
    (reverse list)))


;; User function
;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun latexdiff ()
  "Ask for two tex files and make the difference between them."
  (interactive)
  (let ((file1 (expand-file-name (read-file-name "Base file: "
                                                 nil nil t nil)))
        (file2 (expand-file-name (read-file-name "Revised file: "
                                                 nil nil t nil))))
    (latexdiff--compile-diff file1 file2)))


;;;###autoload
(defun latexdiff-vc ()
  "Compile the pdf difference between the choosen commit and the current version of the current file."
  (interactive)
  (let* ((commits (latexdiff--get-commit-hash-alist))
         (commit (completing-read "Choose a commit:" commits))
         (commit-hash (cdr (assoc commit commits))))
    (latexdiff-vc--compile-diff-with-current commit-hash)))


;;;###autoload
(defun latexdiff-vc-range ()
  "Compile the pdf difference between two choosen commits."
  (interactive)
  (let* ((commits (latexdiff--get-commit-hash-alist))
         (commit1 (completing-read "Base commit:" commits))
         (commit1-hash (cdr (assoc commit1 commits)))
         (commit2 (completing-read "Revised commit:" commits))
         (commit2-hash (cdr (assoc commit2 commits))))
    (latexdiff-vc--compile-diff commit1-hash commit2-hash)))


;; Helm
;;;;;;;;;

(with-eval-after-load "helm-mode"
  (require 'helm-source)

  (defvar helm-source-latexdiff-choose-commit
    (helm-build-sync-source "Latexdiff choose a commit:"
      :candidates 'latexdiff--get-commit-hash-alist
      :action '(("Choose this commit" .
                 latexdiff-vc--compile-diff-with-current)))
    "Helm source for modified projectile projects.")


  (defun helm-latexdiff-vc ()
    "Ask for a commit and make the difference with the current version."
    (interactive)
    (helm :sources 'helm-source-latexdiff-choose-commit
          :buffer "*latexdiff*"
          :nomark t
          :prompt "Choose a commit: "))


  (defun helm-latexdiff-vc-range ()
    "Ask for two commits and make the difference between them."
    (interactive)
    (let* ((commits (latexdiff--get-commit-hash-alist))
           (rev1 (helm-comp-read "Base commit: " commits))
           (rev2 (helm-comp-read "Revised commit: " commits)))
      (latexdiff-vc--compile-diff rev1 rev2)))
  )

(provide 'latexdiff)
;;; latexdiff.el ends here
