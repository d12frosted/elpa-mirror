;;; encourage-mode.el --- Encourages you in your work. :D -*- lexical-binding:t -*-

;; Copyright (C) 2015 Patrick Mosby <patrick@schreiblogade.de>

;; Author: Patrick Mosby <patrick@schreiblogade.de>
;; URL: https://github.com/halbtuerke/encourage-mode.el
;; Package-Version: 20151128.905
;; Package-Commit: ca411e6bfd3d0edffe95852127bd995730b942e3
;; Version: 0.0.1
;; Keywords: fun
;; Package-Requires: ((emacs "24.4"))
;; Prefix: encourage
;; Separator: -

;;; Commentary:
;;
;; This minor-mode is inspired by https://github.com/Haacked/Encourage
;;
;; To use it, simply call M-x `encourage-mode'.
;;
;; `encourage-mode' is a global minor-mode which displays a small encouragement
;; everytime you save a buffer.

;;; License:
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.


;;; Code:


(defconst encourage-mode-version "0.0.1" "Version of the encourage-mode.el package.")

(defgroup encourage-mode ()
  "Some encouragement is always nice."
  :group 'emacs)

(defcustom encourage-encouragements
  '("Nice Job!"
    "Way to go!"
    "Wow, nice change!"
    "So good!"
    "Bravo!"
    "You rock!"
    "Well done!"
    "I see what you did there!"
    "Genius work!"
    "Thumbs up!"
    "Coding win!"
    "FTW!"
    "Yep!"
    "Nnnnailed it!")
  "The list of encouragements.
One of these will be randomly displayed when saving a buffer."
  :group 'encourage-mode)

;;;###autoload
(define-minor-mode encourage-mode
  "A whimsical mode that adds just a little bit of encouragement throughout your day."
  :lighter " YAY!"
  :init-value t
  :global t
  (encourage--toggle-encouragements))

(defun encourage--toggle-encouragements ()
  "Toggle display of encouragements."
  (interactive)
  (if encourage-mode
      (add-hook 'after-save-hook 'encourage--show-encouragements)
    (remove-hook 'after-save-hook 'encourage--show-encouragements)))

(defun encourage--show-encouragements ()
  "Display a random encouragement."
  (message (encourage--random-encouragement)))

(defun encourage--random-encouragement ()
  "Get a random encouragement."
  (elt encourage-encouragements (random (length encourage-encouragements))))


(provide 'encourage-mode)
;;; encourage-mode.el ends here
