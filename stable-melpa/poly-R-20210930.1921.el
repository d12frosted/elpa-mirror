;;; poly-R.el --- Various polymodes for R language -*- lexical-binding: t -*-
;;
;; Author: Vitalie Spinu
;; Maintainer: Vitalie Spinu
;; Copyright (C) 2013-2018 Vitalie Spinu
;; Version: 0.2.2
;; Package-Version: 20210930.1921
;; Package-Commit: e4a39caaf48e1c2e5afab3865644267b10610537
;; Package-Requires: ((emacs "25") (polymode "0.2.2") (poly-markdown "0.2.2") (poly-noweb "0.2.2"))
;; URL: https://github.com/polymode/poly-R
;; Keywords: languages, multi-modes
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file is *NOT* part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'polymode)
(require 'ess-mode)
(require 'ess-r-mode nil t)

(defgroup poly-R nil
  "Settings for poly-R polymodes"
  :group 'polymode)

(defcustom poly-r-root-polymode
  (pm-polymode :name "R"
               :hostmode 'pm-host/R
               :innermodes '(pm-inner/fundamental))
  "Root polymode with R host intended to be inherited from."
  :group 'poly-R
  :type 'object)


;; NOWEB
(require 'poly-noweb)

(define-obsolete-variable-alias 'pm-inner/noweb-R 'poly-r-noweb-innermode "v0.2")
(define-innermode poly-r-noweb-innermode poly-noweb-innermode
  :mode 'R-mode)

;;;###autoload
(define-obsolete-function-alias 'poly-noweb+R-mode 'poly-noweb+r-mode "v0.2")
;;;###autoload
(define-obsolete-variable-alias 'pm-poly/noweb+R 'poly-noweb+r-polymode "v0.2")
;;;###autoload (autoload 'poly-noweb+r-mode "poly-R")
(define-polymode poly-noweb+r-mode poly-noweb-mode
  :lighter " PM-Rnw"
  :innermodes '(poly-r-noweb-innermode))


;; MARKDOWN
(require 'poly-markdown)

(defcustom poly-r-rmarkdown-template-dirs nil
  "Directories containing RMarkdown templates.
Templates are either folders in rmarkdown template format or
simple Rmd files. First level nesting is allowed in the sense
that each sub-directory of these directories can itself contain
templates."
  :type '(repeat string)
  :group 'poly-R)

(define-innermode poly-r-markdown-inline-code-innermode poly-markdown-inline-code-innermode
  :mode 'ess-r-mode
  :head-matcher (cons "[^`]\\(`{?[rR]}?\\)[ \t]" 1))

(define-obsolete-variable-alias 'pm-poly/markdown+R 'poly-markdown+r-polymode "v0.2")
(define-obsolete-variable-alias 'pm-poly/markdown+r 'poly-markdown+r-polymode "v0.2")
;;;###autoload
(define-obsolete-function-alias 'poly-markdown+R-mode 'poly-markdown+r-mode "v0.2")
(define-obsolete-variable-alias 'poly-markdown+R-mode 'poly-markdown+r-mode "v0.2")
;;;###autoload
(define-obsolete-variable-alias 'poly-markdown+R-mode-map 'poly-markdown+r-mode-map "v0.2")
;;;###autoload (autoload 'poly-markdown+r-mode "poly-R")
(define-polymode poly-markdown+r-mode poly-markdown-mode :lighter " PM-Rmd"
  :innermodes '(:inherit poly-r-markdown-inline-code-innermode))
;;;###autoload (autoload 'poly-gfm+r-mode "poly-R")
(define-polymode poly-gfm+r-mode poly-markdown+r-mode 
  :lighter " PM-Rmd(gfm)"
  :hostmode 'poly-gfm-hostmode)

(defvar poly-r--rmarkdown-template-command
  "
local({
list_templates <-
 function(user_dirs) {
    user_dirs <- c(user_dirs, unlist(lapply(user_dirs, list.dirs, recursive = FALSE)))
    list_from_dir <- function(dir, pkg = NULL) {
      pkg_name <- if(is.null(pkg)) 'USER' else pkg
      if (dir.exists(dir)) {
        dirs <- list.dirs(dir, recursive = FALSE)
        for (d in dirs) {
          yaml_file <- file.path(d, 'template.yaml')
          if (file.exists(yaml_file)) {
            yaml <- yaml::yaml.load(readLines(yaml_file, encoding = 'UTF-8'))
            if (is.null(desc <- yaml$description)) desc <- 'nil'
            if (!is.null(pkg)) d <- basename(d)
            cat(sprintf('(\"%%s\" \"%%s\" \"%%s\" \"%%s\")\n', pkg_name, d, yaml$name, desc))
          }
        }
      }
    }
    cat('(\n')
    for (user_dir in user_dirs) {
      files <- list.files(user_dir,  '\\\\.[Rr]md$', full.names = TRUE)
      for (f in files) {
        name <- sub('\\\\.[^.]+$','', basename(f))
        cat(sprintf('(\"USER\" \"%%s\" \"%%s\")\n', f, name))
      }
      list_from_dir(user_dir)
    }
    packages <- sort(unlist(lapply(.libPaths(), dir)))
    for (pkg in packages) {
      template_folder <- system.file('rmarkdown', 'templates', package = pkg)
      list_from_dir(template_folder, pkg)
    }
    cat(')\n')
  }\n
 list_templates(%s)})\n")

(defun poly-r-rmarkdown-templates (&optional proc)
  (let* ((ess-dialect "R")
         (proc (or proc (ess-get-next-available-process "R" t)))
         (user-dirs (if poly-r-rmarkdown-template-dirs
                        (format "c(\"%s\")"
                                (mapconcat #'identity
                                           poly-r-rmarkdown-template-dirs
                                           "\", \""))
                      "c()"))
         (cmd (format poly-r--rmarkdown-template-command user-dirs)))
    (with-current-buffer (ess-command cmd nil nil nil nil proc)
      (goto-char (point-min))
      (if (save-excursion (re-search-forward "\\+ Error" nil t))
          (error "%s" (buffer-string))
        (when (re-search-forward "(" nil t)
          (backward-char)
          (read (current-buffer)))))))

(defun poly-r-rmarkdown-templates-menu (&optional _items)
  (let* ((proc (ess-get-next-available-process "R" t))
         (templates (process-get proc :rmarkdown-templates)))
    (unless templates
      (setq templates (poly-r-rmarkdown-templates proc))
      (when (< 2000 (length templates))
        (process-put proc :rmarkdown-templates templates)))
    (mapcar (lambda (el)
              (cons (car el) (mapcar (lambda (tlate)
                                       (vector (nth 2 tlate)
                                               `(poly-r--rmarkdown-draft ,(nth 0 tlate) ,(nth 1 tlate))
                                               :help (nth 3 tlate)))
                                     (cdr el))))
            (seq-group-by #'car templates))))

(defun poly-r--rmarkdown-draft (pkg template)
  (let* ((ess-dialect "R")
         (file (read-file-name "Draft name: "))
         (pkg (if (string= pkg "USER") "NULL" (format "\"%s\"" pkg)))
         (cmd (format "rmarkdown::draft('%s', '%s', package = %s, edit = FALSE)" file template pkg)))
    (if (and (string= pkg "NULL")
             (file-exists-p template)
             (not (file-directory-p template)))
        (copy-file template file t)
      (when (file-exists-p file)
        (if (y-or-n-p (format "File '%s' already exists.  Overwrite? " file))
            (delete-file file)
          (signal 'quit t)))
      (ess-eval-linewise cmd)
      (sit-for 0.05)
      (let ((output (car (ess-get-words-from-vector "print(.Last.value)\n"))))
        (when output
          (setq file output))))
    (if (file-exists-p file)
        (find-file-other-window file)
      (error "No file '%s' created" file))))

(defvar poly-r--rmarkdown-create-from-template-hist nil)
(defun poly-r-rmarkdown-create-from-template ()
  "Create new Rmarkdown project from template.
  Templates are provided by R packages in the format described in
  the help of 'draft' function and chapter 17 of the RMarkdown
  book. This function also searches for templates in
  `poly-r-rmarkdown-template-dirs' directories. Templates in those
  directories are either simple Rmd files or template directories
  with template.yaml metadata as enforced by rmarkdwon template
  format.

  Common packages containing templates are rticles, tufte,
  xaringan, prettydoc, revealjs, flexdashboards.  Some more
  templates at:

  https://github.com/mikey-harper/example-rmd-templates
  https://github.com/hrbrmstr/markdowntemplates
  https://github.com/svmiller/svm-r-markdown-templates"
  (interactive)
  (let* ((specs (poly-r-rmarkdown-templates))
         (spec (cdr (pm--completing-read "Template: "
                                         (mapcar (lambda (el) (cons (format "%s/%s" (car el) (nth 2 el)) el))
                                                 specs)
                                         nil t nil 'poly-r--rmarkdown-create-from-template-hist))))
    (poly-r--rmarkdown-draft (car spec) (cadr spec))))

(easy-menu-define poly-markdown+R-menu (list ess-mode-map
                                             inferior-ess-mode-map
                                             poly-markdown+r-mode-map)
  "Menu for poly-r+markdown-mode"
  '("RMarkdown"
    ("Templates"
     :active (ess-get-next-available-process "R" t)
     :filter poly-r-rmarkdown-templates-menu)))

(define-key poly-markdown+r-mode-map (kbd "M-n M-m") #'poly-r-rmarkdown-create-from-template)


;; RAPPORT
(define-obsolete-variable-alias 'pm-inner/rapport-YAML 'poly-rapport-yaml-innermode "v0.2")
(define-innermode poly-rapport-yaml-innermode
  :mode 'yaml-mode
  :head-matcher "<!--head"
  :tail-matcher "head-->")

;;;###autoload (autoload 'poly-rapport-mode "poly-R")
(define-polymode poly-rapport-mode poly-markdown+r-mode
  :innermodes '(:inherit
                poly-r-brew-innermode
                poly-rapport-yaml-innermode))


;; HTML
(define-obsolete-variable-alias 'pm-inner/html-R 'poly-r-for-html-innermode "v0.2")
(define-innermode poly-r-for-html-innermode
  :mode 'R-mode
  :head-matcher "<!--[ \t]*begin.rcode"
  :tail-matcher "end.rcode[ \t]*-->")

;;;###autoload
(define-obsolete-function-alias 'poly-html+R-mode 'poly-html+r-mode "v0.2")

;;;###autoload (autoload 'poly-html+r-mode "poly-R")
(define-polymode poly-html+r-mode poly-html-root-polymode
  :innermodes '(poly-r-for-html-innermode))


;;; R-brew
(define-obsolete-variable-alias 'pm-inner/brew-R 'poly-r-for-brew-innermode "v0.2")
(define-innermode poly-r-for-brew-innermode
  :mode 'R-mode
  :head-matcher "<%[=%]?"
  :tail-matcher "[#=%=-]?%>")

;;;###autoload
(define-obsolete-function-alias 'poly-brew+R-mode 'poly-brew+r-mode "v0.2")
;;;###autoload (autoload 'poly-brew+r-mode "poly-R")
(define-polymode poly-brew+r-mode poly-brew-root-polymode
  :innermodes '(poly-r-for-brew-innermode))


;;; R+C++
;; todo: move into :matcher-subexp functionality?
(defun pm--r-cppFunction-head-matcher (ahead)
  (when (re-search-forward "cppFunction(\\(['\"]\n\\)"
                           nil t ahead)
    (cons (match-beginning 1) (match-end 1))))

(defun pm--r-cppFunction-tail-matcher (ahead)
  (when (< ahead 0)
    (goto-char (car (pm--r-cppFunction-head-matcher -1))))
  (goto-char (max 1 (1- (point))))
  (let ((end (or (ignore-errors (scan-sexps (point) 1))
                 (buffer-end 1))))
    (cons (max 1 (1- end)) end)))

(define-obsolete-variable-alias 'pm-inner/R-C++ 'poly-r-cppFunction-innermode "v0.2")
(define-innermode poly-r-cppFunction-innermode
  :mode 'c++-mode
  :head-mode 'host
  :head-matcher 'pm--r-cppFunction-head-matcher
  :tail-matcher 'pm--r-cppFunction-tail-matcher
  :protect-font-lock nil)

;;;###autoload
(define-obsolete-function-alias 'poly-R+C++-mode 'poly-r+c++-mode "v0.2")
;;;###autoload (autoload 'poly-r+c++-mode "poly-R")
(define-polymode poly-r+c++-mode poly-r-root-polymode
  :innermodes '(poly-r-cppFunction-innermode))


;;; C++R
(defun pm--c++r-head-matcher (ahead)
  (when (re-search-forward "^[ \t]*/[*]+[ \t]*R" nil t ahead)
    (cons (match-beginning 0) (match-end 0))))

(defun pm--c++r-tail-matcher (ahead)
  (when (< ahead 0)
    (error "Backwards tail match not implemented"))
  ;; may be rely on syntactic lookup ?
  (when (re-search-forward "^[ \t]*\\*/")
    (cons (match-beginning 0) (match-end 0))))

(define-obsolete-variable-alias 'pm-inner/C++R 'poly-r-for-c++-innermode "v0.2")
(define-innermode poly-r-for-c++-innermode
  :mode 'R-mode
  :head-matcher 'pm--c++r-head-matcher
  :tail-matcher 'pm--c++r-tail-matcher)

;;;###autoload
(define-obsolete-function-alias 'poly-C++R-mode 'poly-c++r-mode "v0.2")
;;;###autoload (autoload 'poly-c++r-mode "poly-R")
(define-polymode poly-c++r-mode poly-c++-root-polymode
  :innermodes '(poly-r-for-c++-innermode))


;;; R help
(define-innermode poly-r-help-usage-innermode
  :mode 'ess-r-mode
  :head-matcher "^Usage:\n"
  :tail-matcher "^[^ \t]+:"
  :keep-in-mode 'host
  :head-mode 'host
  :tail-mode 'host)

(define-obsolete-variable-alias 'pm-inner/ess-help-R 'poly-ess-help-R-innermode "v0.2")
(define-innermode poly-r-help-examples-innermode
  :mode 'ess-r-mode
  :head-matcher "^Examples:\n"
  :tail-matcher "\\'"
  :indent-offset 5
  :head-mode 'host)

;;;###autoload (autoload 'poly-r-help-examples-mode "poly-R")
(define-polymode poly-r-help-examples-mode
  :innermodes '(poly-r-help-usage-innermode
                poly-r-help-examples-innermode)
  ;; don't transfer read only status from main help buffer
  (setq-local polymode-move-these-vars-from-old-buffer
              (delq 'buffer-read-only polymode-move-these-vars-from-old-buffer)))

(add-hook 'ess-help-mode-hook (lambda ()
                                (when (string= ess-dialect "R")
                                  (poly-r-help-examples-mode))))


;; Rd examples
(defun pm--rd-head-matcher (ahead)
  (when (re-search-forward "\\\\\\(examples\\|usage\\) *\\({\n\\)" nil t ahead)
    (cons (match-beginning 0) (match-end 0))))

(defun pm--rd-tail-matcher (ahead)
  (when (< ahead 0)
    (goto-char (cdr (pm--rd-head-matcher -1))))
  (let ((end (or (ignore-errors
                   (skip-chars-backward " \t\n{")
                   (scan-sexps (point) 1))
                 (buffer-end 1))))
    (cons (max 1 (- end 1)) end)))

(define-obsolete-variable-alias 'pm-inner/Rd-examples 'poly-rd-examples-innermode "v0.2")
(define-innermode poly-rd-examples-innermode
  :mode 'R-mode
  :head-mode 'host
  :head-matcher 'pm--rd-head-matcher
  :tail-matcher 'pm--rd-tail-matcher)

(define-hostmode poly-rd-hostmode :mode 'Rd-mode)

;;;###autoload (autoload 'poly-rd-mode "poly-R")
(define-polymode poly-rd-mode
  :hostmode 'poly-rd-hostmode
  :innermodes '(poly-rd-examples-innermode))

(add-hook 'Rd-mode-hook 'poly-rd-mode)


;; Rmarkdown

(defun pm--rmarkdown-output-file-sniffer ()
  (goto-char (point-min))
  (let (files)
    (while (re-search-forward "Output created: +\\(.*\\)" nil t)
      (push (expand-file-name (match-string 1)) files))
    (reverse (delete-dups files))))

(defun pm--rmarkdown-output-file-from-.Last.value ()
  (ess-get-words-from-vector "print(.Last.value)\n"))

(defun pm--rmarkdown-shell-auto-selector (action &rest _ignore)
  (cl-case action
    (doc "AUTO DETECT")
    (command "Rscript -e \"rmarkdown::render('%i', output_format = 'all')\"")
    (output-file #'pm--rmarkdown-output-file-sniffer)))

(defun pm--rmarkdown-shell-default-selector (action &rest _ignore)
  (cl-case action
    (doc "DEFAULT")
    (command "Rscript -e \"rmarkdown::render('%i', output_format = NULL)\"")
    (output-file #'pm--rmarkdown-output-file-sniffer)))

(define-obsolete-variable-alias 'pm-exporter/Rmarkdown 'poly-r-markdown-exporter "v0.2")
(defcustom poly-r-markdown-exporter
  (pm-shell-exporter :name "Rmarkdown"
                     :from
                     '(("Rmarkdown"  "\\.[rR]?md\\|rapport\\'" "R Markdown"
                        "Rscript -e \"rmarkdown::render('%i', output_format = '%t', output_file = '%o')\""))
                     :to
                     '(("auto" . pm--rmarkdown-shell-auto-selector)
                       ("default" . pm--rmarkdown-shell-default-selector)
                       ("html" "html" "html document" "html_document")
                       ("pdf" "pdf" "pdf document" "pdf_document")
                       ("word" "docx" "word document" "word_document")
                       ("md" "md" "md document" "md_document")
                       ("ioslides" "html" "ioslides presentation" "ioslides_presentation")
                       ("slidy" "html" "slidy presentation" "slidy_presentation")
                       ("beamer" "pdf" "beamer presentation" "beamer_presentation")))
  "R Markdown exporter.
  Please not that with 'AUTO DETECT' export options, output file
  names are inferred by Rmarkdown from YAML description
  block. Thus, output file names don't comply with
  `polymode-exporter-output-file-format'."
  :group 'polymode-export
  :type 'object)

(defun pm--rmarkdown-callback-auto-selector (action &rest _ignore)
  (cl-case action
    (doc "AUTO DETECT")
    ;; last file is not auto-detected unless we cat new line
    (command "rmarkdown::render('%I', output_format = 'all', knit_root_dir=getwd())")
    (output-file #'pm--rmarkdown-output-file-from-.Last.value)))

(defun pm--rmarkdown-callback-default-selector (action &rest _ignore)
  (cl-case action
    (doc "DEFAULT")
    ;; last file is not auto-detected unless we cat new line
    (command "rmarkdown::render('%I', output_format = NULL, knit_root_dir=getwd())")
    (output-file #'pm--rmarkdown-output-file-from-.Last.value)))


(define-obsolete-variable-alias 'pm-exporter/Rmarkdown-ESS 'poly-r-markdown-ess-exporter "v0.2")
(defcustom poly-r-markdown-ess-exporter
  (pm-callback-exporter :name "Rmarkdown-ESS"
                        :from
                        '(("Rmarkdown" "\\.[rR]?md\\|rapport\\'" "R Markdown"
                           "rmarkdown::render('%I', output_format = '%t', output_file = '%O', knit_root_dir=getwd())\n"))
                        :to
                        '(("auto" . pm--rmarkdown-callback-auto-selector)
                          ("html" "html" "html document" "html_document")
                          ("pdf" "pdf" "pdf document" "pdf_document")
                          ("default" . pm--rmarkdown-callback-default-selector)
                          ("word" "docx" "word document" "word_document")
                          ("md" "md" "md document" "md_document")
                          ("ioslides" "html" "ioslides presentation" "ioslides_presentation")
                          ("slidy" "html" "slidy presentation" "slidy_presentation")
                          ("beamer" "pdf" "beamer presentation" "beamer_presentation"))
                        :function 'pm--ess-run-command
                        :callback 'pm--ess-callback)
  "R Markdown exporter.
  Please not that with 'AUTO DETECT' export options, output file
  names are inferred by Rmarkdown from YAML description
  block. Thus, output file names don't comply with
  `polymode-exporter-output-file-format'."
  :group 'polymode-export
  :type 'object)

(polymode-register-exporter poly-r-markdown-ess-exporter nil
                            poly-markdown+r-polymode)
(polymode-register-exporter poly-r-markdown-exporter nil
                            poly-markdown+r-polymode)


;;; Bookdown

(defun pm--rbookdown-input-book-selector (action &rest _ignore)
  (cl-case action
    (doc "R Bookdown Book")
    (match (file-exists-p "_bookdown.yml"))
    (command "bookdown::render_book('%I', output_format = '%t')\n")))

(defun pm--rbookdown-intput-chapter-selector (action &rest _ignore)
  (cl-case action
    (doc "R Bookdown Chapter")
    (match (file-exists-p "_bookdown.yml"))
    (command "bookdown::preview_chapter('%I', output_format = '%t')\n")))

(defun pm--rbookdown-output-selector (action id &rest _ignore)
  (cl-case action
    (doc id)
    (output-file #'pm--rmarkdown-output-file-from-.Last.value)
    (t-spec (format "bookdown::%s" id))))

(define-obsolete-variable-alias 'pm-exporter/Rbookdown-ESS 'poly-r-bookdown-ess-exporter "v0.2")
(defcustom poly-r-bookdown-ess-exporter
  (pm-callback-exporter :name "Rbookdown-ESS"
                        :from
                        '(("Book" . pm--rbookdown-input-book-selector)
                          ("Chapter" . pm--rbookdown-intput-chapter-selector))
                        :to
                        '(("ALL" nil "ALL-CONFIGURED" "all")
                          ("epub_book" . pm--rbookdown-output-selector)
                          ("gitbook" . pm--rbookdown-output-selector)
                          ("html_book" . pm--rbookdown-output-selector)
                          ("html_document2" . pm--rbookdown-output-selector)
                          ("pdf_book" . pm--rbookdown-output-selector)
                          ("pdf_document2" . pm--rbookdown-output-selector)
                          ("tufte_book2" . pm--rbookdown-output-selector)
                          ("tufte_handout2" . pm--rbookdown-output-selector)
                          ("tufte_html2" . pm--rbookdown-output-selector)
                          ("tufte_html_book" . pm--rbookdown-output-selector)
                          ("word_document2" . pm--rbookdown-output-selector))
                        :function 'pm--ess-run-command
                        :callback 'pm--ess-callback)
  "R bookdown exporter within ESS process."
  :group 'polymode-export
  :type 'object)

(polymode-register-exporter poly-r-bookdown-ess-exporter nil poly-markdown+r-polymode)


;; Shiny Rmd

(defun pm--shiny-input-selector (action &optional id &rest _ignore)
  (cl-case action
    (doc "Shiny Rmd Application")
    (match (save-excursion
             (goto-char (point-min))
             (re-search-forward "^[ \t]*runtime:[ \t]+shiny[ \t]*$" nil t)))
    (command (if (equal id "Rmd-ESS")
                 "rmarkdown::run('%I')\n"
               "Rscript -e \"rmarkdown::run('%I')\""))))

(define-obsolete-variable-alias 'pm-exporter/Shiny 'poly-r-shiny-exporter "v0.2")
(defcustom poly-r-shiny-exporter
  (pm-shell-exporter :name "Shiny"
                     :from
                     '(("Rmd" . pm--shiny-input-selector))
                     :to
                     '(("html" "html" "Shiny Web App")))
  "Shiny exporter of Rmd documents in stand alone shell.
  The Rmd yaml preamble must contain runtime: shiny declaration."
  :group 'polymode-export
  :type 'object)

(define-obsolete-variable-alias 'pm-exporter/Shiny-ESS 'poly-r-shiny-ess-exporter "v0.2")
(defcustom poly-r-shiny-ess-exporter
  (pm-callback-exporter :name "Shiny-ESS"
                        :from
                        '(("Rmd-ESS" . pm--shiny-input-selector))
                        :to
                        '(("html" "html" "Shiny Web App"))
                        :function 'pm--ess-run-command)
  "Shiny exporter of Rmd documents within ESS process.
  The Rmd yaml preamble must contain runtime: shiny declaration."
  :group 'polymode-export
  :type 'object)

(polymode-register-exporter poly-r-shiny-exporter nil poly-markdown+r-polymode)
(polymode-register-exporter poly-r-shiny-ess-exporter nil poly-markdown+r-polymode)


;; KnitR
(define-obsolete-variable-alias 'pm-weaver/knitR 'poly-r-knitr-weaver "v0.2")
(defcustom poly-r-knitr-weaver
  (pm-shell-weaver :name "knitr"
                   :from-to
                   '(("latex" "\\.\\(r?tex\\|rnw\\)\\'" "tex" "LaTeX" "Rscript -e \"knitr::knit('%i', output='%o')\"")
                     ("html" "\\.r?x?html?\\'" "html" "HTML" "Rscript -e \"knitr::knit('%i', output='%o')\"")
                     ("markdown" "\\.[rR]?md\\'" "md" "Markdown" "Rscript -e \"knitr::knit('%i', output='%o')\"")
                     ("rst" "\\.rst" "rst" "ReStructuredText" "Rscript -e \"knitr::knit('%i', output='%o')\"")
                     ("brew" "\\.r?brew\\'" "brew" "Brew" "Rscript -e \"knitr::knit('%i', output='%o')\"")
                     ("asciidoc" "\\.asciidoc\\'" "txt" "AsciiDoc" "Rscript -e \"knitr::knit('%i', output='%o')\"")
                     ("textile" "\\.textile\\'" "textile" "Textile" "Rscript -e \"knitr::knit('%i', output='%o')\"")))
  "Shell knitR weaver."
  :group 'polymode-weave
  :type 'object)

(polymode-register-weaver poly-r-knitr-weaver nil
                          poly-noweb+r-polymode poly-markdown-polymode
                          poly-rapport-polymode poly-html+r-polymode)

(define-obsolete-variable-alias 'pm-weaver/knitR-ESS 'poly-r-knitr-ess-weaver "v0.2")
(defcustom poly-r-knitr-ess-weaver
  (pm-callback-weaver :name "knitR-ESS"
                      :from-to
                      '(("latex" "\\.\\(r?tex\\|rnw\\)\\'" "tex" "LaTeX" "knitr::knit('%I', output='%O')")
                        ("html" "\\.[xX]?html?\\'" "html" "HTML" "knitr::knit('%I', output='%O')")
                        ("markdown" "\\.[rR]?md\\'" "md" "Markdown" "knitr::knit('%I', output='%O')")
                        ("rst" "\\.rst\\'" "rst" "ReStructuredText" "knitr::knit('%I', output='%O')")
                        ("brew" "\\.r?brew]\\'" "brew" "Brew" "knitr::knit('%I', output='%O')")
                        ("asciidoc" "\\.r?asciidoc\\'" "txt" "AsciiDoc" "knitr::knit('%I', output='%O')")
                        ("textile" "\\.textile\\'" "textile" "Textile" "knitr::knit('%I', output='%O')"))
                      :function 'pm--ess-run-command
                      :callback 'pm--ess-callback)
  "ESS knitR weaver."
  :group 'polymode-weave
  :type 'object)

(polymode-register-weaver poly-r-knitr-ess-weaver nil
                          poly-noweb+r-polymode poly-markdown-polymode
                          poly-rapport-polymode poly-html-root-polymode)

(define-obsolete-variable-alias 'pm-weaver/Sweave-ESS 'poly-r-sweave-ess-weaver "v0.2")
(defcustom poly-r-sweave-ess-weaver
  (pm-callback-weaver :name "ESS-Sweave"
                      :from-to '(("latex" "\\.\\(tex\\|r?s?nw\\)\\'" "tex"
                                  "LaTeX" "Sweave('%I', output='%O')"))
                      :function 'pm--ess-run-command
                      :callback 'pm--ess-callback)
  "ESS 'Sweave' weaver."
  :group 'polymode-weave
  :type 'object)

(polymode-register-weaver poly-r-sweave-ess-weaver nil
                          poly-noweb+r-polymode)


;; Sweave
(define-obsolete-variable-alias 'pm-weaver/Sweave 'poly-r-sweave-weaver "v0.2")
(defcustom poly-r-sweave-weaver
  (pm-shell-weaver :name "sweave"
                   :from-to
                   '(("latex" "\\.\\(tex\\|r?s?nw\\)\\'"
                      "tex" "LaTeX" "R CMD Sweave %i --options=\"output='%o'\"")))
  "Shell 'Sweave' weaver."
  :group 'polymode-weave
  :type 'object)

(polymode-register-weaver poly-r-sweave-weaver nil
                          poly-noweb+r-polymode)


;; Setup

(defun poly-r-eval-region (beg end msg)
  (let ((ess-inject-source t))
    (ess-eval-region beg end nil msg)))

(defun poly-r-mode-setup ()
  (when (equal ess-dialect "R")
    (setq-local polymode-eval-region-function #'poly-r-eval-region)))

(add-hook 'ess-mode-hook #'poly-r-mode-setup)


;; ESS command
(declare-function ess-async-command "ess-inf.el")
(declare-function ess-force-buffer-current "ess-inf.el")
(declare-function ess-process-get "ess-inf.el")
(declare-function ess-process-put "ess-inf.el")
(declare-function comint-previous-prompt "comint.el")

(defun pm--ess-callback (proc string)
  (let ((ofile (process-get proc :output-file)))
    ;; This is getting silly. Ess splits output for optimization reasons. So we
    ;; are collecting output from 3 places:
    ;;   - most recent STRING
    ;;   - string in accumulation buffer
    ;;   - string already in output buffer
    (with-current-buffer (if (fboundp 'ess--accumulation-buffer)
                             (ess--accumulation-buffer proc)
                           (process-get proc 'accum-buffer-name))
      (setq string (concat (buffer-string) string)))
    (with-current-buffer (process-buffer proc)
      (setq string (concat (buffer-substring (or ess--tb-last-input (comint-previous-prompt)) (point-max))
                           string)))
    (with-temp-buffer
      (setq ess-dialect "R"
            ess-local-process-name (process-name proc))
      (insert string)
      (when (string-match-p "Error\\(:\\| +in\\)" string)
        (user-error "Errors durring ESS async command"))
      (when (functionp ofile)
        (setq ofile (funcall ofile))))
    ofile))

(defun pm--ess-run-command (command callback &rest _ignore)
  (require 'ess)
  (let ((ess-eval-visibly t)
        (ess-dialect "R"))
    (ess-force-buffer-current)
    (with-current-buffer (ess-get-process-buffer)
      (unless (and (boundp 'goto-address-mode)
                   goto-address-mode)
        ;; mostly for shiny apps (added in ESS 19)
        (goto-address-mode 1)))
    (ess-process-put :output-file pm--output-file)
    (when callback
      (ess-process-put 'callbacks (list callback))
      (ess-process-put 'interruptable? t)
      (ess-process-put 'running-async? t))
    (ess-eval-linewise command)
    (display-buffer (ess-get-process-buffer))))


;; COMPAT
(when (fboundp 'advice-add)
  (advice-add 'ess-eval-paragraph :around 'pm-execute-narrowed-to-span)
  (advice-add 'ess-eval-buffer :around 'pm-execute-narrowed-to-span)
  (advice-add 'ess-beginning-of-function :around 'pm-execute-narrowed-to-span))

(add-to-list 'polymode-move-these-vars-from-old-buffer 'ess-local-process-name)
(add-to-list 'polymode-mode-abbrev-aliases '("ess-r" . "R"))


;;; ASSOCIATIONS

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.Snw\\'" . poly-noweb+r-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.[rR]nw\\'" . poly-noweb+r-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.[rR]md\\'" . poly-markdown+r-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.rapport\\'" . poly-rapport-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.[rR]html\\'" . poly-html+r-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.[rR]brew\\'" . poly-brew+r-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.[Rr]cpp\\'" . poly-r+c++-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.cpp[rR]\\'" . poly-c++r-mode))

(provide 'poly-R)
;;; poly-R.el ends here
