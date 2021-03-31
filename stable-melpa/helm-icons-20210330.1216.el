;;; helm-icons.el --- Helm icons  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Ivan Yonchovski

;; Author: Ivan Yonchovski <yyoncho@gmail.com>
;; Contributor: Ellis Kenyő <me@elken.dev>
;; Keywords: convenience
;; Package-Version: 20210330.1216
;; Package-Commit: 8d2f5e705c8b78a390677cf242024739c932fc95

;; Version: 0.1
;; URL: https://github.com/yyoncho/helm-icons
;; Package-Requires: ((emacs "25.1") (dash "2.14.1") (f "0.20.0") (treemacs "2.7"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received candidate copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package plugs icons into `helm' standard functions.

;;; Code:

(require 'dash)
(require 'seq)
(require 'f)
(require 'treemacs-icons nil t)
(require 'treemacs-themes nil t)
(require 'all-the-icons nil t)

(defgroup helm-icons nil
  "Helm treemacs icons."
  :group 'helm)

(defcustom helm-icons-mode->icon
  '((dired-mode . dir-closed)
    (emacs-lisp-mode . "el")
    (spacemacs-buffer-mode . "el"))
  "Lookup Emacs mode -> `treemacs' icon key."
  :type '(alist :key-type symbol :value-type sexp))

(defcustom helm-icons-provider
  'treemacs
  "Provider to load symbols from."
  :type '(choice (const all-the-icons)
                 (const treemacs))
  :group 'helm)

(with-eval-after-load 'treemacs-icons
  (defun helm-icons--treemacs-icon (file)
    "docstring"
    (let ((icon (cond
                 ((symbolp file) file)
                 ((f-dir? file) 'dir-closed)
                 ((f-file? file) (f-ext file)))))
      (let* ((theme (treemacs--find-theme
                     (treemacs-theme->name
                      (treemacs-current-theme))))
             (icons (treemacs-theme->gui-icons theme)))
        (ht-get icons icon)))))

(defun helm-icons--get-icon (file)
  "Get icon for FILE."
  (cond ((eq helm-icons-provider 'all-the-icons)
         (require 'all-the-icons)
         (concat
          (or (cond ((not file) (all-the-icons-octicon "gear"))
                    ((or
                      (member (f-base file) '("." ".."))
                      (f-dir? file))
                     (all-the-icons-octicon "file-directory")))
              (all-the-icons-icon-for-file file))
          " "))
        ((eq helm-icons-provider 'treemacs)
         (helm-icons--treemacs-icon file))))

(defun helm-icons-buffers-add-icon (candidates _source)
  "Add icon to buffers source.
CANDIDATES is the list of candidates."
  (-map (-lambda ((display . buffer))
          (cons (concat
                 (with-current-buffer buffer
                   (or (->> (assoc major-mode helm-icons-mode->icon)
                            (cl-rest)
                            helm-icons--get-icon)
                       (-some->> (buffer-file-name)
                         helm-icons--get-icon)
                       (helm-icons--get-icon 'fallback)))
                 display)
                buffer))
        candidates))

(defun helm-icons-files-add-icons (candidates _source)
  "Add icon to files source.
CANDIDATES is the list of candidates."
  (-map (-lambda (candidate)
          (-let [(display . file-name) (if (listp candidate)
                                           candidate
                                         (cons candidate candidate))]
            (cons (concat (cond
                           ((helm-icons--get-icon file-name))
                           ((helm-icons--get-icon 'fallback)))
                          display)
                  file-name)))
        candidates))

(defun helm-icons-add-transformer (fn source)
  "Add FN to `filtered-candidate-transformer' slot of SOURCE."
  (setf (alist-get 'filtered-candidate-transformer source)
        (-uniq (append
                (-let [value (alist-get 'filtered-candidate-transformer source)]
                  (if (seqp value) value (list value)))
                (list fn)))))

(defun helm-icons--make (orig name class &rest args)
  "The advice over `helm-make-source'.
ORIG is the original function.
NAME, CLASS and ARGS are the original params."
  (let ((result (apply orig name class args)))
    (cl-case class
      ((helm-recentf-source helm-source-ffiles helm-locate-source helm-fasd-source helm-ls-git-source)
       (helm-icons-add-transformer
        #'helm-icons-files-add-icons
        result))
      ((helm-source-buffers helm-source-projectile-buffer)
       (helm-icons-add-transformer
        #'helm-icons-buffers-add-icon
        result)))
    (cond
     ((or (-any? (lambda (source-name) (s-match source-name name))
                 '("Projectile files"
                   "Projectile projects"
                   "Projectile directories"
                   "Projectile recent files"
                   "Projectile files in current Dired buffer"
                   "dired-do-rename.*"
                   "Elisp libraries (Scan)")))
      (helm-icons-add-transformer
       #'helm-icons-files-add-icons
       result)))
    result))

(defun helm-icons--setup ()
  "Setup icons based on which provider is set."
  (cond ((eq helm-icons-provider 'all-the-icons)
         (require 'all-the-icons))
        ((eq helm-icons-provider 'treemacs)
         (require 'treemacs-themes)
         (require 'treemacs-icons)
         (treemacs--setup-icon-background-colors))))

;;;###autoload
(defun helm-icons-enable ()
  "Enable `helm-icons'."
  (interactive)
  (advice-add 'helm-make-source :around #'helm-icons--make)
  (helm-icons--setup))

(provide 'helm-icons)
;;; helm-icons.el ends here
