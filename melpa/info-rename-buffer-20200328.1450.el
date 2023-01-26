;;; info-rename-buffer.el --- Rename Info buffers to match manuals  -*- lexical-binding:t -*-

;; Copyright (C) 2019 Bruno Félix Rezende Ribeiro <oitofelix@gnu.org>

;; Author: Bruno Félix Rezende Ribeiro <oitofelix@gnu.org>
;; Keywords: help
;; Package-Version: 20200328.1450
;; Package-Commit: 87fb263b18717538fd04878e3358e1e720415db8
;; Package: info-rename-buffer
;; Homepage: https://github.com/oitofelix/info-rename-buffer
;; Version: 20200328.1147
;; Package-Requires: ((emacs "24.3"))

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; ‘info-rename-buffer-mode’ is a global minor-mode that automatically
;; renames Info buffers to match their visiting manual.

;; That’s a useful feature when consulting several Info manuals
;; simultaneously, because it frees the user from the burden of
;; renaming Info buffers to descriptive names manually before visiting
;; another manual, thus avoiding accidentally overriding the currently
;; visited node in case the user tries to open a new Info buffer.

;;; Code:


(require 'info)


;;;###autoload
(define-minor-mode info-rename-buffer-mode
  "Toggle Info-Rename-Buffer mode on or off.
With a prefix argument ARG, enable Info-Rename-Buffer mode if ARG
is positive, and disable it otherwise.  If called from Lisp,
enable the mode if ARG is omitted or nil, and toggle it if ARG is
‘toggle’.

When Info-Rename-Buffer is enabled, Info buffer's name is
automatically changed to include its currently visiting manual's
name.  See the command \\[info-rename-buffer]."
  :group 'info
  :init-value nil
  :global t
  :require 'info-rename-buffer
  (if info-rename-buffer-mode
      (add-hook 'Info-selection-hook #'info-rename-buffer)
    (remove-hook 'Info-selection-hook #'info-rename-buffer)))


(defun info-rename-buffer ()
  "Rename current Info buffer to match its visiting manual."
  (interactive)
  (unless (eq major-mode 'Info-mode) (user-error "This is not an Info buffer"))
  (unless (not (string-match-p "^\\*info" (buffer-name)))
    (rename-buffer (if (equal Info-current-file "dir") "*info*"
                     (format "*info %s*" (file-name-base Info-current-file)))
                   'unique)))


(provide 'info-rename-buffer)

;;; info-rename-buffer.el ends here
