;;; helm-R.el --- helm-sources and some utilities for GNU R.

;; Description: helm-sources and some utilities for GNU R.
;; Author: myuhe <yuhei.maeda_at_gmail.com>
;; Maintainer: myuhe
;; Copyright (C) 2010,2011,2012 myuhe all rights reserved.
;; Created: :2012-05-20
;; Version: 0.0.1
;; Package-Version: 20120820.14
;; Package-Commit: b0eb9d5f6a483a9dbe6eb6cf1f2024d4f5938bc2
;; Keywords: convenience
;; URL: https://github.com/myuhe/helm-R.el
;; Package-Requires: ((helm "20120517")(ess "20120509"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Put the helm-R.el, helm.el and ESS to your
;; load-path.
;; Add to .emacs:
;; (require 'helm-R)
;;

;;; Command:
;;  `helm-for-R'

;;  Anything sources defined :
;; `helm-c-source-R-help'     (manage help function)
;; `helm-c-source-R-local'    (manage object))
;; `helm-c-source-R-localpkg' (manage local packages)
;; `helm-c-source-R-repospkg' (manage repository packages)

;;; Code:
(require 'helm)
(require 'ess-site)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;helm-c-source-R-help
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar helm-c-source-R-help
      '((name . "R objects / help")
        (init . (lambda ()
                  ;; this grabs the process name associated with the buffer
                  (setq helm-c-ess-local-process-name ess-local-process-name)))
        (candidates . (lambda ()
                        (condition-case nil
                            (ess-get-object-list helm-c-ess-local-process-name)
                          (error nil))))
        (action
         ("help" . ess-display-help-on-object)
         ("head (10)" . (lambda(obj-name)
                          (ess-execute (concat "head(" obj-name ", n = 10)\n") nil (concat "R head: " obj-name))))
         ("head (100)" . (lambda(obj-name)
                           (ess-execute (concat "head(" obj-name ", n = 100)\n") nil (concat "R head: " obj-name))))
         ("tail" . (lambda(obj-name)
                     (ess-execute (concat "tail(" obj-name ", n = 10)\n") nil (concat "R tail: " obj-name))))
         ("str" . (lambda(obj-name)
                    (ess-execute (concat "str(" obj-name ")\n") nil (concat "R str: " obj-name))))
         ("summary" . (lambda(obj-name)
                        (ess-execute (concat "summary(" obj-name ")\n") nil (concat "R summary: " obj-name))))
         ("view source" . (lambda(obj-name)
                            (ess-execute (concat "print(" obj-name ")\n") nil (concat "R object: " obj-name))))
         ("dput" . (lambda(obj-name)
                     (ess-execute (concat "dput(" obj-name ")\n") nil (concat "R dput: " obj-name)))))
        (volatile)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; helm-c-source-R-local
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar helm-c-source-R-local
      '((name . "R local objects")
        (init . (lambda ()
                  ;; this grabs the process name associated with the buffer
                  (setq helm-c-ess-local-process-name ess-local-process-name)
                  ;; this grabs the buffer for later use
                  (setq helm-c-ess-buffer (current-buffer))))
        (candidates . (lambda ()
                        (let (buf)
                          (condition-case nil
                              (with-temp-buffer
                                (progn
                                  (setq buf (current-buffer))
                                  (with-current-buffer helm-c-ess-buffer
                                    (ess-command "print(ls.str(), max.level=0)\n" buf))
                                  (split-string (buffer-string) "\n" t)))
                            (error nil)))))
        (display-to-real . (lambda (obj-name) (car (split-string obj-name " : " t))))
        (action
         ("str" . (lambda(obj-name)
                    (ess-execute (concat "str(" obj-name ")\n") nil (concat "R str: " obj-name))))
         ("summary" . (lambda(obj-name)
                        (ess-execute (concat "summary(" obj-name ")\n") nil (concat "R summary: " obj-name))))
         ("head (10)" . (lambda(obj-name)
                          (ess-execute (concat "head(" obj-name ", n = 10)\n") nil (concat "R head: " obj-name))))
         ("head (100)" . (lambda(obj-name)
                           (ess-execute (concat "head(" obj-name ", n = 100)\n") nil (concat "R head: " obj-name))))
         ("tail" . (lambda(obj-name)
                     (ess-execute (concat "tail(" obj-name ", n = 10)\n") nil (concat "R tail: " obj-name))))
         ("print" . (lambda(obj-name)
                      (ess-execute (concat "print(" obj-name ")\n") nil (concat "R object: " obj-name))))
         ("dput" . (lambda(obj-name)
                     (ess-execute (concat "dput(" obj-name ")\n") nil (concat "R dput: " obj-name)))))
        (volatile)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; func for action
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun helm-ess-marked-install (candidate)
  (dolist (i (helm-marked-candidates))
    (ess-execute (concat "install.packages(\"" i "\")\n") t)))

(defun helm-ess-marked-remove (candidate)
  (dolist (i (helm-marked-candidates))
    (ess-execute (concat "remove.packages(\"" i "\")\n") t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; helm-c-source-R-localpkg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar helm-c-source-R-localpkg
      '((name . "R-local-packages")
        (init . (lambda ()
                  ;; this grabs the process name associated with the buffer
                  (setq helm-c-ess-local-process-name ess-local-process-name)
                  ;; this grabs the buffer for later use
                  (setq helm-c-ess-buffer (current-buffer))))
        (candidates . (lambda ()
                        (let (buf)
                          (condition-case nil
                              (with-temp-buffer
                                (progn
                                  (setq buf (current-buffer))
                                  (with-current-buffer helm-c-ess-buffer
                                    (ess-command "writeLines(paste('', sort(.packages(all.available=TRUE)), sep=''))\n" buf))

                                  (split-string (buffer-string) "\n" t)))
                            (error nil)))))

        (action
         ("load packages" . (lambda(obj-name)
                              (ess-execute (concat "library(" obj-name ")\n") t )))
         ("remove packages" . (lambda(obj-name)
                                (ess-execute (concat "remove.packages(\"" obj-name "\")\n") t)))
         ("remove marked packages" . helm-ess-marked-remove))    
        (volatile)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; helm-c-source-R-repospkg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar helm-c-source-R-repospkg
      '((name . "R-repos-packages")
        (init . (lambda ()
                  ;; this grabs the process name associated with the buffer
                  (setq helm-c-ess-local-process-name ess-local-process-name)
                  ;; this grabs the buffer for later use
                  (setq helm-c-ess-buffer (current-buffer))))
        (candidates . (lambda ()
                        (let (buf)
                          (condition-case nil
                              (with-temp-buffer
                                (progn
                                  (setq buf (current-buffer))
                                  (with-current-buffer helm-c-ess-buffer
                                    (ess-command "writeLines(paste('', rownames(available.packages(contriburl=contrib.url(\"http://cran.md.tsukuba.ac.jp/\"))), sep=''))\n" buf))
                                  ;; (ess-command "writeLines(paste('', sort(.packages(all.available=TRUE)), sep=''))\n" buf))
                                  (split-string (buffer-string) "\n" t)))
                            (error nil)))))
        (action
         ("install packages" . (lambda(obj-name)
                                 (ess-execute 
                                  (concat "install.packages(\"" obj-name "\", lib = .libPaths()[1], contriburl=contrib.url(\"http://cran.md.tsukuba.ac.jp/\"))\n") t)
(minibuffer-keyboard-quit)))
                                 
         ("install marked packages" . helm-ess-marked-install))    
        (volatile)))

(defcustom helm-for-R-list '(helm-c-source-R-help 
                                 helm-c-source-R-local 
                                 helm-c-source-R-repospkg 
                                 helm-c-source-R-localpkg)
  "Your prefered sources to GNU R."
  :type 'list
  :group 'helm-R)

;;;###autoload
(defun helm-for-R ()
  "Preconfigured `helm' for GNU R."
  (interactive)
  (helm-other-buffer helm-for-R-list "*helm for GNU R*"))

(provide 'helm-R)
;;; helm-R.el ends here
