;;; el2org.el --- Convert elisp file to org file

;; * Header
;; #+BEGIN_EXAMPLE
;; Copyright (C) 2017 Feng Shu

;; Author: Feng Shu  <tumashu AT 163.com>
;; Homepage: https://github.com/tumashu/el2org
;; Keywords: convenience
;; Package-Version: 20170805.442
;; Package-Commit: 4a33469cd305e581603d7ef63bc2a1f2156f2e2e
;; Package-Requires: ((emacs "25.1"))
;; Version: 0.10

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
;; #+END_EXAMPLE

;;; Commentary:

;; * What is el2org                                      :README:
;; el2org is a simple tool, which can convert a emacs-lisp file to org file.
;; You can write code and document in a elisp file with its help.

;; #+BEGIN_EXAMPLE
;;            (convert to)                    (export to)
;; elisp  -----------------> org (internal) --------------> other formats
;; #+END_EXAMPLE

;; Note: el2org.el file may be a good example.

;; [[./snapshots/el2org.gif]]

;; ** Installation

;; 1. Config melpa source, please read: [[http://melpa.org/#/getting-started]]
;; 2. M-x package-install RET el2org RET
;; 3. M-x package-install RET ox-gfm RET

;;    ox-gfm is needed by `el2org-generate-readme', if ox-gfm can not be found,
;;    ox-md will be used as fallback.

;; ** Configure

;; #+BEGIN_EXAMPLE
;; (require 'el2org)
;; (require 'ox-gfm)
;; #+END_EXAMPLE

;; ** Usage

;; 1. `el2org-generate-file' can convert an elisp file to other file format
;;     which org's exporter support.
;; 2. `el2org-generate-readme' can generate README.md from elisp's "Commentary"
;;     section.
;; 3. `el2org-generate-html' can generate a html file from current elisp file
;;    and browse it.
;; 4. `el2org-generate-org' can generate a org file from current elisp file.

;;; Code:

;; * el2org's code                                                        :code:
(require 'lisp-mode)
(require 'thingatpt)
(require 'org)
(require 'ox-org)

(defvar el2org-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap "\C-c.." 'el2org-generate-readme)
    keymap)
  "Keymap for `el2org-mode'")

(define-minor-mode el2org-mode
  "Minor for el2org."
  nil " el2org" 'el2org-mode-map)

(defun el2org-in-src-block-p ()
  "If the current point is in BEGIN/END_SRC block, return t."
  (let ((begin1 (save-excursion
                  (if (re-search-backward ";; #[+]BEGIN_SRC emacs-lisp" nil t)
                      (point)
                    (point-min))))
        (begin2 (save-excursion
                  (if (re-search-backward ";; #[+]END_SRC" nil t)
                      (point)
                    (point-min))))
        (end1 (save-excursion
                (if (re-search-forward "\n;; #[+]BEGIN_SRC emacs-lisp" nil t)
                    (point)
                  (point-max))))
        (end2 (save-excursion
                (if (re-search-forward "\n;; #[+]END_SRC" nil t)
                    (point)
                  (point-max)))))
    (and (> begin1 begin2) (> end1 end2))))

(defun el2org-generate-file (el-file tags backend output-file &optional force with-tags)
  (when (and (string-match-p "\\.el$" el-file)
             (file-exists-p el-file)
             (or force
                 (not (file-exists-p output-file))
                 (file-newer-than-file-p el-file output-file)))
    (with-temp-buffer
      (insert-file-contents el-file)
      (emacs-lisp-mode)
      ;; Add "#+END_SRC"
      (goto-char (point-min))
      (let ((status t))
        (while status
          (thing-at-point--end-of-sexp)
          (end-of-line)
          (unless (< (point) (point-max))
            (setq status nil))
          (insert "\n;; #+END_SRC")))
      ;; Add "#+BEGIN_SRC"
      (goto-char (point-max))
      (let ((status t))
        (while status
          (thing-at-point--beginning-of-sexp)
          (if (> (point) (point-min))
              (insert ";; #+BEGIN_SRC emacs-lisp\n")
            (setq status nil))))
      ;; Deal with first line if it prefix with ";;;"
      (goto-char (point-min))
      (while (re-search-forward "^;;;.*---[ ]+" (line-end-position) t)
        (replace-match ";; #+TITLE: " nil t))
      ;; Remove lexical-binding string
      (goto-char (point-min))
      (while (re-search-forward "[ ]*-\\*-.*-\\*-[ ]*$"
                                (line-end-position) t)
        (replace-match "" nil t))
      ;; Indent the buffer, so ";;" and ";;;" in sexp will not be removed.
      (indent-region (point-min) (point-max))
      ;; Add protect-mask to the beginning of "^;;[;]+" in string.
      (goto-char (point-min))
      (while (not (eobp))
        (beginning-of-line)
        (let ((content (buffer-substring
                        (line-beginning-position)
                        (line-end-position))))
          (when (and (el2org-in-src-block-p)
                     (string-match-p "^;;[; ]" content))
            (goto-char (line-beginning-position))
            (insert "&&el2org&&")
            (goto-char (line-beginning-position))))
        (forward-line))
      ;; Deal with ";; Local Variables:" and ";; End:"
      (goto-char (point-min))
      (while (re-search-forward "^;;+[ ]+Local[ ]+Variables: *" nil t)
        (replace-match ";; #+BEGIN_EXAMPLE\n;; Local Variables:" nil t))
      (goto-char (point-min))
      (while (re-search-forward "^;;+[ ]+End: *" nil t)
        (replace-match ";; End:\n;; #+END_EXAMPLE" nil t))
      ;; Deal with ";;;"
      (goto-char (point-min))
      (while (re-search-forward "^;;;" nil t)
        (replace-match "# ;;;" nil t))
      ;; Deal with ";;"
      (goto-char (point-min))
      (while (re-search-forward "^;;[ ]?" nil t)
        (replace-match "" nil t))
      ;; Delete useless "BEGIN_SRC/END_SRC"
      (goto-char (point-min))
      (while (re-search-forward "^#[+]BEGIN_SRC[ ]+emacs-lisp\n+#[+]END_SRC\n*" nil t)
        (replace-match "" nil t))
      (goto-char (point-min))
      (while (re-search-forward "^#[+]END_SRC\n#[+]BEGIN_SRC[ ]+emacs-lisp\n" nil t)
        (replace-match "" nil t))
      ;; Remove protect-mark.
      (goto-char (point-min))
      (while (re-search-forward "^&&el2org&&" nil t)
        (replace-match "" nil t))
      ;; Export
      (org-mode)
      (let ((org-export-select-tags tags)
            (org-export-with-tags with-tags)
            (indent-tabs-mode nil)
            (tab-width 4))
        (org-export-to-file backend output-file))
      output-file)))

;;;###autoload
(defun el2org-generate-readme ()
  "Generate README.md from current emacs-lisp file."
  (interactive)
  (let* ((file (or (buffer-file-name)
                   (error "el2org: No emacs-lisp file is found.")))
         (readme-file (concat (file-name-directory file) "README.md")))
    (el2org-generate-file
     file '("README")
     (if (featurep 'ox-gfm)
         'gfm
       (message "Can't generate README.md with ox-gfm, use ox-md instead!")
       'md)
     readme-file t)
    (write-region
     (format "\n\n\nConverted from %s by [el2org](https://github.com/tumashu/el2org) ."
             (file-name-nondirectory file))
     nil readme-file 'append)))

;;;###autoload
(defun el2org-generate-html ()
  "Generate html file from current elisp file and browse it."
  (interactive)
  (let* ((file (or (buffer-file-name)
                   (error "el2org: No emacs-lisp file is found.")))
         (html-file (concat (file-name-sans-extension file) "_el2org.html"))
         (tags (when (yes-or-no-p "Convert README tag only? ")
                 '("README"))))
    (el2org-generate-file file tags 'html html-file t)
    (browse-url html-file)))

;;;###autoload
(defun el2org-generate-org ()
  "Generate org file from current elisp file."
  (interactive)
  (let* ((file (or (buffer-file-name)
                   (error "el2org: No emacs-lisp file is found.")))
         (org-file (concat (file-name-sans-extension file) ".org")))
    (el2org-generate-file file nil 'org org-file t t)))

(provide 'el2org)

;; * Footer

;; Local Variables:
;; coding: utf-8-unix
;; End:

;;; el2org.el ends here
