;;; all-the-icons-gnus.el --- Shows icons for in Gnus  -*- lexical-binding: t; -*-

;; Author: Nicolas Lamirault <nicolas.lamirault@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20180511.654
;; Package-Commit: 27f78996da0725943bcfb2d18038e6f7bddfa9c7
;; Keywords: mail tools
;; Package-Requires: ((emacs "24.4") (dash "2.12.0") (all-the-icons "3.1.0"))

;; Copyright (C) 2017, 2018 Nicolas Lamirault <nicolas.lamirault@gmail.com>

;; This program is free software: you can redistribute it and/or modify
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

;; To use this package, do
;;
;; (require 'all-the-icons-gnus)
;; (all-the-icons-gnus-setup)
;;

;;; Code:

(require 'gnus)
(require 'all-the-icons)

(setq pretty-gnus-article-alist nil)

(defmacro all-the-icons-gnus--pretty-gnus (word icon props)
  "Replace sanitized word with icon, props."
  `(add-to-list 'pretty-gnus-article-alist
               (list (rx bow (group ,word " : "))
                     ,icon ',props)))

(all-the-icons-gnus--pretty-gnus "From: "
                                 (all-the-icons-faicon "user")
                                 (:foreground "#375E97"))
(all-the-icons-gnus--pretty-gnus "Subject: "
                                 (all-the-icons-faicon "envelope-o")
                                 (:foreground "#375E97"))
(all-the-icons-gnus--pretty-gnus "To: "
                                 (all-the-icons-faicon "user")
                                 (:foreground "#375E97"))
(all-the-icons-gnus--pretty-gnus "CC: "
                                 (all-the-icons-octicon "puzzle")
                                 (:foreground "#375E97"))
(all-the-icons-gnus--pretty-gnus "Reply-To: "
                                 (all-the-icons-faicon "sign-out")
                                 (:foreground "#375E97"))
(all-the-icons-gnus--pretty-gnus "Date: "
                                 (all-the-icons-faicon "calendar")
                                 (:foreground "#375E97")) ; :height 1.2))
(all-the-icons-gnus--pretty-gnus "Organization: "
                                 (all-the-icons-faicon "university")
                                 (:foreground "#375E97"))
(all-the-icons-gnus--pretty-gnus "Content-Type: "
                                 (all-the-icons-faicon "question-circle")
                                 (:foreground "#375E97"))
(all-the-icons-gnus--pretty-gnus "User-Agent: "
                                 (all-the-icons-faicon "chrome")
                                 (:foreground "#375E97"))
(all-the-icons-gnus--pretty-gnus "X-mailer: "
                                 (all-the-icons-faicon "chrome")
                                 (:foreground "#375E97"))
(all-the-icons-gnus--pretty-gnus "X-PGP-Fingerprint: "
                                 (all-the-icons-faicon "expeditedssl")
                                 (:foreground "#375E97"))

(defun all-the-icons-gnus--add-faces ()
  "Add face properties and compose symbols for buffer from pretty-gnus-article."
  (interactive)
  (with-silent-modifications
    (--each pretty-gnus-article-alist
      (-let (((rgx icon props) it))
        (save-excursion
          (goto-char (point-min))
          (while (search-forward-regexp rgx nil t)
            (compose-region
             (match-beginning 1) (match-end 1) icon)
            (when props
              (add-face-text-property
               (match-beginning 1) (match-end 1) props))))))))


(defun all-the-icons-gnus--set-format ()
  (setq

   ;; gnus-topic-line-format "%i[  %(%{%n -- %A%}%) ]%v\n"
   gnus-topic-line-format (concat "%i[ "
                                  (propertize ;(all-the-icons-faicon "folder-open")
                                   (all-the-icons-material "folder")
                                   'display '(raise 0.0))
                                  " %(%{%n -- %A%}%) ]%v\n")

   gnus-group-line-format (concat "%1M%1S%5y "
                                  (propertize ;(all-the-icons-faicon "envelope-o")
                                   (all-the-icons-material "mail")
                                   'display '(raise 0.0))
                                  " : %(%-50,50G%)\n")

   gnus-summary-line-format (concat "%1{%U%R%z: %}%[%2{%&user-date;%}%] "
                                    (propertize ;(all-the-icons-faicon "male")
                                     (all-the-icons-material "person")
                                     'display '(raise 0.0))
                                    " %4{%-34,34n%} %3{"
                                    (propertize ;(all-the-icons-faicon "terminal")
                                     (all-the-icons-material "send")
                                     'display '(raise 0.0))
                                    " %}%(%1{%B%}%s%)\n")

   ;; gnus-user-date-format-alist '((t . " %Y-%m-%d %H:%M"))
   gnus-user-date-format-alist (list (cons t (concat
                                              (propertize ;(all-the-icons-faicon "calendar" :v-adjust -0.01)
                                               (all-the-icons-material "date_range")
                                               'display '(raise 0.0))
                                              " %Y-%m-%d %H:%M")))

   gnus-sum-thread-tree-root (concat (propertize ;(all-the-icons-faicon "envelope-o" :v-adjust -0.01)
                                      (all-the-icons-material "mail")
                                      'display '(raise 0.0))
                                     " ")
   gnus-sum-thread-tree-false-root (concat (propertize ;(all-the-icons-faicon "chevron-circle-right" :v-adjust -0.01)
                                            (all-the-icons-material "forward")
                                            'display '(raise 0.0))
                                           " ")
   gnus-sum-thread-tree-single-indent (concat (propertize ;(all-the-icons-faicon "envelope-o" :v-adjust -0.01)
                                               (all-the-icons-material "email")
                                               'display '(raise 0.0))
                                              " ")
   gnus-sum-thread-tree-leaf-with-other (concat (propertize ;(all-the-icons-faicon "envelope-o" :v-adjust -0.01)
                                                 (all-the-icons-material "mail")
                                                 'display '(raise 0.0))
                                                " ")
   gnus-sum-thread-tree-vertical " "
   gnus-sum-thread-tree-single-leaf (concat (propertize ;(all-the-icons-faicon "envelope-o" :v-adjust -0.01)
                                             (all-the-icons-material "mail")
                                             'display '(raise 0.0))
                                            " ")
   ))

;;;###autoload
(defun all-the-icons-gnus-setup ()
  "Add icons for Gnus."
  ;; (advice-add 'gnus-summary-next-article :after 'all-the-icons-gnus--add-faces)
  (all-the-icons-gnus--set-format))


(provide 'all-the-icons-gnus)
;;; all-the-icons-gnus.el ends here
