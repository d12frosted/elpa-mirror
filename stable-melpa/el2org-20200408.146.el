;;; el2org.el --- Convert elisp file to org file   -*- lexical-binding: t; -*-

;; * Header
;; #+begin_example
;; Copyright (C) 2017-2019 Feng Shu

;; Author: Feng Shu  <tumashu@163.com>
;; Homepage: https://github.com/tumashu/el2org
;; Keywords: convenience
;; Package-Version: 20200408.146
;; Package-Commit: 7db77fdd73f378d4e60e34c11bbdf00677adc32c
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
;; #+end_example

;;; Commentary:

;; * What is el2org                                      :README:
;; el2org is a simple tool, which can convert a emacs-lisp file to org file.
;; You can write code and document in a elisp file with its help.

;; #+begin_example
;;            (convert to)                    (export to)
;; elisp  -----------------> org (internal) --------------> other formats
;; #+end_example

;; Note: el2org.el file may be a good example.

;; [[./snapshots/el2org.gif]]

;; ** Installation

;; 1. Config melpa source, please read: [[http://melpa.org/#/getting-started]]
;; 2. M-x package-install RET el2org RET
;; 3. M-x package-install RET ox-gfm RET

;;    ox-gfm is needed by `el2org-generate-readme', if ox-gfm can not be found,
;;    ox-md will be used as fallback.

;; ** Configure

;; #+begin_src emacs-lisp
;; (require 'el2org)
;; (require 'ox-gfm)
;; #+end_src

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
(require 'ox-md)

(defgroup el2org nil
  "A tool, which can convert a emacs-lisp file to org file"
  :group 'tools
  :prefix "el2org-")

(defcustom el2org-default-backend 'gfm
  "Default backend for README file."
  :group 'el2org
  :type '(choice (const :tag "Org" org)
                 (const :tag "GitHub Markdown" gfm)
                 (const :tag "Org Markdown" md)))

(defcustom el2org-add-notification 'begin
  "Add a notification, which mention el2org as file generator in README."
  :group 'el2org
  :type '(choice (const :tag "Beginning of file" begin)
                 (const :tag "End of file" end)
                 (const :tag "Off" nil)))

(defvar el2org-backend-settings
  `((gfm
     :require ox-gfm
     :fallback md
     :filename-extension "md"
     :notification
     ,(concat "Note: this file is auto converted from %elisp-file by "
              "[el2org](https://github.com/tumashu/el2org), "
              "please do not edit it by hand!!!"))
    (md
     :filename-extension "md"
     :notification
     ,(concat "Note: this file is auto converted from %elisp-file by "
              "[el2org](https://github.com/tumashu/el2org), "
              "please do not edit it by hand!!!"))
    (org
     :filename-extension "org"
     :notification
     ,(concat "Note: this file is auto converted from %elisp-file by "
              "[[https://github.com/tumashu/el2org][el2org]], "
              "please do not edit it by hand!!!")))
  "The settings of el2org backends.")

(defun el2org-in-src-block-p ()
  "If the current point is in BEGIN/end_src block, return t."
  (let ((begin1 (save-excursion
                  (if (re-search-backward ";; #[+]begin_src emacs-lisp" nil t)
                      (point)
                    (point-min))))
        (begin2 (save-excursion
                  (if (re-search-backward ";; #[+]end_src" nil t)
                      (point)
                    (point-min))))
        (end1 (save-excursion
                (if (re-search-forward "\n;; #[+]begin_src emacs-lisp" nil t)
                    (point)
                  (point-max))))
        (end2 (save-excursion
                (if (re-search-forward "\n;; #[+]end_src" nil t)
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
      (let ((case-fold-search t)
            (buffer-end-of-newline-p
             (save-excursion (goto-char (point-max))
                             (forward-line 0)
                             (if (string-match
                                  "^$"
                                  (buffer-substring-no-properties (point) (point-max)))
                                 t
                               nil))))
        ;; Protect existing "begin_src emacs-lisp"
        (goto-char (point-min))
        (while (re-search-forward "#[+]begin_src[ ]+emacs-lisp" nil t)
          (replace-match "&&&el2org-begin-src-emacs-lisp&&&" nil t))
        ;; Protect existing "#+end_src"
        (goto-char (point-min))
        (while (re-search-forward "#[+]end_src" nil t)
          (replace-match "&&&el2org-end-src&&&" nil t))
        ;; Add "#+end_src"
        (goto-char (point-min))
        (let ((status t))
          (while status
            (thing-at-point--end-of-sexp)
            (end-of-line)
            (if (< (point) (point-max))
                (insert "\n;; #+end_src")
              (setq status nil)
              (unless buffer-end-of-newline-p
                (insert "\n;; #+end_src")))))
        ;; Add "#+begin_src"
        (goto-char (point-max))
        (let ((status t))
          (while status
            (thing-at-point--beginning-of-sexp)
            (if (> (point) (point-min))
                (insert ";; #+begin_src emacs-lisp\n")
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
              (insert "&&&el2org;;;&&&")
              (goto-char (line-beginning-position))))
          (forward-line))
        ;; Deal with ";; Local Variables:" and ";; End:"
        (goto-char (point-min))
        (while (re-search-forward "^;;+[ ]+Local[ ]+Variables: *" nil t)
          (replace-match ";; #+begin_example\n;; Local Variables:" nil t))
        (goto-char (point-min))
        (while (re-search-forward "^;;+[ ]+End: *" nil t)
          (replace-match ";; End:\n;; #+end_example" nil t))
        ;; Deal with ";;;"
        (goto-char (point-min))
        (while (re-search-forward "^;;;" nil t)
          (replace-match "# ;;;" nil t))
        ;; Un-protect existing "begin_src emacs-lisp"
        (goto-char (point-min))
        (while (re-search-forward "&&&el2org-begin-src-emacs-lisp&&&" nil t)
          (replace-match "#+begin_src emacs-lisp" nil t))
        ;; Un-Protect existing "#+end_src"
        (goto-char (point-min))
        (while (re-search-forward "&&&el2org-end-src&&&" nil t)
          (replace-match "#+end_src" nil t))
        ;; Deal with ";;"
        (goto-char (point-min))
        (while (re-search-forward "^;;[ ]?" nil t)
          (replace-match "" nil t)
          (goto-char (line-end-position)))
        ;; Delete useless "begin_src/end_src"
        (goto-char (point-min))
        (while (re-search-forward "^#[+]begin_src[ ]+emacs-lisp\n+#[+]end_src\n*" nil t)
          (replace-match "" nil t))
        (goto-char (point-min))
        (while (re-search-forward "^#[+]end_src\n#[+]begin_src[ ]+emacs-lisp\n" nil t)
          (replace-match "" nil t))
        ;; Remove protect-mark.
        (goto-char (point-min))
        (while (re-search-forward "^&&&el2org;;;&&&" nil t)
          (replace-match "" nil t)))
      ;; Export
      (org-mode)
      (let ((org-export-select-tags tags)
            (org-export-with-tags with-tags)
            (indent-tabs-mode nil)
            (tab-width 4))
        (org-export-to-file backend output-file))
      output-file)))

(defun el2org--get-valid-backend (backend)
  (let* ((setting (cdr (assq backend el2org-backend-settings)))
         (feature (plist-get setting :require))
         (fallback (plist-get setting :fallback)))
    (if (or (not feature)
            (and feature (featurep feature)))
        backend
      (message "el2org: backend '%s' is invalid, fallback to '%s'." backend fallback)
      fallback)))

;;;###autoload
(defun el2org-generate-readme (&optional backend file-ext)
  "Generate README from current emacs-lisp file.

If BACKEND is set then use-it else use `el2org-default-backend'.
If FILE-EXT is nil deduce it from BACKEND."
  (interactive)
  (let* ((backend (el2org--get-valid-backend
                   (or backend el2org-default-backend)))
         (file-ext
          (or file-ext
              (plist-get (cdr (assq backend el2org-backend-settings))
                         :filename-extension)))
         (el-file (or (buffer-file-name)
                      (error "el2org: No emacs-lisp file is found.")))
         (readme-file (concat (file-name-directory el-file) "README" "." file-ext))
         (notification (replace-regexp-in-string
                        "%elisp-file"
                        (file-name-nondirectory el-file)
                        (or (plist-get (cdr (assq 'md el2org-backend-settings))
                                       :notification)
                            ""))))
    (el2org-generate-file el-file '("README") backend readme-file t)
    (when el2org-add-notification
      (with-temp-buffer
        (insert-file-contents readme-file)
        (if (eq el2org-add-notification 'end)
            (progn (goto-char (point-max))
                   (insert "\n\n")
                   (insert notification))
          (goto-char (point-min))
          (insert notification)
          (insert "\n\n"))
        (write-file readme-file)))))

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
