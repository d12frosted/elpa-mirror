;;; nameframe-perspective.el --- Nameframe integration with perspective.el

;; Author: John Del Rosario <john2x@gmail.com>
;; URL: https://github.com/john2x/nameframe
;; Package-Version: 20221023.957
;; Package-Commit: 06d3400750c6b33ae215b9ac2922ee4dafd6b506
;; Version: 0.5.0-beta
;; Package-Requires: ((nameframe "0.5.0-beta") (perspective "1.12"))

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

;; This package advises the `nameframe-make-frame' function to
;; switch to a perspective after creating a frame.

;; To use this library, put this file in your Emacs load path,
;; and call (nameframe-perspective-mode t).

;;; Code:

(require 'nameframe)
(require 'perspective)

;;;###autoload
(define-minor-mode nameframe-perspective-mode
  "Global minor mode that switches perspective when creating frames.
With `nameframe-perspective-mode' enabled, creating frames with
`nameframe-make-frame' will automatically switch to a perspective
with that frame's name."
  :init-value nil
  :lighter nil
  :global t
  :group 'nameframe
  :require 'nameframe-perspective
  (cond
   (nameframe-perspective-mode
    (add-hook 'nameframe-make-frame-hook #'nameframe-perspective--make-frame-persp-switch-hook))
   (t
    (remove-hook 'nameframe-make-frame-hook #'nameframe-perspective--make-frame-persp-switch-hook))))

(defun nameframe-perspective--make-frame-persp-switch-hook (frame)
  "Used as a hook function to switch perspective based on FRAME's name."
  (persp-switch (nameframe--get-frame-name frame))
  ;; kill the default 'main' perspective
  (persp-kill "main"))

(provide 'nameframe-perspective)

;;; nameframe-perspective.el ends here
