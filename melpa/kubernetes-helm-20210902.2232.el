;;; kubernetes-helm.el --- extension for helm, the package manager for kubernetes -*- lexical-binding: t; -*-

;; Copyright (C) 2018, Adrien Brochard

;; This file is NOT part of Emacs.

;; This  program is  free  software; you  can  redistribute it  and/or
;; modify it  under the  terms of  the GNU  General Public  License as
;; published by the Free Software  Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT  ANY  WARRANTY;  without   even  the  implied  warranty  of
;; MERCHANTABILITY or FITNESS  FOR A PARTICULAR PURPOSE.   See the GNU
;; General Public License for more details.

;; You should have  received a copy of the GNU  General Public License
;; along  with  this program;  if  not,  write  to the  Free  Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
;; USA

;; Version: 1.0
;; Package-Version: 20210902.2232
;; Package-Commit: 95cf92600436f67bd7bfe650763e68635f5ecc8e
;; Author: Adrien Brochard
;; Keywords: kubernetes helm k8s tools processes
;; URL: https://github.com/abrochard/kubernetes-helm
;; License: GNU General Public License >= 3
;; Package-Requires: ((yaml-mode "0.0.13") (emacs "25.3"))

;;; Commentary:

;; Commands for [helm](https://helm.sh/), the kubernetes package manager.

;;; Usage:

;; Invoke the interactive functions
;;
;; M-x kubernetes-helm-dep-up
;; M-x kubernetes-helm-install
;; M-x kubernetes-helm-upgrade
;; M-x kubernetes-helm-values
;; M-x kubernetes-helm-status
;; M-x kubernetes-helm-template
;;
;; To respectively
;; - update the dependencies
;; - install a chart
;; - upgrade a chart
;; - get the values of a deployed chart
;; - get the status of a deployment
;; - render chart template locally
;;
;; Note that in most cases, you will be prompted for the k8s namespace.

;;; Code:

(require 'yaml-mode)

(defconst kubernetes-helm-process-name "kubernetes-helm")
(defconst kubernetes-helm-buffer-name "*kubernetes-helm-command*")

;;;###autoload
(defun kubernetes-helm-dep-up (directory)
  "Run helm dep up on a directory.

DIRECTORY is the chart location."
  (interactive "DChart: ")
  (with-output-to-temp-buffer kubernetes-helm-buffer-name
    (start-process kubernetes-helm-process-name kubernetes-helm-buffer-name
                   "helm" "dep" "up" directory)
    (pop-to-buffer kubernetes-helm-buffer-name)))

;;;###autoload
(defun kubernetes-helm-install (namespace directory values-file)
  "Run helm install.

NAMESPACE is the namespace.
DIRECTORY is the chart location.
VALUES-FILE is the override values."
  (interactive "MNamespace: \nDChart: \nfValues file: ")
  (with-output-to-temp-buffer kubernetes-helm-buffer-name
    (apply #'start-process kubernetes-helm-process-name kubernetes-helm-buffer-name
           "helm" (remove nil (list "install" directory "-f" values-file "--name" namespace "--debug" (when (y-or-n-p "Dry run? ") "--dry-run"))))
    (pop-to-buffer kubernetes-helm-buffer-name)))

;;;###autoload
(defun kubernetes-helm-upgrade (namespace directory values-file)
  "Run helm upgrade.

NAMESPACE is the namespace.
DIRECTORY si the chart location.
VALUES-FILE is the override values."
  (interactive "MNamespace: \nDChart: \nfValues file: ")
  (with-output-to-temp-buffer kubernetes-helm-buffer-name
    (apply #'start-process kubernetes-helm-process-name kubernetes-helm-buffer-name
           "helm" (remove nil (list "upgrade" namespace directory "-f" values-file "--debug" (when (y-or-n-p "Dry run? ") "--dry-run"))))
    (pop-to-buffer kubernetes-helm-buffer-name)))

;;;###autoload
(defun kubernetes-helm-values (namespace)
  "Get helm values for a namespace.

NAMESPACE is the namespace."
  (interactive "MNamespace: ")
  (let ((buffer-name (concat "*kubernetes - helm - " namespace "*")))
    (when (get-buffer buffer-name) (kill-buffer buffer-name))
    (call-process "helm" nil buffer-name nil "get" "values" namespace)
    (pop-to-buffer buffer-name)
    (yaml-mode)))

(defun kubernetes-helm-status (namespace)
  "Get helm status for a namespace.

NAMESPACE is the namespace."
  (interactive "MNamespace: ")
  (with-output-to-temp-buffer kubernetes-helm-buffer-name
    (call-process "helm" nil kubernetes-helm-buffer-name nil "status" namespace)
    (pop-to-buffer kubernetes-helm-buffer-name)))

;;;###autoload
(defun kubernetes-helm-template (directory)
  "Render chat template locally.

DIRECTORY is the location of the chart."
  (interactive "DChart: ")
  (let ((buffer-name (format "*kubernetes - helm - template - %s *" (file-name-base (directory-file-name directory)))))
    (with-output-to-temp-buffer buffer-name
      (call-process "helm" nil buffer-name nil "template" directory)
      (pop-to-buffer buffer-name)
      (yaml-mode))))

(provide 'kubernetes-helm)
;;; kubernetes-helm.el ends here
