;;; cloud-to-butt-erc.el --- Replace 'the cloud' with 'my butt'

;; Copyright © 2013 David Leatherman

;; Author: David Leatherman <leathekd@gmail.com>
;; URL: http://www.github.com/leathekd/cloud-to-butt-erc
;; Package-Version: 20130627.2308
;; Package-Commit: 6710c03d1bc91736435cbfe845924940cae34e5c
;; Version: 1.0.0

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Inspired by https://github.com/panicsteve/cloud-to-butt.  I wanted
;; to have the same laughs in IRC as I do while browsing the web so I
;; put this together.  I hope you enjoy it, too.

;; History

;; 1.0.0 - Initial release

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
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

;;; Code:
(defvar cloud-to-butt-replacement-decoration "~"
  "A character to surround the replacement just so you don't think the
replacement is actually something someone said.")

;;;###autoload
(defun cloud-to-butt-in-buffer ()
  (save-excursion
    (goto-char (point-min))
    (let ((case-fold-search t))
      (while (search-forward "the cloud" nil t)
        (replace-match (format "%smy butt%s"
                               cloud-to-butt-replacement-decoration
                               cloud-to-butt-replacement-decoration))))))

(define-erc-module cloud-to-butt nil
  "ERC module that replaces occurrences of 'the cloud' with 'my butt'"
  ((add-hook 'erc-insert-modify-hook 'cloud-to-butt-in-buffer))
  ((remove-hook 'erc-insert-modify-hook 'cloud-to-butt-in-buffer)))

(provide 'cloud-to-butt-erc)

;; For first time use
;;;###autoload
(when (and (boundp 'erc-modules)
           (not (member 'cloud-to-butt 'erc-modules)))
  (add-to-list 'erc-modules 'cloud-to-butt))

;;;###autoload
(eval-after-load 'erc
  '(progn
     (unless (featurep 'cloud-to-butt-erc)
       (require 'cloud-to-butt-erc))
     (add-to-list 'erc-modules 'cloud-to-butt t)))

;;; cloud-to-butt-erc.el ends here
