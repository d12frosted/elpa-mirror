;;; backline.el --- Preserve appearance of outline headings  -*- lexical-binding:t -*-

;; Copyright (C) 2018-2023 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/backline
;; Keywords: outlines
;; Package-Version: 20230514.1800
;; Package-Commit: f1d9e1cd5cba6362b152b5f4227d1714918fba59

;; Package-Requires: (
;;     (emacs "25.1")
;;     (compat "29.1.4.1")
;;     (outline-minor-faces "0.1.2"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; An outline heading does not extend to the right edge of the window
;; when its body is collapsed.  This is unfortunate when the used face
;; sets the background color or another property that is visible on
;; whitespace.  This package adds overlays to extend the appearance of
;; headings all the way to the right window edge.

;;   (use-package backline
;;     :after outline
;;     :config (advice-add 'outline-flag-region :after 'backline-update))

;; This package should be used together with the `outline-minor-faces'
;; package.  Instead setting the built-in `outline-minor-mode-highlight' to
;; `append' also works, but then top-level s-expressions are highlighted as
;; if they were sections, which makes the overview less readable.

;;; Code:

(require 'compat)

(require 'outline)
(require 'outline-minor-faces)

;;;###autoload
(defun backline-update (from to _hide)
  "When hidings, add an overlay to extend header's appearance to window edge."
  (when outline-minor-mode
    ;; `outline-hide-sublevels' tries to hide this range, in which case
    ;; `outline-back-to-heading' somehow concludes that point is before
    ;; the first heading causing it to raise an error.  Luckily we don't
    ;; actually have to do anything for that range, so we can just skip
    ;; ahead to the calls that hide the subtrees individually.
    (unless (and (= from   (point-min))
                 (= to (1- (point-max))))
      (ignore-errors ; Other instances of "before first heading" error.
        (remove-overlays from
                         (save-excursion
                           (goto-char to)
                           (outline-end-of-subtree)
                           (1+ (point)))
                         'backline-heading t)
        (dolist (ov (overlays-in (max (1- from) (point-min))
                                 (min (1+ to)   (point-max))))
          (when (eq (overlay-get ov 'invisible) 'outline)
            (let ((end (overlay-end ov)))
              (unless (save-excursion
                        (goto-char end)
                        (outline-back-to-heading)
                        ;; If we depended on `bicycle', then we could use:
                        ;; (bicycle--code-level-p)
                        (= (funcall outline-level)
                           (or (bound-and-true-p outline-code-level) 1000)))
                (let ((o (make-overlay end
                                       (min (1+ end) (point-max))
                                       nil 'front-advance)))
                  (overlay-put o 'evaporate t)
                  (overlay-put o 'backline-heading t)
                  (overlay-put o 'face
                               (save-excursion
                                 (goto-char end)
                                 (outline-back-to-heading)
                                 (outline-minor-faces--get-face))))))))))))

;;; _
(provide 'backline)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; backline.el ends here
