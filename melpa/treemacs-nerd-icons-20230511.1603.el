;;; treemacs-nerd-icons.el --- Emacs Nerd Font Icons theme for treemacs -*- lexical-binding: t -*-

;; Copyright (C) 2023 Hongyu Ding <rainstormstudio@yahoo.com>

;; Author: Hongyu Ding <rainstormstudio@yahoo.com>
;; Keywords: lisp
;; Package-Version: 20230511.1603
;; Package-Commit: f18228eaf6ecd28eb5c5ede3550c94cd12aac856
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.3") (nerd-icons "0.0.1") (treemacs "0.0"))
;; URL: https://github.com/rainstormstudio/treemacs-nerd-icons
;; Keywords: files, icons, treemacs

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

;;; Commentary:

;; nerd-icons theme for treemacs

;;; Code:

(require 'nerd-icons)
(require 'treemacs)

(defface treemacs-nerd-icons-root-face
  '((t (:inherit nerd-icons-dorange)))
  "Face used for the root icon in nerd-icons theme."
  :group 'treemacs-faces)

(defface treemacs-nerd-icons-file-face
  '((t (:inherit nerd-icons-orange)))
  "Face used for the directory and file icons in nerd-icons theme."
  :group 'treemacs-faces)

(defvar treemacs-nerd-icons-tab (if (bound-and-true-p treemacs-nerd-icons-tab-font)
                                    (propertize "\t" 'face `((:family ,treemacs-nerd-icons-tab-font)))
                                  "\t"))

(treemacs-create-theme "nerd-icons"
                       :config
                       (progn
                         (dolist (item nerd-icons-extension-icon-alist)
                           (let* ((extension (car item))
                                  (func (cadr item))
                                  (args (append (list (cadr (cdr item))) '(:v-adjust -0.05 :height 1.0) (cdr (cddr item))))
                                  (icon (apply func args)))
                             (let* ((icon-pair (cons (format " %s%s%s" treemacs-nerd-icons-tab icon treemacs-nerd-icons-tab) (format " %s%s%s" treemacs-nerd-icons-tab icon treemacs-nerd-icons-tab)))
                                    (gui-icons (treemacs-theme->gui-icons treemacs--current-theme))
                                    (tui-icons (treemacs-theme->tui-icons treemacs--current-theme))
                                    (gui-icon  (car icon-pair))
                                    (tui-icon  (cdr icon-pair)))
                               (ht-set! gui-icons extension gui-icon)
                               (ht-set! tui-icons extension tui-icon))))

                         ;; directory and other icons
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-octicon "nf-oct-repo"   :face 'treemacs-nerd-icons-root-face) treemacs-nerd-icons-tab)
                                               :extensions (root-closed root-open)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s%s%s" (nerd-icons-octicon "nf-oct-chevron_down"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab (nerd-icons-octicon "nf-oct-file_directory"  :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (dir-open)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s%s%s" (nerd-icons-octicon "nf-oct-chevron_right"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab (nerd-icons-octicon "nf-oct-file_directory"  :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (dir-closed)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s%s%s" (nerd-icons-octicon "nf-oct-chevron_down"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab (nerd-icons-octicon "nf-oct-file_directory"  :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (src-open)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s%s%s" (nerd-icons-octicon "nf-oct-chevron_right"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab (nerd-icons-octicon "nf-oct-file_directory"  :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (src-closed)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s%s%s" (nerd-icons-octicon "nf-oct-chevron_down"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab (nerd-icons-octicon "nf-oct-file_directory"  :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (build-open)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s%s%s" (nerd-icons-octicon "nf-oct-chevron_right"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab (nerd-icons-octicon "nf-oct-file_directory"  :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (build-closed)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s%s%s" (nerd-icons-octicon "nf-oct-chevron_down"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab (nerd-icons-octicon "nf-oct-file_directory"  :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (test-open)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s%s%s" (nerd-icons-octicon "nf-oct-chevron_right"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab (nerd-icons-octicon "nf-oct-file_directory"  :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (test-closed)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s%s%s" (nerd-icons-octicon "nf-oct-chevron_down"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab (nerd-icons-octicon "nf-oct-package"  :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (tag-open)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s%s%s" (nerd-icons-octicon "nf-oct-chevron_right"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab (nerd-icons-octicon "nf-oct-package"  :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (tag-closed)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-octicon "nf-oct-tag"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (tag-leaf)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-octicon "nf-oct-flame"  :face 'nerd-icons-red) treemacs-nerd-icons-tab)
                                               :extensions (error)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-octicon "nf-oct-stop"  :face 'nerd-icons-yellow) treemacs-nerd-icons-tab)
                                               :extensions (warning)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-octicon "nf-oct-info"   :face 'nerd-icons-blue) treemacs-nerd-icons-tab)
                                               :extensions (info)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-mdicon "nf-md-mail"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (mail)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-octicon "nf-oct-bookmark"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (bookmark)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-mdicon "nf-md-monitor"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (screen)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-mdicon "nf-md-home"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (house)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-faicon "nf-fa-list"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (list)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-mdicon "nf-md-repeat"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (repeat)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-faicon "nf-fa-suitcase"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (suitcase)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-mdicon "nf-md-close"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (close)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-octicon "nf-oct-calendar"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (calendar)
                                               :fallback 'same-as-icon)
                         (treemacs-create-icon :icon (format "%s%s" (nerd-icons-faicon "nf-fa-briefcase"   :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (briefcase)
                                               :fallback 'same-as-icon)

                         (treemacs-create-icon :icon (format "  %s%s" (nerd-icons-faicon "nf-fa-file_o" :face 'treemacs-nerd-icons-file-face) treemacs-nerd-icons-tab)
                                               :extensions (fallback)
                                               :fallback 'same-as-icon)))

(provide 'treemacs-nerd-icons)
;;; treemacs-nerd-icons.el ends here
