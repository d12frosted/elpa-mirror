;;; ob-napkin.el --- Babel functions for Napkin -*- lexical-binding: t -*-

;; Copyright (C) Hans Jang

;; Author: Hans Jang
;; Keywords: tools, literate programming, reproducible research, napkin, plantuml
;; Package-Version: 20200817.1259
;; Package-Commit: 7af5e8af08da8455c489909afbd9528a61f570e7
;; Homepage: https://github.com/pinetr2e/ob-napkin
;; Version: 0.9
;; Package-Requires: ((emacs "26.1"))

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Org-Babel support for evaluating Napkin script, a Python based DSL to write
;; sequence diagrams.

;;; Requirements:

;;
;; pip install napkin plantuml
;;
;; See https://github.com/pinetr2e/napkin

;;; Code:
(require 'ob)

(defcustom org-babel-napkin-command "napkin"
  "Name of the command for running napkin tool command line."
  :group 'org-babel
  :type 'string)

(defcustom org-babel-napkin-plantuml-server-url ""
  "Server URL to use in generating image file.
The empty string means to use the public server."
  :group 'org-babel
  :type 'string)

(defvar org-babel-default-header-args:napkin
  '((:results . "file") (:exports . "results"))
  "Default arguments for evaluating a napkin src block.")

(defvar org-babel-default-header-args:napkin-puml
  '((:results . "file") (:exports . "results"))
  "Default arguments for evaluating a napkin-puml src block.")

(defun org-babel-napkin-out-file (params)
  "Return output file name from PARAMS."
  (or (cdr (assq :file params))
      (error "Napkin src block requires :file header argument")))

(defun org-babel-expand-body:napkin (body params)
  "Prpend import/decorator with file name coming from PARAMS with BODY."
  (let ((out-file (org-babel-napkin-out-file params)))
    (if (string-match (rx buffer-start (0+ blank) "def" (1+ blank) "seq_diagram" (0+ blank) "(") body)
        (concat "import napkin\n"
                (format "@napkin.seq_diagram('%s')\n" (file-name-base (org-babel-process-file-name out-file)))
                body)
      (error "Napkin src block requires def seq_diagram() as the first line of the contents"))))

;;;###autoload
(defun org-babel-execute:napkin (body params)
  "Execute a block of napkin code with BODY and PARAMS with Babel.
napkin tool will be invoked to generate the image."
  (let* ((out-file (org-babel-napkin-out-file params))
         (img-type (file-name-extension out-file))
         (in-file (org-babel-temp-file "napkin-" ".py"))
         (expanded-body (org-babel-expand-body:napkin body params))
         (server-url org-babel-napkin-plantuml-server-url)
         (tool-path org-babel-napkin-command)
         (command (format "%s %s -o %s -f %s %s"
                          tool-path
                          (org-babel-process-file-name in-file)
                          (file-name-directory (org-babel-process-file-name out-file))
                          (concat "plantuml_" img-type)
                          (if (string-equal server-url "") "" (concat "--server-url " server-url)))))
    (with-temp-file in-file (insert expanded-body))
    (message "%s" command)
    (org-babel-eval command "")
    nil)) ;; signal that output has already been written to file


(defun org-babel-expand-body:napkin-puml (body _params)
  "Wrap BODY if it does not include @startuml. PARAMS are unused."
  (if (string-match (rx buffer-start (0+ blank) "@startuml") body)
      body
    (concat "@startuml\n" body "@enduml")))

;;;###autoload
(defun org-babel-execute:napkin-puml (body params)
  "Execute a block of plantuml code with BODY and PARAMS with Babel.
napkin_plantuml tool will be invoked to generate the image."
  (let* ((out-file (org-babel-napkin-out-file params))
         (in-file (org-babel-temp-file "napkin-" ".puml"))
         (expanded-body (org-babel-expand-body:napkin-puml body params))
         (server-url org-babel-napkin-plantuml-server-url)
         (tool-path (concat org-babel-napkin-command "_plantuml"))
         (command (format "%s %s %s %s"
                          tool-path
                          (org-babel-process-file-name in-file)
                          (org-babel-process-file-name out-file)
                          (if (string-equal server-url "") "" (concat "--server-url " server-url)))))
    (with-temp-file in-file (insert expanded-body))
    (message "%s" command)
    (org-babel-eval command "")
    nil)) ;; signal that output has already been written to file


(defun ob-napkin-unload-function ()
  "Pre-cleanup when `unload-feature' is called."
  (setq org-src-lang-modes
        (remove '("napkin" . python)
                (remove '("napkin-puml" . planuml)
                        org-src-lang-modes)))
  ;; return nil to continue standard unloading:
  nil)

(add-to-list 'org-src-lang-modes '("napkin" . python))
(when (featurep 'plantuml-mode)
  (add-to-list 'org-src-lang-modes '("napkin-puml" . plantuml)))

(provide 'ob-napkin)

;;; ob-napkin.el ends here
