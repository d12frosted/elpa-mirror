;;; treemacs-nerd-icons.el --- Emacs Nerd Font Icons theme for treemacs -*- lexical-binding: t -*-

;; Copyright (C) 2023 Hongyu Ding <rainstormstudio@yahoo.com>

;; Author: Hongyu Ding <rainstormstudio@yahoo.com>
;; Keywords: lisp
;; Package-Version: 20230424.1854
;; Package-Commit: c6f4a74ea4f414528fc43a6fe95f7f17687faeb4
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
                           (let ((extensions (list (nth 0 item)))
                                 (fn (nth 1 item))
                                 (key (nth 2 item))
                                 (plist (nthcdr 3 item)))
                             (treemacs-create-icon
                              :icon (format "  %s%s" (apply fn key plist) treemacs-nerd-icons-tab)
                              :extensions extensions
                              :fallback 'same-as-icon)))
                         
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
